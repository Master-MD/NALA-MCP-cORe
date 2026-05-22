import Foundation

public final class DumpManager {
    private let paths: VaultPaths
    private let database: DatabaseManager

    public init(paths: VaultPaths, database: DatabaseManager) {
        self.paths = paths
        self.database = database
    }

    public func exportFullDump(project: String? = nil) throws -> DumpResult {
        try database.checkpoint()
        let root = paths.exportsURL.appendingPathComponent("NALA-Dump-\(CoreClock.pathTimestamp())", isDirectory: true)
        try createDumpStructure(root)
        try FileManager.default.copyItem(at: paths.databaseURL, to: root.appendingPathComponent("sqlite/nala-mcp-core.sqlite"))
        try copyEvents(to: root.appendingPathComponent("jsonl/events.jsonl"))
        try exportStandardJSONL(to: root.appendingPathComponent("jsonl", isDirectory: true))
        try writeProjectMarkdown(to: root.appendingPathComponent("markdown", isDirectory: true))
        try database.exportJSONL(table: "content_fingerprints", to: root.appendingPathComponent("index/fingerprint-index.jsonl"))
        try writeObjectIndex(to: root.appendingPathComponent("index/object-index.jsonl"))
        try writeBrainSyncFiles(to: root.appendingPathComponent("nala-brain", isDirectory: true))
        try "Export completed at \(CoreClock.nowString())\n".write(to: root.appendingPathComponent("logs/export.log"), atomically: true, encoding: .utf8)
        let manifestURL = root.appendingPathComponent("manifest.json")
        try writeManifest(kind: "nala-full", root: root, to: manifestURL, project: project)
        let checksumsURL = root.appendingPathComponent("checksums.sha256")
        try ChecksumManager.writeChecksums(for: root, to: checksumsURL)
        return DumpResult(rootURL: root, manifestURL: manifestURL, checksumsURL: checksumsURL)
    }

    public func exportBrainSyncPackage() throws -> DumpResult {
        let root = paths.exportsURL.appendingPathComponent("NALA-bRaiN-Sync-\(CoreClock.pathTimestamp())", isDirectory: true)
        for directory in [
            root,
            root.appendingPathComponent("index", isDirectory: true),
            root.appendingPathComponent("data", isDirectory: true),
            root.appendingPathComponent("markdown/projects", isDirectory: true),
            root.appendingPathComponent("docling/source-documents", isDirectory: true)
        ] {
            try FileManager.default.ensureDirectory(directory)
        }
        try database.exportJSONL(table: "content_fingerprints", to: root.appendingPathComponent("index/fingerprint-index.jsonl"))
        try writeObjectIndex(to: root.appendingPathComponent("index/object-index.jsonl"))
        try writeProjectIndex(to: root.appendingPathComponent("index/project-index.md"))
        for table in ["projects", "memories", "decisions", "bugs", "prompts", "session_summaries"] {
            try database.exportJSONL(table: table, to: root.appendingPathComponent("data/\(table).jsonl"))
        }
        try writeProjectMarkdown(to: root.appendingPathComponent("markdown", isDirectory: true))
        try """
        # NALA-bRaiN Sync Import

        This package is a stable export from NALA-MCP-cORe \(NALAConstants.version).
        Use indexes first, then import data files. Do not overwrite existing NALA-bRaiN data without review.
        """.write(to: root.appendingPathComponent("import-instructions.md"), atomically: true, encoding: .utf8)
        let manifestURL = root.appendingPathComponent("manifest.json")
        try writeManifest(kind: "nala-brain-sync", root: root, to: manifestURL, project: nil)
        let checksumsURL = root.appendingPathComponent("checksums.sha256")
        try ChecksumManager.writeChecksums(for: root, to: checksumsURL)
        return DumpResult(rootURL: root, manifestURL: manifestURL, checksumsURL: checksumsURL)
    }

    private func createDumpStructure(_ root: URL) throws {
        for directory in [
            root,
            root.appendingPathComponent("sqlite", isDirectory: true),
            root.appendingPathComponent("jsonl", isDirectory: true),
            root.appendingPathComponent("markdown/projects", isDirectory: true),
            root.appendingPathComponent("index", isDirectory: true),
            root.appendingPathComponent("nala-brain", isDirectory: true),
            root.appendingPathComponent("logs", isDirectory: true)
        ] {
            try FileManager.default.ensureDirectory(directory)
        }
    }

    private func exportStandardJSONL(to jsonlURL: URL) throws {
        for table in ["projects", "memories", "decisions", "bugs", "prompts", "session_summaries", "artifacts"] {
            try database.exportJSONL(table: table, to: jsonlURL.appendingPathComponent("\(table).jsonl"))
        }
    }

    private func copyEvents(to url: URL) throws {
        if FileManager.default.fileExists(atPath: paths.eventsURL.path) {
            try FileManager.default.copyItem(at: paths.eventsURL, to: url)
        } else {
            try "".write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func writeProjectMarkdown(to markdownURL: URL) throws {
        try writeProjectIndex(to: markdownURL.appendingPathComponent("project-index.md"))
        let projectsRoot = markdownURL.appendingPathComponent("projects", isDirectory: true)
        try FileManager.default.ensureDirectory(projectsRoot)
        for project in try database.listProjects() {
            let safeName = project.name.replacingOccurrences(of: "/", with: "-")
            try """
            # \(project.name)

            \(project.content)

            Updated: \(project.updatedAt)
            """.write(to: projectsRoot.appendingPathComponent("\(safeName).md"), atomically: true, encoding: .utf8)
        }
    }

    private func writeProjectIndex(to url: URL) throws {
        let lines = try database.listProjects().map { "- \($0.name) (`\($0.stableID)`)" }.joined(separator: "\n")
        try "# Project Index\n\n\(lines)\n".write(to: url, atomically: true, encoding: .utf8)
    }

    private func writeObjectIndex(to url: URL) throws {
        var lines: [String] = []
        for table in DatabaseManager.tableNames {
            for row in try database.exportRows(table: table) {
                let record: [String: String] = [
                    "stable_id": row["stable_id"] ?? "",
                    "type": row["type"] ?? "",
                    "table": table,
                    "title": row["title"] ?? "",
                    "updated_at": row["updated_at"] ?? ""
                ]
                let data = try JSONSerialization.data(withJSONObject: record, options: [.sortedKeys])
                lines.append(String(data: data, encoding: .utf8) ?? "{}")
            }
        }
        try (lines.joined(separator: "\n") + (lines.isEmpty ? "" : "\n")).write(to: url, atomically: true, encoding: .utf8)
    }

    private func writeBrainSyncFiles(to url: URL) throws {
        try "# NALA-bRaiN Sync\n\nUse this dump as read-only input for future NALA-bRaiN ingestion.\n"
            .write(to: url.appendingPathComponent("nala-brain-sync.md"), atomically: true, encoding: .utf8)
        try database.exportJSONL(table: "content_fingerprints", to: url.appendingPathComponent("nala-brain-sync.jsonl"))
    }

    private func writeManifest(kind: String, root: URL, to url: URL, project: String?) throws {
        let manifest: [String: Any] = [
            "app": NALAConstants.appName,
            "version": NALAConstants.version,
            "kind": kind,
            "project": project ?? "all",
            "created_at": CoreClock.nowString(),
            "root": root.lastPathComponent
        ]
        let data = try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: url)
    }
}
