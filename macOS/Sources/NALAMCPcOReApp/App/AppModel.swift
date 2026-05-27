import AppKit
import Foundation
import NALAMCPcOReCore
import ServiceManagement
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var core: StableCore?
    @Published var health: HealthStatus?
    @Published var searchResults: [SearchResult] = []
    @Published var statusMessage = "Choose a vault folder to start."
    @Published var lastOutput = ""
    @Published var selectedLog = "app"
    @Published var startAtLogin = UserDefaults.standard.bool(forKey: "startAtLogin")
    @Published var showMenuBarIcon = UserDefaults.standard.object(forKey: "showMenuBarIcon") as? Bool ?? true
    @Published var showMenuBarMetric = UserDefaults.standard.string(forKey: "showMenuBarMetric") ?? "icon"
    @Published var monitoringInterval = UserDefaults.standard.string(forKey: "monitoringInterval") ?? "10 sec"
    @Published var clientActivities: [ClientActivity] = []
    @Published var resourceSummary = ResourceMonitorSummary(pid: nil, uptimeSeconds: nil, samples: [], totalRequests: 0, failedRequests: 0, lastRequestAt: nil)

    private let vaultPathKey = "vaultPath"
    private var appLaunchDate = Date()

    init() {
        if let path = UserDefaults.standard.string(forKey: vaultPathKey), !path.isEmpty {
            openVault(URL(fileURLWithPath: path))
        }
    }

    func useDefaultVault() {
        openVault(VaultPaths.default())
    }

    func chooseCustomVault() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose where NALA-MCP-cORe should store its local vault."
        if panel.runModal() == .OK, let url = panel.url {
            openVault(url)
        }
    }

    func openVault(_ url: URL) {
        do {
            let stableCore = try StableCore(vaultRoot: url)
            try stableCore.initialize()
            UserDefaults.standard.set(url.path, forKey: vaultPathKey)
            core = stableCore
            statusMessage = "Vault ready at \(url.path)"
            refreshResourceSample()
            reloadHealth()
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func reloadHealth() {
        guard let core else { return }
        do {
            health = try core.healthCheck()
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func startServer() {
        perform {
            try core?.serverManager.start()
            statusMessage = "Local MCP helper running with stdio transport."
            reloadHealth()
        }
    }

    func stopServer() {
        perform {
            try core?.serverManager.stop()
            statusMessage = "Local MCP helper stopped."
            reloadHealth()
        }
    }

    func restartServer() {
        perform {
            try core?.serverManager.restart()
            statusMessage = "Local MCP helper restarted."
            reloadHealth()
        }
    }

    func search(query: String, project: String?) {
        perform {
            searchResults = try core?.searchContext(query: query, project: project?.nilIfBlank) ?? []
            statusMessage = "Search returned \(searchResults.count) indexed result(s)."
        }
    }

    func addEntry(kind: ManualEntryKind, project: String, title: String, content: String, severity: String) {
        perform {
            guard let core else { return }
            switch kind {
            case .project:
                _ = try core.addProject(name: title.nilIfBlank ?? project.nilIfBlank ?? "Untitled Project", content: content, sourceClient: "Manual")
            case .memory:
                _ = try core.addMemory(project: project.nilIfBlank ?? "General", title: title.nilIfBlank ?? "Untitled Memory", content: content, sourceClient: "Manual")
            case .decision:
                _ = try core.addDecision(project: project.nilIfBlank ?? "General", sourceClient: "Manual", title: title.nilIfBlank ?? "Untitled Decision", content: content)
            case .bug:
                _ = try core.addBugReport(project: project.nilIfBlank ?? "General", sourceClient: "Manual", title: title.nilIfBlank ?? "Untitled Bug", severity: severity.nilIfBlank ?? "medium", description: content, reproductionSteps: [], affectedFiles: [])
            case .sessionSummary:
                _ = try core.addSessionSummary(project: project.nilIfBlank ?? "General", sourceClient: "Manual", summary: content, changedFiles: [], openQuestions: [])
            }
            statusMessage = "\(kind.label) saved."
            reloadHealth()
        }
    }

    func backupNow() {
        perform {
            let result = try core?.backupNow()
            lastOutput = result?.fullBackupURL.path ?? ""
            statusMessage = "Backup created."
            reloadHealth()
        }
    }

    func exportDump() {
        perform {
            let result = try core?.exportDump()
            lastOutput = result?.rootURL.path ?? ""
            statusMessage = "Full NALA dump exported."
            reloadHealth()
        }
    }

    func exportBrainSync() {
        perform {
            let result = try core?.exportBrainSyncPackage()
            lastOutput = result?.rootURL.path ?? ""
            statusMessage = "NALA-bRaiN sync package exported."
            reloadHealth()
        }
    }

    func restoreDryRun(path: String) {
        perform {
            let result = try core?.restoreDryRun(from: URL(fileURLWithPath: path))
            lastOutput = result?.previewText ?? ""
            statusMessage = "Restore dry-run completed."
            reloadHealth()
        }
    }

    func createLabSandbox() {
        perform {
            let sandbox = try core?.runLabSandbox(featureName: "manual-sandbox-check") { sandbox in
                try "Sandbox check only. Live vault is untouched.\n".write(
                    to: sandbox.outputURL.appendingPathComponent("sandbox-check.txt"),
                    atomically: true,
                    encoding: .utf8
                )
            }
            lastOutput = sandbox?.rootURL.path ?? ""
            statusMessage = "Lab sandbox created against a snapshot."
            reloadHealth()
        }
    }

    func tableCounts() -> [(String, Int)] {
        guard let core else { return [] }
        return DatabaseManager.tableNames.map { table in
            (table, (try? core.database.count(table: table)) ?? 0)
        }
    }

    var projectRootURL: URL {
        let bundleURL = Bundle.main.bundleURL
        if bundleURL.path.contains("/dist/") {
            return bundleURL.deletingLastPathComponent().deletingLastPathComponent()
        }
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }

    var buildHelperURL: URL {
        projectRootURL.appendingPathComponent(".build/debug/nala-mcp-core-helper")
    }

    func helperStatus() -> HelperStatus {
        core?.helperSymlinkManager.status(buildHelperURL: buildHelperURL)
            ?? HelperStatus(buildHelperExists: false, stableHelperExists: false, stableHelperExecutable: false)
    }

    func clientStates() -> [ClientConnectionInfo] {
        guard let core else { return [] }
        return (try? core.clientConnectionManager.states(helperStatus: helperStatus(), activity: clientActivities)) ?? []
    }

    func clientConfigs() -> ClientConfigBundle? {
        core?.clientConfigGenerator.configs(projectRoot: projectRootURL)
    }

    func flowMatrix() -> FlowMatrix {
        core?.flowMatrixBuilder.build(clientStates: clientStates()) ?? FlowMatrix(nodes: [], edges: [])
    }

    func refreshResourceSample() {
        guard let core else { return }
        core.resourceMonitor.addSample(core.resourceMonitor.sampleCurrentProcess())
        resourceSummary = core.resourceMonitor.summary(
            pid: core.serverManager.isRunning ? Int(ProcessInfo.processInfo.processIdentifier) : nil,
            uptimeSeconds: Date().timeIntervalSince(appLaunchDate)
        )
    }

    func menuBarState() -> MenuBarVisualState {
        let recent = resourceSummary.lastRequestAt.map { Date().timeIntervalSince($0) < 30 } ?? false
        return MenuBarStateMapper.state(serverRunning: core?.serverManager.isRunning == true, hasError: false, hasRecentActivity: recent)
    }

    func copyToClipboard(_ text: String, message: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        statusMessage = message
    }

    func revealHelper() {
        let url = core?.helperSymlinkManager.stableHelperURL ?? buildHelperURL
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func installHelperSymlink() {
        perform {
            guard let core else { return }
            let plan = try core.helperSymlinkManager.install(realHelperURL: buildHelperURL)
            lastOutput = plan.commands.joined(separator: "\n")
            statusMessage = "Installed user helper symlink at \(plan.linkURL.path)."
        }
    }

    func testHelper(client: MCPClientKind = .manual) {
        perform {
            let helper = core?.helperSymlinkManager.stableHelperURL ?? buildHelperURL
            guard FileManager.default.fileExists(atPath: helper.path) else {
                throw StableCoreError.operationFailed("Helper not found at \(helper.path)")
            }
            let process = Process()
            process.executableURL = helper
            process.arguments = ["--tool", "health_check", "--client", client.permissionClientName, "--vault", core?.paths.rootURL.path ?? VaultPaths.default().path]
            let pipe = Pipe()
            process.standardOutput = pipe
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            lastOutput = String(data: data, encoding: .utf8) ?? ""
            let ok = process.terminationStatus == 0
            if ok {
                clientActivities.append(ClientActivity(client: client, tool: "health_check", result: "ok", timestamp: Date(), durationMS: 0))
                core?.resourceMonitor.recordRequest(result: .ok)
            } else {
                core?.resourceMonitor.recordRequest(result: .error)
            }
            refreshResourceSample()
            statusMessage = ok ? "health_check succeeded for \(client.rawValue)." : "health_check failed for \(client.rawValue)."
        }
    }

    func logText() -> String {
        core?.logManager.readLog(selectedLog) ?? ""
    }

    func openVaultFolder() {
        guard let path = core?.paths.rootURL else { return }
        NSWorkspace.shared.open(path)
    }

    func openLogsFolder() {
        guard let path = core?.paths.logsURL else { return }
        NSWorkspace.shared.open(path)
    }

    func chooseRestoreFolder(currentPath: Binding<String>) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose a full backup folder containing manifest.json."
        if panel.runModal() == .OK, let url = panel.url {
            currentPath.wrappedValue = url.path
        }
    }

    func setStartAtLogin(_ enabled: Bool) {
        startAtLogin = enabled
        UserDefaults.standard.set(enabled, forKey: "startAtLogin")
        do {
            if #available(macOS 13.0, *) {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            }
            statusMessage = enabled ? "Start at login enabled for current user." : "Start at login disabled."
        } catch {
            statusMessage = "Login item update failed: \(error.localizedDescription)"
        }
    }

    func setShowMenuBarIcon(_ enabled: Bool) {
        showMenuBarIcon = enabled
        UserDefaults.standard.set(enabled, forKey: "showMenuBarIcon")
    }

    func setMonitoringInterval(_ value: String) {
        monitoringInterval = value
        UserDefaults.standard.set(value, forKey: "monitoringInterval")
    }

    func setShowMenuBarMetric(_ value: String) {
        showMenuBarMetric = value
        UserDefaults.standard.set(value, forKey: "showMenuBarMetric")
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}

enum ManualEntryKind: String, CaseIterable, Identifiable {
    case project
    case memory
    case decision
    case bug
    case sessionSummary

    var id: String { rawValue }

    var label: String {
        switch self {
        case .project: "Project"
        case .memory: "Memory"
        case .decision: "Decision"
        case .bug: "Bug"
        case .sessionSummary: "Session Summary"
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
