import Foundation

public final class MCPJSONRPCBridge {
    private let core: StableCore
    private let defaultClient: String

    public init(core: StableCore, defaultClient: String) {
        self.core = core
        self.defaultClient = defaultClient
    }

    public func handle(json: [String: Any]) throws -> [String: Any]? {
        guard json["jsonrpc"] as? String == "2.0" else {
            return errorResponse(id: json["id"], code: -32600, message: "Invalid JSON-RPC request.")
        }

        let id = json["id"]
        guard let method = json["method"] as? String else {
            return errorResponse(id: id, code: -32600, message: "Missing JSON-RPC method.")
        }

        switch method {
        case "initialize":
            return response(id: id, result: initializeResult(for: json))
        case "notifications/initialized":
            return nil
        case "ping":
            return response(id: id, result: [:])
        case "tools/list":
            return response(id: id, result: ["tools": toolDescriptors()])
        case "tools/call":
            guard let params = json["params"] as? [String: Any],
                  let name = params["name"] as? String else {
                return errorResponse(id: id, code: -32602, message: "tools/call requires params.name.")
            }
            let arguments = params["arguments"] as? [String: Any] ?? [:]
            let result = try core.mcpServer.call(tool: name, client: defaultClient, arguments: arguments)
            return response(id: id, result: toolCallResult(from: result))
        default:
            return errorResponse(id: id, code: -32601, message: "Method not found: \(method)")
        }
    }

    private func initializeResult(for json: [String: Any]) -> [String: Any] {
        let params = json["params"] as? [String: Any]
        let requestedProtocolVersion = params?["protocolVersion"] as? String
        return [
            "protocolVersion": requestedProtocolVersion ?? "2025-11-25",
            "capabilities": [
                "tools": [
                    "listChanged": false
                ]
            ],
            "serverInfo": [
                "name": NALAConstants.appName,
                "version": NALAConstants.version
            ],
            "instructions": "Local-only NALA project memory tools. Unknown clients and destructive actions are denied by policy."
        ]
    }

    private func toolCallResult(from result: MCPToolResult) -> [String: Any] {
        [
            "content": [
                [
                    "type": "text",
                    "text": result.text
                ]
            ],
            "structuredContent": [
                "status": result.status.rawValue,
                "text": result.text,
                "payload": result.payload
            ],
            "isError": result.status != .ok
        ]
    }

    private func response(id: Any?, result: [String: Any]) -> [String: Any] {
        [
            "jsonrpc": "2.0",
            "id": normalizedID(id),
            "result": result
        ]
    }

    private func errorResponse(id: Any?, code: Int, message: String) -> [String: Any] {
        [
            "jsonrpc": "2.0",
            "id": normalizedID(id),
            "error": [
                "code": code,
                "message": message
            ]
        ]
    }

    private func normalizedID(_ id: Any?) -> Any {
        id ?? NSNull()
    }

    private func toolDescriptors() -> [[String: Any]] {
        [
            tool(
                name: "health_check",
                description: "Check local NALA vault, SQLite, FTS, backup, dump, lab, and client status.",
                properties: [:],
                required: []
            ),
            tool(
                name: "list_projects",
                description: "List projects currently indexed in the local NALA vault.",
                properties: [:],
                required: []
            ),
            tool(
                name: "search_context",
                description: "Search indexed local project memories, decisions, bugs, and summaries using SQLite FTS5.",
                properties: [
                    "query": stringSchema("Search query."),
                    "project": stringSchema("Optional project name filter.")
                ],
                required: ["query"]
            ),
            tool(
                name: "get_project_brief",
                description: "Return a concise project brief plus recent indexed context.",
                properties: [
                    "project": stringSchema("Project name.")
                ],
                required: ["project"]
            ),
            tool(
                name: "add_session_summary",
                description: "Append a session summary to the local NALA vault.",
                properties: [
                    "project": stringSchema("Project name."),
                    "summary": stringSchema("Session summary content."),
                    "changed_files": stringArraySchema("Optional changed file paths."),
                    "open_questions": stringArraySchema("Optional open questions.")
                ],
                required: ["project", "summary"]
            ),
            tool(
                name: "add_bug_report",
                description: "Append a bug report to the local NALA vault.",
                properties: [
                    "project": stringSchema("Project name."),
                    "title": stringSchema("Bug title."),
                    "severity": stringSchema("Severity label."),
                    "description": stringSchema("Bug description."),
                    "reproduction_steps": stringArraySchema("Optional reproduction steps."),
                    "affected_files": stringArraySchema("Optional affected file paths.")
                ],
                required: ["project", "title", "description"]
            ),
            tool(
                name: "add_decision_candidate",
                description: "Append a decision candidate to the local NALA vault.",
                properties: [
                    "project": stringSchema("Project name."),
                    "title": stringSchema("Decision title."),
                    "rationale": stringSchema("Decision rationale."),
                    "status": stringSchema("Optional decision status.")
                ],
                required: ["project", "title", "rationale"]
            ),
            tool(
                name: "export_dump",
                description: "Export a local NALA dump. This is read/export oriented and subject to permissions.",
                properties: [
                    "project": stringSchema("Optional project name filter.")
                ],
                required: []
            )
        ]
    }

    private func tool(name: String, description: String, properties: [String: Any], required: [String]) -> [String: Any] {
        [
            "name": name,
            "description": description,
            "inputSchema": [
                "type": "object",
                "properties": properties,
                "required": required
            ]
        ]
    }

    private func stringSchema(_ description: String) -> [String: Any] {
        [
            "type": "string",
            "description": description
        ]
    }

    private func stringArraySchema(_ description: String) -> [String: Any] {
        [
            "type": "array",
            "description": description,
            "items": [
                "type": "string"
            ]
        ]
    }
}
