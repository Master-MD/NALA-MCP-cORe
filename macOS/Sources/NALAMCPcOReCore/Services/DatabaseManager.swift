import Foundation

public final class DatabaseManager {
    public static let tableNames = ObjectType.allCases.map(\.tableName)

    private let databaseURL: URL
    private let fingerprintManager: FingerprintManager
    private var connection: SQLiteConnection?

    public init(databaseURL: URL, fingerprintManager: FingerprintManager) {
        self.databaseURL = databaseURL
        self.fingerprintManager = fingerprintManager
    }

    public func open() throws {
        try FileManager.default.ensureDirectory(databaseURL.deletingLastPathComponent())
        connection = try SQLiteConnection(path: databaseURL.path)
    }

    public func initialize() throws {
        guard let connection else {
            throw StableCoreError.operationFailed("Database is not open")
        }

        _ = try connection.query("PRAGMA journal_mode=WAL;")
        try connection.execute("PRAGMA foreign_keys=ON;")
        try connection.execute("PRAGMA synchronous=NORMAL;")

        for table in Self.tableNames {
            try connection.execute(Self.createObjectTableSQL(table))
        }

        try connection.execute(
            """
            CREATE VIRTUAL TABLE IF NOT EXISTS search_index USING fts5(
                stable_id UNINDEXED,
                object_type UNINDEXED,
                project_id UNINDEXED,
                project_name,
                title,
                content,
                tags,
                source_client,
                source_path,
                created_at,
                updated_at
            );
            """
        )

        try seedKnownClients()
    }

    public func checkpoint() throws {
        _ = try requireConnection().query("PRAGMA wal_checkpoint(FULL);")
    }

    public func journalMode() throws -> String {
        try requireConnection().query("PRAGMA journal_mode;").first?.values.first ?? ""
    }

    public func ftsReady() throws -> Bool {
        let rows = try requireConnection().query(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'search_index';"
        )
        return !rows.isEmpty
    }

    public func addProject(name: String, content: String, sourceClient: String) throws -> CoreObject {
        if let existing = try findProject(named: name) {
            return try object(table: ObjectType.project.tableName, stableID: existing.stableID)
        }
        return try insertObject(
            type: .project,
            projectID: nil,
            title: name,
            content: content,
            metadata: ["tags": "project"],
            sourceClient: sourceClient,
            sourcePath: nil,
            sourceDocumentID: nil,
            status: "active"
        )
    }

    public func insertObject(
        type: ObjectType,
        projectID: String?,
        title: String,
        content: String,
        metadata: [String: String],
        sourceClient: String,
        sourcePath: String?,
        sourceDocumentID: String?,
        status: String
    ) throws -> CoreObject {
        let now = CoreClock.nowString()
        let fingerprint = try fingerprintManager.fingerprint(for: content)
        let metadataData = try JSONSerialization.data(withJSONObject: metadata, options: [.sortedKeys])
        let metadataJSON = String(data: metadataData, encoding: .utf8) ?? "{}"
        let object = CoreObject(
            stableID: "\(type.rawValue)-\(UUID().uuidString)",
            type: type,
            projectID: projectID,
            title: title,
            content: content,
            metadataJSON: metadataJSON,
            sourceClient: sourceClient,
            sourcePath: sourcePath,
            sourceDocumentID: sourceDocumentID,
            createdAt: now,
            updatedAt: now,
            importedAt: now,
            contentHash: fingerprint.contentHash,
            normalizedHash: fingerprint.normalizedHash,
            semanticFingerprint: fingerprint.semanticFingerprint,
            version: 1,
            parentID: nil,
            status: status
        )

        try insert(object)
        return object
    }

    public func insert(_ object: CoreObject) throws {
        let connection = try requireConnection()
        try connection.execute(
            """
            INSERT OR REPLACE INTO \(object.type.tableName)
            (stable_id, type, project_id, title, content, metadata_json, source_client, source_path,
             source_document_id, created_at, updated_at, imported_at, content_hash, normalized_hash,
             semantic_fingerprint, version, parent_id, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """,
            parameters: object.sqliteValues
        )

        if object.type != .contentFingerprint {
            try upsertFingerprint(for: object)
        }

        if isSearchable(object.type) {
            try index(object)
        }
    }

    public func findProject(named name: String) throws -> ProjectSummary? {
        let rows = try requireConnection().query(
            """
            SELECT stable_id, title, content, updated_at FROM projects
            WHERE lower(title) = lower(?)
            LIMIT 1;
            """,
            parameters: [.text(name)]
        )
        guard let row = rows.first else { return nil }
        return ProjectSummary(
            stableID: row["stable_id"] ?? "",
            name: row["title"] ?? "",
            content: row["content"] ?? "",
            updatedAt: row["updated_at"] ?? ""
        )
    }

    public func listProjects() throws -> [ProjectSummary] {
        try requireConnection().query(
            "SELECT stable_id, title, content, updated_at FROM projects ORDER BY lower(title);"
        ).map { row in
            ProjectSummary(
                stableID: row["stable_id"] ?? "",
                name: row["title"] ?? "",
                content: row["content"] ?? "",
                updatedAt: row["updated_at"] ?? ""
            )
        }
    }

    public func search(query: String, project: String?) throws -> [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let ftsQuery = trimmed.sqliteEscapedFTSQuery()

        let rows: [SQLiteRow]
        if let project, !project.isEmpty {
            rows = try requireConnection().query(
                """
                SELECT stable_id, object_type, project_name, title, content, source_client, updated_at
                FROM search_index
                WHERE search_index MATCH ? AND lower(project_name) = lower(?)
                ORDER BY rank
                LIMIT 50;
                """,
                parameters: [.text(ftsQuery), .text(project)]
            )
        } else {
            rows = try requireConnection().query(
                """
                SELECT stable_id, object_type, project_name, title, content, source_client, updated_at
                FROM search_index
                WHERE search_index MATCH ?
                ORDER BY rank
                LIMIT 50;
                """,
                parameters: [.text(ftsQuery)]
            )
        }

        return rows.map { row in
            SearchResult(
                stableID: row["stable_id"] ?? "",
                objectType: row["object_type"] ?? "",
                projectName: row["project_name"] ?? "",
                title: row["title"] ?? "",
                content: row["content"] ?? "",
                sourceClient: row["source_client"] ?? "",
                updatedAt: row["updated_at"] ?? "",
                source: "sqlite_fts5"
            )
        }
    }

    public func object(table: String, stableID: String) throws -> CoreObject {
        let rows = try requireConnection().query(
            "SELECT * FROM \(table) WHERE stable_id = ? LIMIT 1;",
            parameters: [.text(stableID)]
        )
        guard let row = rows.first else {
            throw StableCoreError.operationFailed("Missing object \(stableID) in \(table)")
        }
        return try object(from: row)
    }

    public func hasContentHash(_ hash: String) throws -> Bool {
        let rows = try requireConnection().query(
            "SELECT stable_id FROM content_fingerprints WHERE content_hash = ? LIMIT 1;",
            parameters: [.text(hash)]
        )
        return !rows.isEmpty
    }

    public func hasNormalizedHash(_ hash: String) throws -> Bool {
        let rows = try requireConnection().query(
            "SELECT stable_id FROM content_fingerprints WHERE normalized_hash = ? LIMIT 1;",
            parameters: [.text(hash)]
        )
        return !rows.isEmpty
    }

    public func count(table: String) throws -> Int {
        let value = try requireConnection().query("SELECT COUNT(*) AS count FROM \(table);").first?["count"] ?? "0"
        return Int(value) ?? 0
    }

    public func exportRows(table: String) throws -> [[String: String]] {
        try requireConnection().query("SELECT * FROM \(table) ORDER BY created_at, stable_id;")
    }

    public func exportJSONL(table: String, to url: URL) throws {
        try FileManager.default.ensureDirectory(url.deletingLastPathComponent())
        let rows = try exportRows(table: table)
        let lines = try rows.map { row -> String in
            let data = try JSONSerialization.data(withJSONObject: row, options: [.sortedKeys])
            return String(data: data, encoding: .utf8) ?? "{}"
        }.joined(separator: "\n")
        try (lines + (lines.isEmpty ? "" : "\n")).write(to: url, atomically: true, encoding: .utf8)
    }

    public func projectBrief(project: String) throws -> String {
        guard let summary = try findProject(named: project) else {
            return "Project not found: \(project)"
        }
        let results = try search(query: project, project: project).prefix(10)
        let lines = results.map { "- [\($0.objectType)] \($0.title): \($0.content)" }
        return """
        # \(summary.name)

        \(summary.content)

        Recent indexed context:
        \(lines.joined(separator: "\n"))
        """
    }

    public func writeIndexStatus(to url: URL) throws {
        let payload: [String: Any] = [
            "status": try ftsReady() ? "ready" : "missing",
            "updated_at": CoreClock.nowString(),
            "source": "SQLite FTS5"
        ]
        let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: url)
    }

    private func seedKnownClients() throws {
        for client in NALAConstants.defaultKnownClients {
            if try requireConnection().query(
                "SELECT stable_id FROM clients WHERE title = ? LIMIT 1;",
                parameters: [.text(client)]
            ).isEmpty {
                _ = try insertObject(
                    type: .client,
                    projectID: nil,
                    title: client,
                    content: "Known MCP client: \(client)",
                    metadata: ["policy": "known"],
                    sourceClient: "System",
                    sourcePath: nil,
                    sourceDocumentID: nil,
                    status: "allow"
                )
            }
        }
    }

    private func index(_ object: CoreObject) throws {
        let projectName: String
        if object.type == .project {
            projectName = object.title
        } else if let projectID = object.projectID,
                  let project = try? self.object(table: ObjectType.project.tableName, stableID: projectID) {
            projectName = project.title
        } else {
            projectName = ""
        }

        try requireConnection().execute(
            """
            INSERT INTO search_index
            (stable_id, object_type, project_id, project_name, title, content, tags, source_client, source_path, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """,
            parameters: [
                .text(object.stableID),
                .text(object.type.rawValue),
                object.projectID.map(SQLiteValue.text) ?? .null,
                .text(projectName),
                .text(object.title),
                .text(object.content),
                .text(object.metadataJSON),
                .text(object.sourceClient),
                object.sourcePath.map(SQLiteValue.text) ?? .null,
                .text(object.createdAt),
                .text(object.updatedAt)
            ]
        )
    }

    private func upsertFingerprint(for object: CoreObject) throws {
        try requireConnection().execute(
            """
            INSERT OR REPLACE INTO content_fingerprints
            (stable_id, type, project_id, title, content, metadata_json, source_client, source_path,
             source_document_id, created_at, updated_at, imported_at, content_hash, normalized_hash,
             semantic_fingerprint, version, parent_id, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """,
            parameters: [
                .text(object.stableID),
                .text(ObjectType.contentFingerprint.rawValue),
                object.projectID.map(SQLiteValue.text) ?? .null,
                .text(object.title),
                .text(object.contentHash),
                .text(object.metadataJSON),
                .text(object.sourceClient),
                object.sourcePath.map(SQLiteValue.text) ?? .null,
                object.sourceDocumentID.map(SQLiteValue.text) ?? .null,
                .text(object.createdAt),
                .text(object.updatedAt),
                object.importedAt.map(SQLiteValue.text) ?? .null,
                .text(object.contentHash),
                .text(object.normalizedHash),
                .text(object.semanticFingerprint),
                .int(object.version),
                object.parentID.map(SQLiteValue.text) ?? .null,
                .text(object.status)
            ]
        )
    }

    private func object(from row: SQLiteRow) throws -> CoreObject {
        guard let typeValue = row["type"], let type = ObjectType(rawValue: typeValue) else {
            throw StableCoreError.operationFailed("Unknown object type \(row["type"] ?? "")")
        }
        return CoreObject(
            stableID: row["stable_id"] ?? "",
            type: type,
            projectID: row["project_id"]?.nilIfBlank,
            title: row["title"] ?? "",
            content: row["content"] ?? "",
            metadataJSON: row["metadata_json"] ?? "{}",
            sourceClient: row["source_client"] ?? "",
            sourcePath: row["source_path"]?.nilIfBlank,
            sourceDocumentID: row["source_document_id"]?.nilIfBlank,
            createdAt: row["created_at"] ?? "",
            updatedAt: row["updated_at"] ?? "",
            importedAt: row["imported_at"]?.nilIfBlank,
            contentHash: row["content_hash"] ?? "",
            normalizedHash: row["normalized_hash"] ?? "",
            semanticFingerprint: row["semantic_fingerprint"] ?? "",
            version: Int(row["version"] ?? "1") ?? 1,
            parentID: row["parent_id"]?.nilIfBlank,
            status: row["status"] ?? "active"
        )
    }

    private func isSearchable(_ type: ObjectType) -> Bool {
        switch type {
        case .project, .memory, .decision, .decisionCandidate, .bug, .prompt, .sessionSummary, .artifact, .sourceDocument:
            return true
        default:
            return false
        }
    }

    private func requireConnection() throws -> SQLiteConnection {
        guard let connection else {
            throw StableCoreError.operationFailed("Database is not open")
        }
        return connection
    }

    private static func createObjectTableSQL(_ table: String) -> String {
        """
        CREATE TABLE IF NOT EXISTS \(table) (
            stable_id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            project_id TEXT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            metadata_json TEXT NOT NULL DEFAULT '{}',
            source_client TEXT NOT NULL,
            source_path TEXT,
            source_document_id TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            imported_at TEXT,
            content_hash TEXT NOT NULL,
            normalized_hash TEXT NOT NULL,
            semantic_fingerprint TEXT NOT NULL,
            version INTEGER NOT NULL DEFAULT 1,
            parent_id TEXT,
            status TEXT NOT NULL
        );
        """
    }
}

private extension CoreObject {
    var sqliteValues: [SQLiteValue] {
        [
            .text(stableID),
            .text(type.rawValue),
            projectID.map(SQLiteValue.text) ?? .null,
            .text(title),
            .text(content),
            .text(metadataJSON),
            .text(sourceClient),
            sourcePath.map(SQLiteValue.text) ?? .null,
            sourceDocumentID.map(SQLiteValue.text) ?? .null,
            .text(createdAt),
            .text(updatedAt),
            importedAt.map(SQLiteValue.text) ?? .null,
            .text(contentHash),
            .text(normalizedHash),
            .text(semanticFingerprint),
            .int(version),
            parentID.map(SQLiteValue.text) ?? .null,
            .text(status)
        ]
    }
}
