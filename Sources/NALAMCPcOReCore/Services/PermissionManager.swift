import Foundation

public final class PermissionManager {
    public private(set) var knownClients: Set<String>

    public init(knownClients: [String] = NALAConstants.defaultKnownClients) {
        self.knownClients = Set(knownClients)
    }

    public func decision(client: String, action: PermissionAction) -> PermissionDecision {
        if [.deleteMemory, .overwriteDecision, .bulkImportWithoutReview, .wipeDatabase, .remoteExecute].contains(action) {
            return .deny
        }

        guard knownClients.contains(client) else {
            return .deny
        }

        switch action {
        case .read, .search, .addSessionSummary, .addBugReport, .addDecisionCandidate, .exportDump:
            return .allow
        case .deleteMemory, .overwriteDecision, .bulkImportWithoutReview, .wipeDatabase, .remoteExecute:
            return .deny
        }
    }

    public func addKnownClient(_ client: String) {
        knownClients.insert(client)
    }
}
