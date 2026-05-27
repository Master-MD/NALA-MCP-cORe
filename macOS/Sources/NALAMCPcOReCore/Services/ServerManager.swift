import Foundation

public enum MCPTransport: String, Codable {
    case stdio
    case localhostHTTP = "localhost_http"
}

public final class ServerManager {
    public private(set) var isRunning = false
    public private(set) var transport: MCPTransport = .stdio
    public private(set) var host = "127.0.0.1"
    public private(set) var port: Int?

    private let logManager: LogManager

    public init(logManager: LogManager) {
        self.logManager = logManager
    }

    public func start(transport: MCPTransport = .stdio, host: String = "127.0.0.1", port: Int? = nil) throws {
        try validateLocalBindHost(host)
        self.transport = transport
        self.host = host
        self.port = port
        self.isRunning = true
        try logManager.appendServer("server started transport=\(transport.rawValue) host=\(host) port=\(port.map(String.init) ?? "stdio")")
    }

    public func stop() throws {
        isRunning = false
        try logManager.appendServer("server stopped")
    }

    public func restart() throws {
        let currentTransport = transport
        let currentHost = host
        let currentPort = port
        try stop()
        try start(transport: currentTransport, host: currentHost, port: currentPort)
    }

    public func validateLocalBindHost(_ host: String) throws {
        let allowed = ["127.0.0.1", "localhost", "::1"]
        guard allowed.contains(host) else {
            throw StableCoreError.unsafeBindHost(host)
        }
    }
}
