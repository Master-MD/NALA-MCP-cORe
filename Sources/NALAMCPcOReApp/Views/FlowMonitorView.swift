import NALAMCPcOReCore
import SwiftUI

struct FlowMonitorView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        let matrix = model.flowMatrix()
        ScreenContainer(title: "Flow Monitor", subtitle: "Shows allowed, blocked, internal, and planned local data flows.") {
            AdaptiveCardGrid {
                ForEach(matrix.edges.prefix(12)) { edge in
                    FlowEdgeCard(edge: edge)
                }
            }

            Table(matrix.edges) {
                TableColumn("From", value: \.from)
                TableColumn("To", value: \.to)
                TableColumn("Direction", value: \.direction)
                TableColumn("State") { edge in
                    Text(edge.state.rawValue)
                        .foregroundStyle(edge.state.color)
                }
                TableColumn("Mode", value: \.mode)
                TableColumn("Last Activity", value: \.lastActivity)
                TableColumn("Policy") { edge in
                    Text(edge.policy.rawValue)
                        .foregroundStyle(edge.policy == .deny ? .red : .secondary)
                }
            }
            .frame(minHeight: 320)
        }
    }
}

struct FlowEdgeCard: View {
    let edge: FlowEdge

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(edge.from)
                    .lineLimit(1)
                Image(systemName: "arrow.right")
                    .foregroundStyle(edge.state.color)
                Text(edge.to)
                    .lineLimit(1)
            }
            .font(.headline)
            Text(edge.mode)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Text(edge.policy.rawValue.uppercased())
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(edge.state.color.opacity(0.18))
                .foregroundStyle(edge.state.color)
                .clipShape(Capsule())
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private extension FlowState {
    var color: Color {
        switch self {
        case .activeAllowed: .green
        case .configuredIdle: .yellow
        case .blocked: .red
        case .internalLocal: .blue
        case .planned: .secondary
        }
    }
}
