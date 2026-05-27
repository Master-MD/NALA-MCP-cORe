import Foundation

public enum NALAConstants {
    public static let appName = "NALA-MCP-cORe"
    public static let version = "0.1.0"
    public static let bundleIdentifier = "ch.nala.mcp-core"
    public static let defaultKnownClients = ["Codex", "Gemini CLI", "Google Antigravity", "Manual", "NALA-bRaiN future"]
}

public enum StableCoreError: Error, LocalizedError {
    case databaseOpenFailed(String)
    case databaseExecutionFailed(String)
    case operationFailed(String)
    case permissionDenied(String)
    case unsafeBindHost(String)
    case invalidBackup(String)

    public var errorDescription: String? {
        switch self {
        case .databaseOpenFailed(let message):
            return "Database open failed: \(message)"
        case .databaseExecutionFailed(let message):
            return "Database execution failed: \(message)"
        case .operationFailed(let message):
            return message
        case .permissionDenied(let message):
            return "Permission denied: \(message)"
        case .unsafeBindHost(let host):
            return "Unsafe bind host denied in v0.1: \(host)"
        case .invalidBackup(let message):
            return "Invalid backup: \(message)"
        }
    }
}

public struct VaultPaths: Equatable {
    public let rootURL: URL
    public let vaultURL: URL
    public let databaseURL: URL
    public let eventsURL: URL
    public let projectsURL: URL
    public let attachmentsURL: URL
    public let vaultDumpsURL: URL
    public let vaultBackupsURL: URL
    public let configURL: URL
    public let settingsURL: URL
    public let permissionsURL: URL
    public let clientsURL: URL
    public let indexURL: URL
    public let ftsStatusURL: URL
    public let fingerprintIndexURL: URL
    public let logsURL: URL
    public let appLogURL: URL
    public let serverLogURL: URL
    public let auditLogURL: URL
    public let sandboxesURL: URL
    public let exportsURL: URL

    public static func `default`() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent(NALAConstants.appName, isDirectory: true)
    }

    public init(rootURL: URL) {
        self.rootURL = rootURL
        self.vaultURL = rootURL.appendingPathComponent("Vault", isDirectory: true)
        self.databaseURL = vaultURL.appendingPathComponent("nala-mcp-core.sqlite")
        self.eventsURL = vaultURL.appendingPathComponent("events.jsonl")
        self.projectsURL = vaultURL.appendingPathComponent("projects", isDirectory: true)
        self.attachmentsURL = vaultURL.appendingPathComponent("attachments", isDirectory: true)
        self.vaultDumpsURL = vaultURL.appendingPathComponent("dumps", isDirectory: true)
        self.vaultBackupsURL = vaultURL.appendingPathComponent("backups", isDirectory: true)
        self.configURL = rootURL.appendingPathComponent("Config", isDirectory: true)
        self.settingsURL = configURL.appendingPathComponent("settings.json")
        self.permissionsURL = configURL.appendingPathComponent("permissions.json")
        self.clientsURL = configURL.appendingPathComponent("clients.json")
        self.indexURL = rootURL.appendingPathComponent("Index", isDirectory: true)
        self.ftsStatusURL = indexURL.appendingPathComponent("fts-status.json")
        self.fingerprintIndexURL = indexURL.appendingPathComponent("fingerprint-index.jsonl")
        self.logsURL = rootURL.appendingPathComponent("Logs", isDirectory: true)
        self.appLogURL = logsURL.appendingPathComponent("app.log")
        self.serverLogURL = logsURL.appendingPathComponent("server.log")
        self.auditLogURL = logsURL.appendingPathComponent("audit.log")
        self.sandboxesURL = rootURL.appendingPathComponent("Sandboxes", isDirectory: true)
        self.exportsURL = rootURL.appendingPathComponent("Exports", isDirectory: true)
    }

    public var requiredDirectories: [URL] {
        [
            rootURL, vaultURL, projectsURL, attachmentsURL, vaultDumpsURL, vaultBackupsURL,
            configURL, indexURL, logsURL, sandboxesURL, exportsURL
        ]
    }
}

public enum ObjectType: String, Codable, CaseIterable, Identifiable {
    case project
    case memory
    case decision
    case decisionCandidate = "decision_candidate"
    case bug
    case prompt
    case sessionSummary = "session_summary"
    case artifact
    case sourceDocument = "source_document"
    case client
    case permission
    case backupRun = "backup_run"
    case restoreRun = "restore_run"
    case dumpRun = "dump_run"
    case auditLog = "audit_log"
    case importRun = "import_run"
    case exportRun = "export_run"
    case objectVersion = "object_version"
    case contentFingerprint = "content_fingerprint"
    case reviewQueue = "review_queue"
    case labRun = "lab_run"
    case labArtifact = "lab_artifact"

    public var id: String { rawValue }

    public var tableName: String {
        switch self {
        case .project: "projects"
        case .memory: "memories"
        case .decision: "decisions"
        case .decisionCandidate: "decision_candidates"
        case .bug: "bugs"
        case .prompt: "prompts"
        case .sessionSummary: "session_summaries"
        case .artifact: "artifacts"
        case .sourceDocument: "source_documents"
        case .client: "clients"
        case .permission: "permissions"
        case .backupRun: "backup_runs"
        case .restoreRun: "restore_runs"
        case .dumpRun: "dump_runs"
        case .auditLog: "audit_log"
        case .importRun: "import_runs"
        case .exportRun: "export_runs"
        case .objectVersion: "object_versions"
        case .contentFingerprint: "content_fingerprints"
        case .reviewQueue: "review_queue"
        case .labRun: "lab_runs"
        case .labArtifact: "lab_artifacts"
        }
    }

    public var displayName: String {
        switch self {
        case .project: "Project"
        case .memory: "Memory"
        case .decision: "Decision"
        case .decisionCandidate: "Decision Candidate"
        case .bug: "Bug"
        case .prompt: "Prompt"
        case .sessionSummary: "Session Summary"
        case .artifact: "Artifact"
        case .sourceDocument: "Source Document"
        case .client: "Client"
        case .permission: "Permission"
        case .backupRun: "Backup Run"
        case .restoreRun: "Restore Run"
        case .dumpRun: "Dump Run"
        case .auditLog: "Audit Log"
        case .importRun: "Import Run"
        case .exportRun: "Export Run"
        case .objectVersion: "Object Version"
        case .contentFingerprint: "Content Fingerprint"
        case .reviewQueue: "Review Queue"
        case .labRun: "Lab Run"
        case .labArtifact: "Lab Artifact"
        }
    }
}

public struct CoreObject: Codable, Identifiable, Equatable {
    public let stableID: String
    public let type: ObjectType
    public let projectID: String?
    public let title: String
    public let content: String
    public let metadataJSON: String
    public let sourceClient: String
    public let sourcePath: String?
    public let sourceDocumentID: String?
    public let createdAt: String
    public let updatedAt: String
    public let importedAt: String?
    public let contentHash: String
    public let normalizedHash: String
    public let semanticFingerprint: String
    public let version: Int
    public let parentID: String?
    public let status: String

    public var id: String { stableID }
}

public struct ProjectSummary: Codable, Identifiable, Equatable {
    public let stableID: String
    public let name: String
    public let content: String
    public let updatedAt: String

    public var id: String { stableID }
}

public struct SearchResult: Codable, Identifiable, Equatable {
    public let stableID: String
    public let objectType: String
    public let projectName: String
    public let title: String
    public let content: String
    public let sourceClient: String
    public let updatedAt: String
    public let source: String

    public var id: String { stableID }
}

public struct Fingerprint: Codable, Equatable {
    public let contentHash: String
    public let normalizedHash: String
    public let semanticFingerprint: String
}

public enum DuplicateClassification: String, Codable {
    case alreadyExists
    case duplicateFormatVariant
    case newObject
}

public struct HealthStatus: Codable, Equatable {
    public let appName: String
    public let version: String
    public let databaseStatus: String
    public let journalMode: String
    public let ftsReady: Bool
    public let externalAccess: String
    public let currentUser: String
    public let vaultPath: String
    public let lastBackup: String?
    public let lastDump: String?
    public let lastLabRun: String?
    public let knownClients: [String]
}

public struct BackupResult: Codable, Equatable {
    public let fullBackupURL: URL
    public let manifestURL: URL
    public let checksumsURL: URL
    public let zipURL: URL
}

public enum RestoreDryRunStatus: String, Codable {
    case ready
    case failed
}

public struct RestoreDryRun: Codable, Equatable {
    public let status: RestoreDryRunStatus
    public let backupURL: URL
    public let objectCounts: [String: Int]
    public let checksumFailures: [String]
    public let previewText: String
}

public struct DumpResult: Codable, Equatable {
    public let rootURL: URL
    public let manifestURL: URL
    public let checksumsURL: URL
}

public struct LabSandbox: Codable, Equatable {
    public let rootURL: URL
    public let databaseSnapshotURL: URL
    public let eventsSnapshotURL: URL
    public let inputURL: URL
    public let outputURL: URL
    public let reportJSONURL: URL
    public let reportMarkdownURL: URL
    public let checksumsURL: URL
    public let logsURL: URL
}

public enum PermissionDecision: String, Codable, Sendable {
    case allow
    case ask
    case deny
}

public enum PermissionAction: String, Codable, CaseIterable {
    case read
    case search
    case addSessionSummary = "add_session_summary"
    case addBugReport = "add_bug_report"
    case addDecisionCandidate = "add_decision_candidate"
    case exportDump = "export_dump"
    case deleteMemory = "delete_memory"
    case overwriteDecision = "overwrite_decision"
    case bulkImportWithoutReview = "bulk_import_without_review"
    case wipeDatabase = "wipe_database"
    case remoteExecute = "remote_execute"
}

public enum MCPToolStatus: String, Codable {
    case ok
    case denied
    case error
}

public struct MCPToolResult: Codable, Equatable {
    public let status: MCPToolStatus
    public let text: String
    public let payload: [String: String]
}
