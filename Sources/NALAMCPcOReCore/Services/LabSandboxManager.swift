import Foundation

public final class LabSandboxManager {
    private let paths: VaultPaths
    private let database: DatabaseManager

    public init(paths: VaultPaths, database: DatabaseManager) {
        self.paths = paths
        self.database = database
    }

    public func createSandbox(featureName: String) throws -> LabSandbox {
        try database.checkpoint()
        let safeFeature = featureName
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9-]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        let root = paths.sandboxesURL.appendingPathComponent("lab-\(CoreClock.pathTimestamp())-\(safeFeature)", isDirectory: true)
        let sandbox = LabSandbox(
            rootURL: root,
            databaseSnapshotURL: root.appendingPathComponent("nala.snapshot.sqlite"),
            eventsSnapshotURL: root.appendingPathComponent("events.snapshot.jsonl"),
            inputURL: root.appendingPathComponent("input", isDirectory: true),
            outputURL: root.appendingPathComponent("output", isDirectory: true),
            reportJSONURL: root.appendingPathComponent("report.json"),
            reportMarkdownURL: root.appendingPathComponent("report.md"),
            checksumsURL: root.appendingPathComponent("checksums.sha256"),
            logsURL: root.appendingPathComponent("logs", isDirectory: true)
        )

        for directory in [root, sandbox.inputURL, sandbox.outputURL, sandbox.logsURL] {
            try FileManager.default.ensureDirectory(directory)
        }
        try FileManager.default.copyItem(at: paths.databaseURL, to: sandbox.databaseSnapshotURL)
        if FileManager.default.fileExists(atPath: paths.eventsURL.path) {
            try FileManager.default.copyItem(at: paths.eventsURL, to: sandbox.eventsSnapshotURL)
        } else {
            try "".write(to: sandbox.eventsSnapshotURL, atomically: true, encoding: .utf8)
        }
        return sandbox
    }

    public func finalize(_ sandbox: LabSandbox, featureName: String, status: String, message: String) throws {
        let report: [String: String] = [
            "feature": featureName,
            "status": status,
            "message": message,
            "created_at": CoreClock.nowString(),
            "live_vault_modified": "false"
        ]
        let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: sandbox.reportJSONURL)
        try """
        # Lab Report

        Feature: \(featureName)
        Status: \(status)
        Live vault modified: false

        \(message)
        """.write(to: sandbox.reportMarkdownURL, atomically: true, encoding: .utf8)
        try ChecksumManager.writeChecksums(for: sandbox.rootURL, to: sandbox.checksumsURL)
    }
}

public struct ExperimentalFeature: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let state: String
}

public enum ExperimentalFeatureRegistry {
    public static let features: [ExperimentalFeature] = [
        ExperimentalFeature(id: "import-lab", name: "Import Lab", state: "planned"),
        ExperimentalFeature(id: "export-lab", name: "Export Lab", state: "planned"),
        ExperimentalFeature(id: "mongodb-export-lab", name: "MongoDB Export Lab", state: "planned"),
        ExperimentalFeature(id: "chromadb-export-lab", name: "ChromaDB Export Lab", state: "planned"),
        ExperimentalFeature(id: "mempalace-export-lab", name: "MemPalace Export Lab", state: "planned"),
        ExperimentalFeature(id: "docling-rag-export-lab", name: "Docling/RAG Export Lab", state: "planned"),
        ExperimentalFeature(id: "nala-brain-sync-lab", name: "NALA-bRaiN Sync Lab", state: "planned"),
        ExperimentalFeature(id: "ssh-sync-lab", name: "SSH Sync Lab", state: "planned"),
        ExperimentalFeature(id: "cloud-folder-export-lab", name: "Cloud Folder Export Lab", state: "planned")
    ]
}
