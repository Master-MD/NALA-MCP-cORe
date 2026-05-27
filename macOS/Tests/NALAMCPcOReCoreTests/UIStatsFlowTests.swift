import XCTest
@testable import NALAMCPcOReCore

final class UIStatsFlowTests: XCTestCase {
    private func makeCore(function: StaticString = #function) throws -> StableCore {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("NALA-MCP-cORe-UIStats-Tests", isDirectory: true)
            .appendingPathComponent(String(describing: function), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let core = try StableCore(vaultRoot: root)
        try core.initialize()
        return core
    }

    func testClientStateDoesNotBecomeActiveWithoutEvidence() throws {
        let core = try makeCore()
        let state = try core.clientConnectionManager.state(
            for: .codex,
            helperStatus: HelperStatus(buildHelperExists: true, stableHelperExists: false, stableHelperExecutable: false),
            activity: []
        )

        XCTAssertEqual(state.state, .reachable)
        XCTAssertNotEqual(state.state, .active)
        XCTAssertEqual(state.permission, .allow)
    }

    func testClientStateBecomesActiveOnlyAfterRecentToolEvidence() throws {
        let core = try makeCore()
        let recent = ClientActivity(
            client: .codex,
            tool: "search_context",
            result: "ok",
            timestamp: Date(),
            durationMS: 12
        )

        let state = try core.clientConnectionManager.state(
            for: .codex,
            helperStatus: HelperStatus(buildHelperExists: true, stableHelperExists: true, stableHelperExecutable: true),
            activity: [recent]
        )

        XCTAssertEqual(state.state, .active)
        XCTAssertEqual(state.lastTool, "search_context")
        XCTAssertTrue(state.shortStatus.contains("recent"))
    }

    func testCopyReadyConfigsUseStableHelperVaultAndProjectPath() throws {
        let core = try makeCore()
        let projectRoot = URL(fileURLWithPath: "/tmp/NALA-MCP-cORe")
        let configs = core.clientConfigGenerator.configs(projectRoot: projectRoot)

        XCTAssertTrue(configs.codexTOML.contains("command = \"\(core.helperSymlinkManager.stableHelperURL.path)\""))
        XCTAssertTrue(configs.codexTOML.contains("NALA_MCP_CORE_VAULT"))
        XCTAssertTrue(configs.geminiJSON.contains("\"cwd\""))
        XCTAssertTrue(configs.antigravityJSON.contains("mcp_config.json") == false)
        XCTAssertTrue(configs.manualSTDIO.contains("Transport:\nSTDIO"))
        XCTAssertTrue(configs.ruleSnippet.contains("Do not overwrite or delete"))
    }

    func testHelperSymlinkPlanIsUserScopedAndNoSudo() throws {
        let core = try makeCore()
        let plan = core.helperSymlinkManager.installPlan(realHelperURL: URL(fileURLWithPath: "/tmp/nala-mcp-core-helper"))

        XCTAssertEqual(plan.linkURL.path, "\(NSHomeDirectory())/bin/nala-mcp-core-helper")
        XCTAssertFalse(plan.commands.contains { $0.contains("sudo") })
        XCTAssertTrue(plan.commands.contains { $0.contains("ln -sfn") })
    }

    func testResourceMonitorAggregatesSamplesAndMenuBarStateMapping() throws {
        let samples = [
            ResourceSample(timestamp: Date().addingTimeInterval(-20), cpuPercent: 1.0, ramMB: 80, callsPerMinute: 0),
            ResourceSample(timestamp: Date().addingTimeInterval(-10), cpuPercent: 3.0, ramMB: 90, callsPerMinute: 2),
            ResourceSample(timestamp: Date(), cpuPercent: 5.0, ramMB: 100, callsPerMinute: 4)
        ]
        let summary = ResourceMonitorSummary(pid: 42, uptimeSeconds: 120, samples: samples, totalRequests: 6, failedRequests: 1, lastRequestAt: Date())

        XCTAssertEqual(summary.currentCPUPercent, 5.0)
        XCTAssertEqual(summary.averageCPUPercent, 3.0)
        XCTAssertEqual(summary.currentRAMMB, 100)
        XCTAssertEqual(summary.peakRAMMB, 100)
        XCTAssertEqual(MenuBarStateMapper.state(serverRunning: false, hasError: false, hasRecentActivity: false), .stopped)
        XCTAssertEqual(MenuBarStateMapper.state(serverRunning: true, hasError: false, hasRecentActivity: true), .active)
        XCTAssertEqual(MenuBarStateMapper.state(serverRunning: true, hasError: true, hasRecentActivity: false), .error)
    }

    func testFlowMatrixContainsBlockedInternetLANAndLabsLiveVaultEdges() throws {
        let matrix = FlowMatrixBuilder().build(clientStates: [
            .init(client: .codex, state: .configured, shortStatus: "configured", lastSeen: nil, lastTool: nil, permission: .allow)
        ])

        XCTAssertTrue(matrix.edges.contains { $0.from == "Internet" && $0.to == "SQLite Vault" && $0.policy == .deny })
        XCTAssertTrue(matrix.edges.contains { $0.from == "LAN" && $0.to == "SQLite Vault" && $0.policy == .deny })
        XCTAssertTrue(matrix.edges.contains { $0.from == "Labs" && $0.to == "Live Vault" && $0.policy == .deny })
        XCTAssertTrue(matrix.edges.contains { $0.from == "MCP Helper" && $0.to == "Event Journal" && $0.state == .internalLocal })
    }

    func testUpgradePreflightFindsV01VaultAndRequiresUserStopWhenActiveClientsExist() throws {
        let core = try makeCore()
        _ = try core.addProject(name: "Upgrade", content: "v0.1 data", sourceClient: "Manual")
        let activity = ClientActivity(client: .geminiCLI, tool: "health_check", result: "ok", timestamp: Date(), durationMS: 5)

        let report = try core.upgradePreflightManager.inspectV01Vault(
            candidates: [core.paths.rootURL],
            activity: [activity],
            serverRunning: true
        )

        XCTAssertEqual(report.status, .requiresUserStop)
        XCTAssertEqual(report.vaultURL, core.paths.rootURL)
        XCTAssertTrue(report.detectedClients.contains(.geminiCLI))
        XCTAssertTrue(report.instructions.contains("stop Gemini CLI"))
        XCTAssertTrue(report.canInspectWhileRunning)
        XCTAssertFalse(report.canMigrateWhileRunning)
    }
}
