import XCTest
@testable import NALAMCPcOReCore

final class StableCoreTests: XCTestCase {
    private func makeCore(function: StaticString = #function) throws -> StableCore {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("NALA-MCP-cORe-Tests", isDirectory: true)
            .appendingPathComponent(String(describing: function), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let core = try StableCore(vaultRoot: root)
        try core.initialize()
        return core
    }

    func testDatabaseInitializesWithWALAndFTS5() throws {
        let core = try makeCore()

        let health = try core.healthCheck()

        XCTAssertEqual(health.databaseStatus, "ready")
        XCTAssertEqual(health.journalMode.lowercased(), "wal")
        XCTAssertTrue(health.ftsReady)
        XCTAssertTrue(FileManager.default.fileExists(atPath: core.paths.databaseURL.path))
    }

    func testSearchContextUsesFTSIndexAndJSONLEventsAreWritten() throws {
        let core = try makeCore()
        _ = try core.addProject(name: "NALA", content: "Local memory core", sourceClient: "Manual")
        _ = try core.addMemory(project: "NALA", title: "MCP indexed memory", content: "Codex should find this through FTS5.", sourceClient: "Codex")

        let results = try core.searchContext(query: "Codex FTS5", project: "NALA")
        let events = try String(contentsOf: core.paths.eventsURL, encoding: .utf8)

        XCTAssertEqual(results.first?.title, "MCP indexed memory")
        XCTAssertEqual(results.first?.source, "sqlite_fts5")
        XCTAssertTrue(events.contains("object.created"))
    }

    func testFingerprintsAndDuplicateDetectionAreStable() throws {
        let core = try makeCore()

        let first = try core.fingerprintManager.fingerprint(for: "  Hello   NALA  ")
        let second = try core.fingerprintManager.fingerprint(for: "hello nala")

        XCTAssertNotEqual(first.contentHash, second.contentHash)
        XCTAssertEqual(first.normalizedHash, second.normalizedHash)
        XCTAssertTrue(try core.classifyDuplicate(content: "hello nala") == .newObject)

        _ = try core.addMemory(project: "NALA", title: "Greeting", content: "hello nala", sourceClient: "Manual")

        XCTAssertEqual(try core.classifyDuplicate(content: "hello nala"), .alreadyExists)
        XCTAssertEqual(try core.classifyDuplicate(content: "Hello NALA"), .duplicateFormatVariant)
    }

    func testPermissionsDenyUnknownClientsAndDestructiveActions() throws {
        let core = try makeCore()

        XCTAssertEqual(core.permissionManager.decision(client: "Mystery Bot", action: .search), .deny)
        XCTAssertEqual(core.permissionManager.decision(client: "Codex", action: .search), .allow)
        XCTAssertEqual(core.permissionManager.decision(client: "Codex", action: .deleteMemory), .deny)
    }

    func testBackupManifestChecksumsAndRestoreDryRun() throws {
        let core = try makeCore()
        _ = try core.addProject(name: "Backup Project", content: "Backup me", sourceClient: "Manual")

        let backup = try core.backupNow()
        let dryRun = try core.restoreDryRun(from: backup.fullBackupURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: backup.manifestURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: backup.checksumsURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: backup.zipURL.path))
        XCTAssertEqual(dryRun.status, .ready)
        XCTAssertGreaterThanOrEqual(dryRun.objectCounts["projects"] ?? 0, 1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: backup.fullBackupURL.appendingPathComponent("nala-mcp-core.sqlite-wal").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: backup.fullBackupURL.appendingPathComponent("nala-mcp-core.sqlite-shm").path))
    }

    func testFullDumpAndBrainSyncPackageContainIndexes() throws {
        let core = try makeCore()
        _ = try core.addProject(name: "Dump Project", content: "Dump me", sourceClient: "Manual")
        _ = try core.addSessionSummary(project: "Dump Project", sourceClient: "Codex", summary: "Built dump test", changedFiles: ["Package.swift"], openQuestions: [])

        let dump = try core.exportDump()
        let brain = try core.exportBrainSyncPackage()

        XCTAssertTrue(FileManager.default.fileExists(atPath: dump.rootURL.appendingPathComponent("index/object-index.jsonl").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: dump.rootURL.appendingPathComponent("index/fingerprint-index.jsonl").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: brain.rootURL.appendingPathComponent("index/project-index.md").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: brain.rootURL.appendingPathComponent("import-instructions.md").path))
    }

    func testLabSandboxFailureDoesNotModifyLiveDatabase() throws {
        let core = try makeCore()
        _ = try core.addProject(name: "Live", content: "Do not mutate", sourceClient: "Manual")
        let before = try core.listProjects().count

        XCTAssertThrowsError(try core.runLabSandbox(featureName: "failing-lab") { sandbox in
            try "sandbox mutation".write(to: sandbox.outputURL.appendingPathComponent("note.txt"), atomically: true, encoding: .utf8)
            throw StableCoreError.operationFailed("intentional failure")
        })

        XCTAssertEqual(try core.listProjects().count, before)
    }

    func testServerRejectsNonLoopbackBinding() throws {
        let core = try makeCore()

        XCTAssertNoThrow(try core.serverManager.validateLocalBindHost("127.0.0.1"))
        XCTAssertNoThrow(try core.serverManager.validateLocalBindHost("localhost"))
        XCTAssertThrowsError(try core.serverManager.validateLocalBindHost("0.0.0.0"))
        XCTAssertThrowsError(try core.serverManager.validateLocalBindHost("192.168.1.20"))
    }

    func testMCPToolsUsePermissionsAndIndexedSearch() throws {
        let core = try makeCore()
        _ = try core.addProject(name: "MCP", content: "Tooling", sourceClient: "Manual")
        _ = try core.addBugReport(project: "MCP", sourceClient: "Codex", title: "Local only", severity: "medium", description: "Bind only to loopback.", reproductionSteps: [], affectedFiles: [])

        let allowed = try core.mcpServer.call(tool: "search_context", client: "Codex", arguments: ["query": "loopback", "project": "MCP"])
        let denied = try core.mcpServer.call(tool: "search_context", client: "Unknown", arguments: ["query": "loopback"])

        XCTAssertEqual(allowed.status, .ok)
        XCTAssertTrue(allowed.text.contains("Local only"))
        XCTAssertEqual(denied.status, .denied)
    }

    func testMCPJSONRPCSupportsInitializeToolsListAndToolCall() throws {
        let core = try makeCore()
        let bridge = MCPJSONRPCBridge(core: core, defaultClient: "Codex")

        let initialize = try XCTUnwrap(bridge.handle(json: [
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": [
                "protocolVersion": "2025-11-25",
                "capabilities": [:],
                "clientInfo": ["name": "Codex", "version": "test"]
            ]
        ]))
        let initializeResult = try XCTUnwrap(initialize["result"] as? [String: Any])
        let initializeCapabilities = try XCTUnwrap(initializeResult["capabilities"] as? [String: Any])

        XCTAssertEqual(initialize["jsonrpc"] as? String, "2.0")
        XCTAssertEqual(initialize["id"] as? Int, 1)
        XCTAssertEqual(initializeResult["protocolVersion"] as? String, "2025-11-25")
        XCTAssertNotNil(initializeCapabilities["tools"])

        let toolsList = try XCTUnwrap(bridge.handle(json: [
            "jsonrpc": "2.0",
            "id": "tools",
            "method": "tools/list"
        ]))
        let toolsResult = try XCTUnwrap(toolsList["result"] as? [String: Any])
        let tools = try XCTUnwrap(toolsResult["tools"] as? [[String: Any]])

        XCTAssertEqual(toolsList["id"] as? String, "tools")
        XCTAssertTrue(tools.contains { $0["name"] as? String == "search_context" })

        let toolCall = try XCTUnwrap(bridge.handle(json: [
            "jsonrpc": "2.0",
            "id": 2,
            "method": "tools/call",
            "params": [
                "name": "health_check",
                "arguments": [:]
            ]
        ]))
        let callResult = try XCTUnwrap(toolCall["result"] as? [String: Any])
        let content = try XCTUnwrap(callResult["content"] as? [[String: Any]])
        let structuredContent = try XCTUnwrap(callResult["structuredContent"] as? [String: Any])

        XCTAssertEqual(content.first?["type"] as? String, "text")
        XCTAssertTrue((content.first?["text"] as? String ?? "").contains("NALA-MCP-cORe 0.1.0: ready"))
        XCTAssertEqual(structuredContent["status"] as? String, "ok")
    }
}
