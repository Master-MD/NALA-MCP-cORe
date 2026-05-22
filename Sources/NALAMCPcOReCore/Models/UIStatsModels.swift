import Foundation

public enum MCPClientKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case codex = "Codex"
    case geminiCLI = "Gemini CLI"
    case googleAntigravity = "Google Antigravity"
    case manual = "Manual"
    case nalaBrainFuture = "NALA-bRaiN future"

    public var id: String { rawValue }

    public var configFileLocation: String {
        switch self {
        case .codex: "~/.codex/config.toml"
        case .geminiCLI: "~/.gemini/settings.json"
        case .googleAntigravity: "~/.gemini/antigravity/mcp_config.json"
        case .manual: "Manual STDIO form"
        case .nalaBrainFuture: "planned v0.3 sync target"
        }
    }

    public var permissionClientName: String { rawValue }
}

public enum ClientConnectionState: String, Codable, CaseIterable, Sendable {
    case known
    case configured
    case reachable
    case healthy
    case active
    case idle
    case denied
    case error
    case planned
}

public struct HelperStatus: Codable, Equatable, Sendable {
    public let buildHelperExists: Bool
    public let stableHelperExists: Bool
    public let stableHelperExecutable: Bool

    public init(buildHelperExists: Bool, stableHelperExists: Bool, stableHelperExecutable: Bool) {
        self.buildHelperExists = buildHelperExists
        self.stableHelperExists = stableHelperExists
        self.stableHelperExecutable = stableHelperExecutable
    }
}

public struct ClientActivity: Codable, Equatable, Sendable {
    public let client: MCPClientKind
    public let tool: String
    public let result: String
    public let timestamp: Date
    public let durationMS: Int

    public init(client: MCPClientKind, tool: String, result: String, timestamp: Date, durationMS: Int) {
        self.client = client
        self.tool = tool
        self.result = result
        self.timestamp = timestamp
        self.durationMS = durationMS
    }
}

public struct ClientConnectionInfo: Codable, Equatable, Identifiable, Sendable {
    public let client: MCPClientKind
    public let state: ClientConnectionState
    public let shortStatus: String
    public let lastSeen: Date?
    public let lastTool: String?
    public let permission: PermissionDecision

    public var id: String { client.rawValue }

    public init(client: MCPClientKind, state: ClientConnectionState, shortStatus: String, lastSeen: Date?, lastTool: String?, permission: PermissionDecision) {
        self.client = client
        self.state = state
        self.shortStatus = shortStatus
        self.lastSeen = lastSeen
        self.lastTool = lastTool
        self.permission = permission
    }
}

public struct ClientConfigBundle: Codable, Equatable, Sendable {
    public let codexTOML: String
    public let geminiJSON: String
    public let antigravityJSON: String
    public let manualSTDIO: String
    public let ruleSnippet: String
}

public struct HelperSymlinkPlan: Codable, Equatable, Sendable {
    public let realHelperURL: URL
    public let linkURL: URL
    public let commands: [String]
    public let requiresSudo: Bool
}

public struct ResourceSample: Codable, Equatable, Sendable {
    public let timestamp: Date
    public let cpuPercent: Double
    public let ramMB: Double
    public let callsPerMinute: Double

    public init(timestamp: Date, cpuPercent: Double, ramMB: Double, callsPerMinute: Double) {
        self.timestamp = timestamp
        self.cpuPercent = cpuPercent
        self.ramMB = ramMB
        self.callsPerMinute = callsPerMinute
    }
}

public struct ResourceMonitorSummary: Codable, Equatable, Sendable {
    public let pid: Int?
    public let uptimeSeconds: TimeInterval?
    public let samples: [ResourceSample]
    public let totalRequests: Int
    public let failedRequests: Int
    public let lastRequestAt: Date?

    public init(pid: Int?, uptimeSeconds: TimeInterval?, samples: [ResourceSample], totalRequests: Int, failedRequests: Int, lastRequestAt: Date?) {
        self.pid = pid
        self.uptimeSeconds = uptimeSeconds
        self.samples = Array(samples.suffix(60))
        self.totalRequests = totalRequests
        self.failedRequests = failedRequests
        self.lastRequestAt = lastRequestAt
    }

    public var currentCPUPercent: Double? { samples.last?.cpuPercent }
    public var averageCPUPercent: Double? { average(samples.map(\.cpuPercent)) }
    public var currentRAMMB: Double? { samples.last?.ramMB }
    public var averageRAMMB: Double? { average(samples.map(\.ramMB)) }
    public var peakRAMMB: Double? { samples.map(\.ramMB).max() }
    public var currentCallsPerMinute: Double? { samples.last?.callsPerMinute }

    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}

public enum MenuBarVisualState: String, Codable, Sendable {
    case healthy
    case warning
    case error
    case stopped
    case active
}

public enum FlowPolicy: String, Codable, Sendable {
    case allow
    case deny
    case planned
}

public enum FlowState: String, Codable, Sendable {
    case activeAllowed
    case configuredIdle
    case blocked
    case internalLocal
    case planned
}

public struct FlowEdge: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let from: String
    public let to: String
    public let direction: String
    public let state: FlowState
    public let mode: String
    public let lastActivity: String
    public let policy: FlowPolicy

    public init(from: String, to: String, direction: String, state: FlowState, mode: String, lastActivity: String, policy: FlowPolicy) {
        self.id = "\(from)->\(to)->\(mode)"
        self.from = from
        self.to = to
        self.direction = direction
        self.state = state
        self.mode = mode
        self.lastActivity = lastActivity
        self.policy = policy
    }
}

public struct FlowMatrix: Codable, Equatable, Sendable {
    public let nodes: [String]
    public let edges: [FlowEdge]

    public init(nodes: [String], edges: [FlowEdge]) {
        self.nodes = nodes
        self.edges = edges
    }
}

public enum UpgradePreflightStatus: String, Codable, Sendable {
    case noV01VaultFound
    case ready
    case requiresUserStop
    case invalid
}

public struct UpgradePreflightReport: Codable, Equatable, Sendable {
    public let status: UpgradePreflightStatus
    public let vaultURL: URL?
    public let detectedClients: [MCPClientKind]
    public let instructions: String
    public let canInspectWhileRunning: Bool
    public let canMigrateWhileRunning: Bool
}
