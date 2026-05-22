import SwiftUI

struct MenuBarStatusView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NALA-MCP-cORe")
                .font(.headline)
            Text("Server: \(model.core?.serverManager.isRunning == true ? "running" : "stopped")")
            Text("Clients: \(model.clientStates().filter { $0.state == .active }.count) active")
            Text("CPU: \(model.resourceSummary.currentCPUPercent.map { String(format: "%.1f %%", $0) } ?? "n/a")")
            Text("RAM: \(model.resourceSummary.currentRAMMB.map { String(format: "%.0f MB", $0) } ?? "n/a")")
            Text("Last request: \(model.resourceSummary.lastRequestAt.map { DateFormatter.localizedString(from: $0, dateStyle: .none, timeStyle: .medium) } ?? "none")")
            Text("Vault: \(model.health?.databaseStatus ?? "not ready")")
            Text("FTS: \(model.health?.ftsReady == true ? "ready" : "missing")")
            Divider()
            Button("Open Control Center") {
                NSApp.activate(ignoringOtherApps: true)
            }
            Button("Start Server") { model.startServer() }
                .disabled(model.core?.serverManager.isRunning == true)
            Button("Stop Server") { model.stopServer() }
                .disabled(model.core?.serverManager.isRunning != true)
            Button("Backup Now") { model.backupNow() }
            Button("Export Dump Now") { model.exportDump() }
            Button("Open Logs") { model.openLogsFolder() }
            Divider()
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
        .padding()
        .onAppear {
            model.reloadHealth()
            model.refreshResourceSample()
        }
    }
}
