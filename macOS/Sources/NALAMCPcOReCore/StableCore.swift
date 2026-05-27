import Foundation

public final class StableCore {
    public let paths: VaultPaths
    public let vaultManager: VaultManager
    public let fingerprintManager: FingerprintManager
    public let permissionManager: PermissionManager
    public let database: DatabaseManager
    public let eventJournal: EventJournal
    public let logManager: LogManager
    public let auditLogger: AuditLogger
    public let serverManager: ServerManager
    public let clientConnectionManager: ClientConnectionManager
    public let clientConfigGenerator: ClientConfigGenerator
    public let helperSymlinkManager: HelperSymlinkManager
    public let resourceMonitor: ResourceMonitor
    public let flowMatrixBuilder: FlowMatrixBuilder
    public let upgradePreflightManager: UpgradePreflightManager
    public lazy var mcpServer: MCPServer = MCPServer(core: self)

    private let backupManager: BackupManager
    private let restoreManager: RestoreManager
    private let dumpManager: DumpManager
    private let labSandboxManager: LabSandboxManager

    public init(vaultRoot: URL) throws {
        self.vaultManager = VaultManager(rootURL: vaultRoot)
        self.paths = vaultManager.paths
        self.fingerprintManager = FingerprintManager()
        self.permissionManager = PermissionManager()
        self.database = DatabaseManager(databaseURL: paths.databaseURL, fingerprintManager: fingerprintManager)
        self.eventJournal = EventJournal(eventsURL: paths.eventsURL)
        self.logManager = LogManager(paths: paths)
        self.auditLogger = AuditLogger(logManager: logManager)
        self.serverManager = ServerManager(logManager: logManager)
        self.helperSymlinkManager = HelperSymlinkManager()
        self.clientConnectionManager = ClientConnectionManager(permissionManager: permissionManager)
        self.clientConfigGenerator = ClientConfigGenerator(vaultURL: paths.rootURL, stableHelperURL: helperSymlinkManager.stableHelperURL)
        self.resourceMonitor = ResourceMonitor()
        self.flowMatrixBuilder = FlowMatrixBuilder()
        self.upgradePreflightManager = UpgradePreflightManager()
        self.backupManager = BackupManager(paths: paths, database: database)
        self.restoreManager = RestoreManager()
        self.dumpManager = DumpManager(paths: paths, database: database)
        self.labSandboxManager = LabSandboxManager(paths: paths, database: database)
    }

    public func initialize() throws {
        try vaultManager.initializeDirectories()
        try database.open()
        try database.initialize()
        try database.writeIndexStatus(to: paths.ftsStatusURL)
        try logManager.appendApp("initialized \(NALAConstants.appName) \(NALAConstants.version) vault=\(paths.rootURL.path)")
    }

    public func healthCheck() throws -> HealthStatus {
        HealthStatus(
            appName: NALAConstants.appName,
            version: NALAConstants.version,
            databaseStatus: FileManager.default.fileExists(atPath: paths.databaseURL.path) ? "ready" : "missing",
            journalMode: try database.journalMode(),
            ftsReady: try database.ftsReady(),
            externalAccess: "blocked",
            currentUser: NSUserName(),
            vaultPath: paths.rootURL.path,
            lastBackup: latestDirectoryName(in: paths.vaultBackupsURL.appendingPathComponent("NALA-MCP-cORe-Backups/full", isDirectory: true)),
            lastDump: latestDirectoryName(in: paths.exportsURL),
            lastLabRun: latestDirectoryName(in: paths.sandboxesURL),
            knownClients: Array(permissionManager.knownClients).sorted()
        )
    }

    public func addProject(name: String, content: String, sourceClient: String) throws -> CoreObject {
        let object = try database.addProject(name: name, content: content, sourceClient: sourceClient)
        try recordWrite(eventType: "object.created", object: object, message: "project saved")
        return object
    }

    public func addMemory(project: String, title: String, content: String, sourceClient: String) throws -> CoreObject {
        try check(client: sourceClient, action: .addSessionSummary)
        let projectObject = try ensureProject(project, sourceClient: sourceClient)
        let object = try database.insertObject(
            type: .memory,
            projectID: projectObject.stableID,
            title: title,
            content: content,
            metadata: ["tags": "memory"],
            sourceClient: sourceClient,
            sourcePath: nil,
            sourceDocumentID: nil,
            status: "active"
        )
        try recordWrite(eventType: "object.created", object: object, message: "memory saved")
        return object
    }

    public func addSessionSummary(project: String, sourceClient: String, summary: String, changedFiles: [String], openQuestions: [String]) throws -> CoreObject {
        try check(client: sourceClient, action: .addSessionSummary)
        let projectObject = try ensureProject(project, sourceClient: sourceClient)
        let metadata = [
            "changed_files": changedFiles.joined(separator: ","),
            "open_questions": openQuestions.joined(separator: "\n")
        ]
        let object = try database.insertObject(
            type: .sessionSummary,
            projectID: projectObject.stableID,
            title: "Session Summary \(CoreClock.nowString())",
            content: summary,
            metadata: metadata,
            sourceClient: sourceClient,
            sourcePath: nil,
            sourceDocumentID: nil,
            status: "active"
        )
        try recordWrite(eventType: "object.created", object: object, message: "session summary saved")
        return object
    }

    public func addBugReport(
        project: String,
        sourceClient: String,
        title: String,
        severity: String,
        description: String,
        reproductionSteps: [String],
        affectedFiles: [String]
    ) throws -> CoreObject {
        try check(client: sourceClient, action: .addBugReport)
        let projectObject = try ensureProject(project, sourceClient: sourceClient)
        let metadata = [
            "severity": severity,
            "reproduction_steps": reproductionSteps.joined(separator: "\n"),
            "affected_files": affectedFiles.joined(separator: ",")
        ]
        let object = try database.insertObject(
            type: .bug,
            projectID: projectObject.stableID,
            title: title,
            content: description,
            metadata: metadata,
            sourceClient: sourceClient,
            sourcePath: nil,
            sourceDocumentID: nil,
            status: "active"
        )
        try recordWrite(eventType: "object.created", object: object, message: "bug report saved")
        return object
    }

    public func addDecision(project: String, sourceClient: String, title: String, content: String) throws -> CoreObject {
        try check(client: sourceClient, action: .addDecisionCandidate)
        let projectObject = try ensureProject(project, sourceClient: sourceClient)
        let object = try database.insertObject(
            type: .decision,
            projectID: projectObject.stableID,
            title: title,
            content: content,
            metadata: ["status": "accepted"],
            sourceClient: sourceClient,
            sourcePath: nil,
            sourceDocumentID: nil,
            status: "accepted"
        )
        try recordWrite(eventType: "object.created", object: object, message: "decision saved")
        return object
    }

    public func addDecisionCandidate(project: String, sourceClient: String, title: String, rationale: String, status: String = "candidate") throws -> CoreObject {
        try check(client: sourceClient, action: .addDecisionCandidate)
        let projectObject = try ensureProject(project, sourceClient: sourceClient)
        let object = try database.insertObject(
            type: .decisionCandidate,
            projectID: projectObject.stableID,
            title: title,
            content: rationale,
            metadata: ["status": status],
            sourceClient: sourceClient,
            sourcePath: nil,
            sourceDocumentID: nil,
            status: status
        )
        try recordWrite(eventType: "object.created", object: object, message: "decision candidate saved")
        return object
    }

    public func listProjects() throws -> [ProjectSummary] {
        try database.listProjects()
    }

    public func searchContext(query: String, project: String? = nil) throws -> [SearchResult] {
        try database.search(query: query, project: project)
    }

    public func getProjectBrief(project: String) throws -> String {
        try database.projectBrief(project: project)
    }

    public func classifyDuplicate(content: String) throws -> DuplicateClassification {
        let fingerprint = try fingerprintManager.fingerprint(for: content)
        if try database.hasContentHash(fingerprint.contentHash) {
            return .alreadyExists
        }
        if try database.hasNormalizedHash(fingerprint.normalizedHash) {
            return .duplicateFormatVariant
        }
        return .newObject
    }

    public func backupNow(targetFolder: URL? = nil) throws -> BackupResult {
        let result = try backupManager.backupNow(targetFolder: targetFolder)
        let object = try database.insertObject(
            type: .backupRun,
            projectID: nil,
            title: result.fullBackupURL.lastPathComponent,
            content: result.fullBackupURL.path,
            metadata: ["zip": result.zipURL.path],
            sourceClient: "System",
            sourcePath: result.fullBackupURL.path,
            sourceDocumentID: nil,
            status: "completed"
        )
        try recordWrite(eventType: "backup.created", object: object, message: "backup created")
        return result
    }

    public func restoreDryRun(from backupURL: URL) throws -> RestoreDryRun {
        let result = try restoreManager.dryRun(from: backupURL)
        let object = try database.insertObject(
            type: .restoreRun,
            projectID: nil,
            title: "Restore dry-run \(CoreClock.nowString())",
            content: result.previewText,
            metadata: ["backup": backupURL.path, "status": result.status.rawValue],
            sourceClient: "System",
            sourcePath: backupURL.path,
            sourceDocumentID: nil,
            status: result.status.rawValue
        )
        try recordWrite(eventType: "restore.dry_run", object: object, message: "restore dry-run completed")
        return result
    }

    public func exportDump(project: String? = nil) throws -> DumpResult {
        try check(client: "Manual", action: .exportDump)
        let result = try dumpManager.exportFullDump(project: project)
        let object = try database.insertObject(
            type: .dumpRun,
            projectID: nil,
            title: result.rootURL.lastPathComponent,
            content: result.rootURL.path,
            metadata: ["kind": "nala-full"],
            sourceClient: "System",
            sourcePath: result.rootURL.path,
            sourceDocumentID: nil,
            status: "completed"
        )
        try recordWrite(eventType: "dump.created", object: object, message: "dump exported")
        return result
    }

    public func exportBrainSyncPackage() throws -> DumpResult {
        let result = try dumpManager.exportBrainSyncPackage()
        let object = try database.insertObject(
            type: .exportRun,
            projectID: nil,
            title: result.rootURL.lastPathComponent,
            content: result.rootURL.path,
            metadata: ["kind": "nala-brain-sync"],
            sourceClient: "System",
            sourcePath: result.rootURL.path,
            sourceDocumentID: nil,
            status: "completed"
        )
        try recordWrite(eventType: "export.created", object: object, message: "NALA-bRaiN sync exported")
        return result
    }

    @discardableResult
    public func runLabSandbox(featureName: String, operation: (LabSandbox) throws -> Void) throws -> LabSandbox {
        let sandbox = try labSandboxManager.createSandbox(featureName: featureName)
        do {
            try operation(sandbox)
            try labSandboxManager.finalize(sandbox, featureName: featureName, status: "completed", message: "Lab completed against sandbox copy.")
            let object = try database.insertObject(
                type: .labRun,
                projectID: nil,
                title: featureName,
                content: sandbox.rootURL.path,
                metadata: ["state": "completed"],
                sourceClient: "System",
                sourcePath: sandbox.rootURL.path,
                sourceDocumentID: nil,
                status: "completed"
            )
            try recordWrite(eventType: "lab.completed", object: object, message: "lab completed")
            return sandbox
        } catch {
            try? labSandboxManager.finalize(sandbox, featureName: featureName, status: "failed", message: error.localizedDescription)
            throw error
        }
    }

    private func ensureProject(_ name: String, sourceClient: String) throws -> CoreObject {
        try database.addProject(name: name, content: "Project vault for \(name)", sourceClient: sourceClient)
    }

    private func check(client: String, action: PermissionAction) throws {
        guard permissionManager.decision(client: client, action: action) == .allow else {
            throw StableCoreError.permissionDenied("\(client) cannot perform \(action.rawValue)")
        }
    }

    private func recordWrite(eventType: String, object: CoreObject, message: String) throws {
        let event = JournalEvent(
            id: UUID().uuidString,
            type: eventType,
            objectID: object.stableID,
            objectType: object.type.rawValue,
            sourceClient: object.sourceClient,
            title: object.title,
            timestamp: CoreClock.nowString(),
            metadata: ["status": object.status]
        )
        try eventJournal.append(event)
        try auditLogger.record(eventType, objectID: object.stableID, sourceClient: object.sourceClient, message: message)
        try database.writeIndexStatus(to: paths.ftsStatusURL)
    }

    private func latestDirectoryName(in directory: URL) -> String? {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ), !contents.isEmpty else {
            return nil
        }
        return contents.max { left, right in
            let leftDate = (try? left.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let rightDate = (try? right.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return leftDate < rightDate
        }?.lastPathComponent
    }
}
