import Foundation

public final class ClientConnectionManager {
    private let permissionManager: PermissionManager

    public init(permissionManager: PermissionManager) {
        self.permissionManager = permissionManager
    }

    public func states(helperStatus: HelperStatus, activity: [ClientActivity]) throws -> [ClientConnectionInfo] {
        try MCPClientKind.allCases.map { client in
            try state(for: client, helperStatus: helperStatus, activity: activity)
        }
    }

    public func state(for client: MCPClientKind, helperStatus: HelperStatus, activity: [ClientActivity]) throws -> ClientConnectionInfo {
        if client == .nalaBrainFuture {
            return ClientConnectionInfo(client: client, state: .planned, shortStatus: "planned v0.3 sync target", lastSeen: nil, lastTool: nil, permission: .ask)
        }

        let permission = permissionManager.decision(client: client.permissionClientName, action: .search)
        guard permission != .deny else {
            return ClientConnectionInfo(client: client, state: .denied, shortStatus: "blocked by policy", lastSeen: nil, lastTool: nil, permission: permission)
        }

        let recent = activity
            .filter { $0.client == client }
            .sorted { $0.timestamp > $1.timestamp }
            .first

        if let recent, Date().timeIntervalSince(recent.timestamp) <= 300 {
            return ClientConnectionInfo(client: client, state: .active, shortStatus: "recent \(recent.tool)", lastSeen: recent.timestamp, lastTool: recent.tool, permission: permission)
        }

        if helperStatus.stableHelperExecutable {
            return ClientConnectionInfo(client: client, state: .healthy, shortStatus: "stable helper executable", lastSeen: recent?.timestamp, lastTool: recent?.tool, permission: permission)
        }

        if helperStatus.buildHelperExists {
            return ClientConnectionInfo(client: client, state: .reachable, shortStatus: "build helper reachable", lastSeen: recent?.timestamp, lastTool: recent?.tool, permission: permission)
        }

        return ClientConnectionInfo(client: client, state: .known, shortStatus: "known client, helper missing", lastSeen: recent?.timestamp, lastTool: recent?.tool, permission: permission)
    }
}
