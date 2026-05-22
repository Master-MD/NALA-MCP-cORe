import Foundation
import NALAMCPcOReCore

struct HelperArguments {
    let vault: URL
    let client: String
    let tool: String?
    let stdioJSONL: Bool
    let arguments: [String: Any]
}

func value(after flag: String, in args: [String]) -> String? {
    guard let index = args.firstIndex(of: flag), args.indices.contains(index + 1) else { return nil }
    return args[index + 1]
}

func parseArguments() -> HelperArguments {
    let args = CommandLine.arguments
    var payload: [String: Any] = [:]
    for key in ["query", "project", "summary", "title", "severity", "description", "rationale", "status"] {
        if let value = value(after: "--\(key)", in: args) {
            payload[key] = value
        }
    }
    return HelperArguments(
        vault: value(after: "--vault", in: args).map(URL.init(fileURLWithPath:)) ?? VaultPaths.default(),
        client: value(after: "--client", in: args) ?? "Codex",
        tool: value(after: "--tool", in: args),
        stdioJSONL: args.contains("--stdio-jsonl"),
        arguments: payload
    )
}

func printJSON(_ object: Any, prettyPrinted: Bool = true) {
    var options: JSONSerialization.WritingOptions = [.sortedKeys]
    if prettyPrinted {
        options.insert(.prettyPrinted)
    }
    if let data = try? JSONSerialization.data(withJSONObject: object, options: options),
       let text = String(data: data, encoding: .utf8) {
        print(text)
    } else {
        print("{\"status\":\"error\",\"text\":\"Could not encode JSON\"}")
    }
}

func dictionary(from result: MCPToolResult) -> [String: Any] {
    [
        "status": result.status.rawValue,
        "text": result.text,
        "payload": result.payload
    ]
}

do {
    let parsed = parseArguments()
    let core = try StableCore(vaultRoot: parsed.vault)
    try core.initialize()

    if parsed.stdioJSONL {
        let jsonRPCBridge = MCPJSONRPCBridge(core: core, defaultClient: parsed.client)
        while let line = readLine() {
            guard let data = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                printJSON([
                    "jsonrpc": "2.0",
                    "id": NSNull(),
                    "error": [
                        "code": -32700,
                        "message": "Parse error"
                    ]
                ], prettyPrinted: false)
                fflush(stdout)
                continue
            }
            if json["jsonrpc"] as? String == "2.0" {
                if let response = try jsonRPCBridge.handle(json: json) {
                    printJSON(response, prettyPrinted: false)
                    fflush(stdout)
                }
            } else {
                let tool = json["tool"] as? String ?? "health_check"
                let client = json["client"] as? String ?? parsed.client
                let arguments = json["arguments"] as? [String: Any] ?? [:]
                let result = try core.mcpServer.call(tool: tool, client: client, arguments: arguments)
                printJSON(dictionary(from: result), prettyPrinted: false)
                fflush(stdout)
            }
        }
    } else if let tool = parsed.tool {
        let result = try core.mcpServer.call(tool: tool, client: parsed.client, arguments: parsed.arguments)
        printJSON(dictionary(from: result))
    } else {
        printJSON([
            "app": NALAConstants.appName,
            "version": NALAConstants.version,
            "tools": core.mcpServer.toolNames,
            "usage": "nala-mcp-core-helper --tool health_check --client Codex"
        ])
    }
} catch {
    printJSON(["status": "error", "text": error.localizedDescription])
    exit(1)
}
