import SwiftUI

struct DeepStatsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScreenContainer(title: "Deep Stats", subtitle: "Lightweight in-memory monitoring. Samples are not persisted to SQLite.") {
            HStack {
                Button("Refresh Sample", systemImage: "arrow.clockwise") {
                    model.refreshResourceSample()
                }
                Picker("Monitoring interval", selection: Binding(
                    get: { model.monitoringInterval },
                    set: { model.setMonitoringInterval($0) }
                )) {
                    Text("off").tag("off")
                    Text("5 sec").tag("5 sec")
                    Text("10 sec").tag("10 sec")
                    Text("30 sec").tag("30 sec")
                }
                .frame(width: 180)
            }

            AdaptiveCardGrid {
                DashboardCard(title: "CPU %", systemImage: "speedometer") {
                    SparklineView(values: model.resourceSummary.samples.map(\.cpuPercent))
                    Text(model.resourceSummary.currentCPUPercent.map { String(format: "%.1f %% current", $0) } ?? "not available yet")
                        .foregroundStyle(.secondary)
                }
                DashboardCard(title: "RAM MB", systemImage: "memorychip") {
                    SparklineView(values: model.resourceSummary.samples.map(\.ramMB))
                    Text(model.resourceSummary.currentRAMMB.map { String(format: "%.0f MB current", $0) } ?? "not available yet")
                        .foregroundStyle(.secondary)
                }
                DashboardCard(title: "MCP Calls / min", systemImage: "arrow.left.arrow.right") {
                    SparklineView(values: model.resourceSummary.samples.map(\.callsPerMinute))
                    Text(model.resourceSummary.currentCallsPerMinute.map { String(format: "%.0f calls/min", $0) } ?? "not available yet")
                        .foregroundStyle(.secondary)
                }
                DashboardCard(title: "Tool Usage", systemImage: "wrench.and.screwdriver") {
                    UsageBreakdown(activity: model.clientActivities.map(\.tool))
                }
                DashboardCard(title: "Client Usage", systemImage: "person.2") {
                    UsageBreakdown(activity: model.clientActivities.map { $0.client.rawValue })
                }
                DashboardCard(title: "Errors", systemImage: "exclamationmark.triangle") {
                    InfoGrid(rows: [
                        ("Failed requests", "\(model.resourceSummary.failedRequests)"),
                        ("Average response", "not available yet"),
                        ("Slowest call", "not available yet")
                    ])
                }
                DashboardCard(title: "Storage", systemImage: "externaldrive") {
                    InfoGrid(rows: [
                        ("Database trend", "not available yet"),
                        ("FTS index", model.health?.ftsReady == true ? "ready" : "missing"),
                        ("Backup history", model.health?.lastBackup ?? "none"),
                        ("Dump history", model.health?.lastDump ?? "none")
                    ])
                }
            }
        }
        .onAppear {
            model.reloadHealth()
            model.refreshResourceSample()
        }
    }
}

struct SparklineView: View {
    let values: [Double]

    var body: some View {
        GeometryReader { proxy in
            let path = sparklinePath(size: proxy.size)
            path
                .stroke(.cyan, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .background(.black.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .frame(height: 58)
    }

    private func sparklinePath(size: CGSize) -> Path {
        var path = Path()
        guard values.count > 1, let min = values.min(), let max = values.max(), max > min else {
            path.move(to: CGPoint(x: 0, y: size.height / 2))
            path.addLine(to: CGPoint(x: size.width, y: size.height / 2))
            return path
        }

        for (index, value) in values.enumerated() {
            let x = size.width * CGFloat(index) / CGFloat(values.count - 1)
            let normalized = (value - min) / (max - min)
            let y = size.height - (size.height * CGFloat(normalized))
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}

struct UsageBreakdown: View {
    let activity: [String]

    var body: some View {
        let counts = Dictionary(grouping: activity, by: { $0 }).mapValues(\.count)
        if counts.isEmpty {
            Text("not available yet")
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(counts.sorted { $0.key < $1.key }, id: \.key) { key, value in
                    Text("\(key): \(value)")
                }
            }
        }
    }
}
