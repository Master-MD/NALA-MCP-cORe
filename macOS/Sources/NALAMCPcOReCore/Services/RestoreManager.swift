import Foundation

public final class RestoreManager {
    public init() {}

    public func dryRun(from backupURL: URL) throws -> RestoreDryRun {
        let manifestURL = backupURL.appendingPathComponent("manifest.json")
        let checksumsURL = backupURL.appendingPathComponent("checksums.sha256")
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            throw StableCoreError.invalidBackup("manifest.json is missing")
        }
        guard FileManager.default.fileExists(atPath: checksumsURL.path) else {
            throw StableCoreError.invalidBackup("checksums.sha256 is missing")
        }

        let failures = try verifyChecksums(rootURL: backupURL, checksumsURL: checksumsURL)
        let counts = try previewCounts(databaseURL: backupURL.appendingPathComponent("nala-mcp-core.sqlite"))
        let text = """
        Restore dry-run complete.
        Backup: \(backupURL.path)
        Checksum failures: \(failures.count)
        Objects: \(counts.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ", "))
        """

        return RestoreDryRun(
            status: failures.isEmpty ? .ready : .failed,
            backupURL: backupURL,
            objectCounts: counts,
            checksumFailures: failures,
            previewText: text
        )
    }

    private func verifyChecksums(rootURL: URL, checksumsURL: URL) throws -> [String] {
        let content = try String(contentsOf: checksumsURL, encoding: .utf8)
        var failures: [String] = []
        for line in content.split(separator: "\n") {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 2 else { continue }
            let expected = String(parts[0])
            let relative = String(parts[1])
            let fileURL = rootURL.appendingPathComponent(relative)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                failures.append(relative)
                continue
            }
            let actual = try ChecksumManager.sha256File(fileURL)
            if expected != actual {
                failures.append(relative)
            }
        }
        return failures
    }

    private func previewCounts(databaseURL: URL) throws -> [String: Int] {
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("NALA-MCP-cORe-RestoreDryRun", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.ensureDirectory(tempRoot)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let tempDatabaseURL = tempRoot.appendingPathComponent("nala-mcp-core.sqlite")
        try FileManager.default.copyItem(at: databaseURL, to: tempDatabaseURL)

        let fingerprintManager = FingerprintManager()
        let database = DatabaseManager(databaseURL: tempDatabaseURL, fingerprintManager: fingerprintManager)
        try database.open()
        var counts: [String: Int] = [:]
        for table in DatabaseManager.tableNames {
            counts[table] = (try? database.count(table: table)) ?? 0
        }
        return counts
    }
}
