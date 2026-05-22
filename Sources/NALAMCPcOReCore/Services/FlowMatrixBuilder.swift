import Foundation

public final class FlowMatrixBuilder {
    public init() {}

    public func build(clientStates: [ClientConnectionInfo]) -> FlowMatrix {
        var edges: [FlowEdge] = []

        for clientState in clientStates where clientState.client != .nalaBrainFuture {
            let state: FlowState = clientState.state == .active ? .activeAllowed : .configuredIdle
            edges.append(FlowEdge(
                from: clientState.client.rawValue,
                to: "MCP Helper",
                direction: "inbound",
                state: state,
                mode: "read/write candidate",
                lastActivity: clientState.lastSeen.map { ISO8601DateFormatter().string(from: $0) } ?? "none",
                policy: clientState.permission == .deny ? .deny : .allow
            ))
        }

        edges.append(contentsOf: [
            FlowEdge(from: "MCP Helper", to: "SQLite Vault", direction: "local", state: .internalLocal, mode: "Core API write", lastActivity: "live", policy: .allow),
            FlowEdge(from: "MCP Helper", to: "FTS Index", direction: "local", state: .internalLocal, mode: "indexed search", lastActivity: "live", policy: .allow),
            FlowEdge(from: "MCP Helper", to: "Event Journal", direction: "local", state: .internalLocal, mode: "append-only JSONL", lastActivity: "live", policy: .allow),
            FlowEdge(from: "SQLite Vault", to: "Backups", direction: "local", state: .internalLocal, mode: "copy/checksum/zip", lastActivity: "manual", policy: .allow),
            FlowEdge(from: "SQLite Vault", to: "Dumps", direction: "local", state: .internalLocal, mode: "export package", lastActivity: "manual", policy: .allow),
            FlowEdge(from: "Dumps", to: "SSH Sync Lab", direction: "outbound", state: .planned, mode: "planned lab", lastActivity: "never", policy: .planned),
            FlowEdge(from: "Dumps", to: "Cloud Export Folder", direction: "local", state: .planned, mode: "planned folder export", lastActivity: "never", policy: .planned),
            FlowEdge(from: "Labs Sandbox", to: "Sandbox Copy", direction: "local", state: .internalLocal, mode: "snapshot only", lastActivity: "manual", policy: .allow),
            FlowEdge(from: "Labs", to: "Live Vault", direction: "local", state: .blocked, mode: "direct write forbidden", lastActivity: "never", policy: .deny),
            FlowEdge(from: "Internet", to: "SQLite Vault", direction: "inbound", state: .blocked, mode: "external access blocked", lastActivity: "never", policy: .deny),
            FlowEdge(from: "LAN", to: "SQLite Vault", direction: "inbound", state: .blocked, mode: "LAN access blocked", lastActivity: "never", policy: .deny),
            FlowEdge(from: "NALA-bRaiN Sync Package", to: "NALA-bRaiN future", direction: "outbound", state: .planned, mode: "v0.3 package", lastActivity: "never", policy: .planned)
        ])

        let nodes = Array(Set(edges.flatMap { [$0.from, $0.to] })).sorted()
        return FlowMatrix(nodes: nodes, edges: edges)
    }
}
