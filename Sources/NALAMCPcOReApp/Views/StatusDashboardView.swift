import NALAMCPcOReCore
import SwiftUI

struct StatusDashboardView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScreenContainer(title: "Status", subtitle: "Responsive Stable Core dashboard.") {
            ViewThatFits(in: .horizontal) {
                HStack {
                    actionButtons
                }
                Menu("Actions", systemImage: "ellipsis.circle") {
                    serverActions
                    Divider()
                    dataActions
                }
            }
            .buttonStyle(.bordered)

            AdaptiveCardGrid {
                DashboardCard(title: "Server", systemImage: "dot.radiowaves.left.and.right") {
                    InfoGrid(rows: serverRows)
                }
                DashboardCard(title: "Vault", systemImage: "cylinder.split.1x2") {
                    InfoGrid(rows: vaultRows)
                }
                DashboardCard(title: "Clients", systemImage: "terminal") {
                    ClientChipsView(states: model.clientStates())
                }
                DashboardCard(title: "Safety", systemImage: "lock.shield") {
                    SafetyListView()
                }
                DashboardCard(title: "Search Index", systemImage: "magnifyingglass") {
                    InfoGrid(rows: [
                        ("FTS5", model.health?.ftsReady == true ? "ready" : "missing"),
                        ("Source", "SQLite FTS5"),
                        ("File scan", "disabled")
                    ])
                }
                DashboardCard(title: "Backup / Dump", systemImage: "externaldrive") {
                    InfoGrid(rows: [
                        ("Last backup", model.health?.lastBackup ?? "none"),
                        ("Last dump", model.health?.lastDump ?? "none"),
                        ("Brain sync", "available")
                    ])
                }
                DashboardCard(title: "Server Load", systemImage: "gauge.with.dots.needle.50percent") {
                    ResourceSummaryRows(summary: model.resourceSummary)
                }
                DashboardCard(title: "Recent Activity", systemImage: "clock.arrow.circlepath") {
                    RecentActivityRows(activity: model.clientActivities)
                }
            }
        }
        .onAppear {
            model.reloadHealth()
            model.refreshResourceSample()
        }
    }

    private var actionButtons: some View {
        Group {
            serverActions
            dataActions
        }
    }

    @ViewBuilder
    private var serverActions: some View {
        Button("Start Server", systemImage: "play.fill") { model.startServer() }
            .disabled(model.core?.serverManager.isRunning == true)
        Button("Stop Server", systemImage: "stop.fill") { model.stopServer() }
            .disabled(model.core?.serverManager.isRunning != true)
        Button("Restart Server", systemImage: "arrow.clockwise") { model.restartServer() }
    }

    @ViewBuilder
    private var dataActions: some View {
        Button("Open Vault", systemImage: "folder") { model.openVaultFolder() }
        Button("Open Logs", systemImage: "doc.text") { model.openLogsFolder() }
        Button("Export Dump", systemImage: "square.and.arrow.up") { model.exportDump() }
        Button("Backup Now", systemImage: "externaldrive") { model.backupNow() }
    }

    private var serverRows: [(String, String)] {
        guard let health = model.health, let server = model.core?.serverManager else { return [] }
        return [
            ("State", server.isRunning ? "running" : "stopped"),
            ("Transport", server.transport.rawValue),
            ("Host", server.host),
            ("Port", server.port.map(String.init) ?? "stdio"),
            ("External access", health.externalAccess),
            ("Helper path", model.core?.helperSymlinkManager.stableHelperURL.path ?? "not available"),
            ("Helper PID", server.isRunning ? "\(ProcessInfo.processInfo.processIdentifier)" : "not available"),
            ("Uptime", model.resourceSummary.uptimeSeconds.map { "\(Int($0)) sec" } ?? "not available")
        ]
    }

    private var vaultRows: [(String, String)] {
        guard let health = model.health else { return [] }
        let counts = Dictionary(uniqueKeysWithValues: model.tableCounts())
        let dbSize = fileSize(path: model.core?.paths.databaseURL.path)
        let journalSize = fileSize(path: model.core?.paths.eventsURL.path)
        return [
            ("Vault path", health.vaultPath),
            ("DB status", health.databaseStatus),
            ("DB size", dbSize),
            ("Event journal", journalSize),
            ("Objects", "\(counts.values.reduce(0, +))"),
            ("Projects", "\(counts["projects"] ?? 0)"),
            ("Memories", "\(counts["memories"] ?? 0)"),
            ("Decisions", "\(counts["decisions"] ?? 0)"),
            ("Bugs", "\(counts["bugs"] ?? 0)"),
            ("Prompts", "\(counts["prompts"] ?? 0)"),
            ("Sessions", "\(counts["session_summaries"] ?? 0)")
        ]
    }

    private func fileSize(path: String?) -> String {
        guard let path,
              let size = try? FileManager.default.attributesOfItem(atPath: path)[.size] as? NSNumber else {
            return "not available"
        }
        return ByteCountFormatter.string(fromByteCount: size.int64Value, countStyle: .file)
    }
}

struct ClientChipsView: View {
    let states: [ClientConnectionInfo]

    var body: some View {
        FlowLayout(alignment: .leading, spacing: 6) {
            ForEach(states) { state in
                Text("\(state.client.rawValue) \(state.state.rawValue.uppercased())")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(state.state.badgeColor.opacity(0.18))
                    .foregroundStyle(state.state.badgeColor)
                    .clipShape(Capsule())
            }
        }
    }
}

struct SafetyListView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("External access: BLOCKED", systemImage: "checkmark.shield")
            Label("LAN: BLOCKED", systemImage: "checkmark.shield")
            Label("Internet: BLOCKED", systemImage: "checkmark.shield")
            Label("Unknown clients: DENIED", systemImage: "checkmark.shield")
            Label("Destructive tools: DISABLED", systemImage: "checkmark.shield")
            Label("Labs live write: FORBIDDEN", systemImage: "checkmark.shield")
        }
    }
}

struct ResourceSummaryRows: View {
    let summary: ResourceMonitorSummary

    var body: some View {
        InfoGrid(rows: [
            ("PID", summary.pid.map(String.init) ?? "not available"),
            ("CPU", summary.currentCPUPercent.map { String(format: "%.1f %%", $0) } ?? "not available"),
            ("Avg CPU", summary.averageCPUPercent.map { String(format: "%.1f %%", $0) } ?? "not available"),
            ("RAM", summary.currentRAMMB.map { String(format: "%.0f MB", $0) } ?? "not available"),
            ("Peak RAM", summary.peakRAMMB.map { String(format: "%.0f MB", $0) } ?? "not available"),
            ("Requests", "\(summary.totalRequests)"),
            ("Failed", "\(summary.failedRequests)")
        ])
    }
}

struct RecentActivityRows: View {
    let activity: [ClientActivity]

    var body: some View {
        if activity.isEmpty {
            Text("No MCP client activity yet.")
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(activity.suffix(10), id: \.timestamp) { item in
                    Text("\(item.client.rawValue) | \(item.tool) | \(item.result) | \(item.durationMS) ms")
                        .font(.caption.monospaced())
                        .lineLimit(1)
                }
            }
        }
    }
}

extension ClientConnectionState {
    var badgeColor: Color {
        switch self {
        case .active, .healthy: .green
        case .configured, .reachable: .yellow
        case .idle: .cyan
        case .denied, .error: .red
        case .known, .planned: .secondary
        }
    }
}

struct FlowLayout<Content: View>: View {
    let alignment: HorizontalAlignment
    let spacing: CGFloat
    @ViewBuilder var content: Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: spacing)], alignment: alignment, spacing: spacing) {
            content
        }
    }
}
