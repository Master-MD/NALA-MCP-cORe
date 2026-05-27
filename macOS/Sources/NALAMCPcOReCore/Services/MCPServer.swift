import Foundation

public final class MCPServer {
    private unowned let core: StableCore

    public init(core: StableCore) {
        self.core = core
    }

    public var toolNames: [String] {
        [
            "health_check",
            "list_projects",
            "search_context",
            "get_project_brief",
            "add_session_summary",
            "add_bug_report",
            "add_decision_candidate",
            "export_dump"
        ]
    }

    public func call(tool: String, client: String, arguments: [String: Any]) throws -> MCPToolResult {
        let action = actionForTool(tool)
        guard core.permissionManager.decision(client: client, action: action) == .allow else {
            return MCPToolResult(status: .denied, text: "Client \(client) is denied for \(tool).", payload: [:])
        }

        switch tool {
        case "health_check":
            let health = try core.healthCheck()
            let toolResult = MCPToolResult(status: .ok, text: "\(health.appName) \(health.version): \(health.databaseStatus)", payload: ["database": health.databaseStatus])
            core.resourceMonitor.recordRequest(result: toolResult.status)
            return toolResult
        case "list_projects":
            let projects = try core.listProjects()
            let toolResult = MCPToolResult(status: .ok, text: projects.map(\.name).joined(separator: "\n"), payload: ["count": "\(projects.count)"])
            core.resourceMonitor.recordRequest(result: toolResult.status)
            return toolResult
        case "search_context":
            let query = string(arguments["query"]) ?? ""
            let project = string(arguments["project"])
            let results = try core.searchContext(query: query, project: project)
            let text = results.map { "[\($0.objectType)] \($0.title): \($0.content)" }.joined(separator: "\n")
            let toolResult = MCPToolResult(status: .ok, text: text, payload: ["count": "\(results.count)", "source": "sqlite_fts5"])
            core.resourceMonitor.recordRequest(result: toolResult.status)
            return toolResult
        case "get_project_brief":
            let project = string(arguments["project"]) ?? ""
            let toolResult = MCPToolResult(status: .ok, text: try core.getProjectBrief(project: project), payload: ["project": project])
            core.resourceMonitor.recordRequest(result: toolResult.status)
            return toolResult
        case "add_session_summary":
            let object = try core.addSessionSummary(
                project: string(arguments["project"]) ?? "General",
                sourceClient: client,
                summary: string(arguments["summary"]) ?? "",
                changedFiles: stringArray(arguments["changed_files"]),
                openQuestions: stringArray(arguments["open_questions"])
            )
            let toolResult = MCPToolResult(status: .ok, text: "Session summary added: \(object.title)", payload: ["stable_id": object.stableID])
            core.resourceMonitor.recordRequest(result: toolResult.status)
            return toolResult
        case "add_bug_report":
            let object = try core.addBugReport(
                project: string(arguments["project"]) ?? "General",
                sourceClient: client,
                title: string(arguments["title"]) ?? "Untitled bug",
                severity: string(arguments["severity"]) ?? "medium",
                description: string(arguments["description"]) ?? "",
                reproductionSteps: stringArray(arguments["reproduction_steps"]),
                affectedFiles: stringArray(arguments["affected_files"])
            )
            let toolResult = MCPToolResult(status: .ok, text: "Bug report added: \(object.title)", payload: ["stable_id": object.stableID])
            core.resourceMonitor.recordRequest(result: toolResult.status)
            return toolResult
        case "add_decision_candidate":
            let object = try core.addDecisionCandidate(
                project: string(arguments["project"]) ?? "General",
                sourceClient: client,
                title: string(arguments["title"]) ?? "Untitled decision",
                rationale: string(arguments["rationale"]) ?? "",
                status: string(arguments["status"]) ?? "candidate"
            )
            let toolResult = MCPToolResult(status: .ok, text: "Decision candidate added: \(object.title)", payload: ["stable_id": object.stableID])
            core.resourceMonitor.recordRequest(result: toolResult.status)
            return toolResult
        case "export_dump":
            let dump = try core.exportDump(project: string(arguments["project"]))
            let toolResult = MCPToolResult(status: .ok, text: "Dump exported: \(dump.rootURL.path)", payload: ["path": dump.rootURL.path])
            core.resourceMonitor.recordRequest(result: toolResult.status)
            return toolResult
        default:
            let toolResult = MCPToolResult(status: .error, text: "Unknown tool: \(tool)", payload: [:])
            core.resourceMonitor.recordRequest(result: toolResult.status)
            return toolResult
        }
    }

    private func actionForTool(_ tool: String) -> PermissionAction {
        switch tool {
        case "search_context": .search
        case "add_session_summary": .addSessionSummary
        case "add_bug_report": .addBugReport
        case "add_decision_candidate": .addDecisionCandidate
        case "export_dump": .exportDump
        default: .read
        }
    }

    private func string(_ value: Any?) -> String? {
        value as? String
    }

    private func stringArray(_ value: Any?) -> [String] {
        if let array = value as? [String] {
            return array
        }
        if let string = value as? String, !string.isEmpty {
            return [string]
        }
        return []
    }
}
