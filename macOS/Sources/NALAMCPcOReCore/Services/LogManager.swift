import Foundation

public final class LogManager {
    private let paths: VaultPaths

    public init(paths: VaultPaths) {
        self.paths = paths
    }

    public func appendApp(_ message: String) throws {
        try append(message, to: paths.appLogURL)
    }

    public func appendServer(_ message: String) throws {
        try append(message, to: paths.serverLogURL)
    }

    public func appendAudit(_ message: String) throws {
        try append(message, to: paths.auditLogURL)
    }

    public func readLog(_ name: String) -> String {
        let url: URL
        switch name {
        case "server": url = paths.serverLogURL
        case "audit": url = paths.auditLogURL
        default: url = paths.appLogURL
        }
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }

    private func append(_ message: String, to url: URL) throws {
        let sanitized = sanitize(message)
        let line = "[\(CoreClock.nowString())] \(sanitized)\n"
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.ensureDirectory(url.deletingLastPathComponent())
            try Data().write(to: url)
        }
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: Data(line.utf8))
    }

    private func sanitize(_ message: String) -> String {
        var output = message
        let secretWords = ["token", "secret", "password", "api_key", "apikey"]
        for word in secretWords {
            output = output.replacingOccurrences(
                of: "(?i)\(word)=\\S+",
                with: "\(word)=<redacted>",
                options: .regularExpression
            )
        }
        return output
    }
}
