import Foundation

public final class BackupManager {
    private let paths: VaultPaths
    private let database: DatabaseManager

    public init(paths: VaultPaths, database: DatabaseManager) {
        self.paths = paths
        self.database = database
    }

    public func backupNow(targetFolder: URL? = nil) throws -> BackupResult {
        try database.checkpoint()

        let root = targetFolder ?? paths.vaultBackupsURL.appendingPathComponent("NALA-MCP-cORe-Backups", isDirectory: true)
        let timestamp = CoreClock.pathTimestamp()
        let fullRoot = root.appendingPathComponent("full", isDirectory: true)
        let deltasRoot = root.appendingPathComponent("deltas", isDirectory: true)
        let manifestsRoot = root.appendingPathComponent("manifests", isDirectory: true)
        let backupURL = fullRoot.appendingPathComponent("full-\(timestamp)", isDirectory: true)

        try FileManager.default.ensureDirectory(fullRoot)
        try FileManager.default.ensureDirectory(deltasRoot)
        try FileManager.default.ensureDirectory(manifestsRoot)
        try FileManager.default.ensureDirectory(backupURL)

        let databaseCopy = backupURL.appendingPathComponent("nala-mcp-core.sqlite")
        let eventsCopy = backupURL.appendingPathComponent("events.jsonl")
        if FileManager.default.fileExists(atPath: databaseCopy.path) {
            try FileManager.default.removeItem(at: databaseCopy)
        }
        try FileManager.default.copyItem(at: paths.databaseURL, to: databaseCopy)
        if FileManager.default.fileExists(atPath: paths.eventsURL.path) {
            try FileManager.default.copyItem(at: paths.eventsURL, to: eventsCopy)
        } else {
            try "".write(to: eventsCopy, atomically: true, encoding: .utf8)
        }

        let deltaURL = deltasRoot.appendingPathComponent("delta-\(timestamp).jsonl")
        try FileManager.default.copyItem(at: eventsCopy, to: deltaURL)

        let readme = """
        # NALA-MCP-cORe Restore

        This backup was created by NALA-MCP-cORe \(NALAConstants.version).

        Always run restore dry-run first. Restore writes are intentionally guarded in v0.1.
        """
        try readme.write(to: backupURL.appendingPathComponent("restore-readme.md"), atomically: true, encoding: .utf8)

        let manifestURL = backupURL.appendingPathComponent("manifest.json")
        let manifest: [String: Any] = [
            "app": NALAConstants.appName,
            "version": NALAConstants.version,
            "created_at": CoreClock.nowString(),
            "type": "full",
            "database": "nala-mcp-core.sqlite",
            "events": "events.jsonl"
        ]
        let data = try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: manifestURL)

        let checksumsURL = backupURL.appendingPathComponent("checksums.sha256")
        try ChecksumManager.writeChecksums(for: backupURL, to: checksumsURL)

        let manifestCopyURL = manifestsRoot.appendingPathComponent("manifest-\(timestamp).json")
        try FileManager.default.copyItem(at: manifestURL, to: manifestCopyURL)

        let zipURL = backupURL.appendingPathExtension("zip")
        try createZip(source: backupURL, destination: zipURL)

        return BackupResult(fullBackupURL: backupURL, manifestURL: manifestURL, checksumsURL: checksumsURL, zipURL: zipURL)
    }

    private func createZip(source: URL, destination: URL) throws {
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-c", "-k", "--keepParent", source.path, destination.path]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw StableCoreError.operationFailed("ZIP creation failed")
        }
    }
}
