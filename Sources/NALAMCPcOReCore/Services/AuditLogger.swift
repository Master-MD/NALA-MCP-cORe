import Foundation

public final class AuditLogger {
    private let logManager: LogManager

    public init(logManager: LogManager) {
        self.logManager = logManager
    }

    public func record(_ action: String, objectID: String, sourceClient: String, message: String) throws {
        try logManager.appendAudit("\(action) object=\(objectID) client=\(sourceClient) \(message)")
    }
}
