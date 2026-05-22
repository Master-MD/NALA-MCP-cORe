# MCP Clients

Known clients:

- Codex
- Gemini CLI
- Google Antigravity
- Manual
- NALA-bRaiN future

Unknown clients are denied.

## Connection Wizard

Open `MCP Clients` in the app.

For each client it shows state badge, helper path, vault path, working directory, config location, copy buttons, symlink install, reveal helper, and health check test.

Active state is never guessed. It needs recent tool-call evidence.

## Helper Build

```bash
swift build --product nala-mcp-core-helper
```

## Examples

```bash
.build/debug/nala-mcp-core-helper --tool health_check --client Codex
.build/debug/nala-mcp-core-helper --tool list_projects --client Codex
.build/debug/nala-mcp-core-helper --tool search_context --client Codex --query "NALA"
.build/debug/nala-mcp-core-helper --tool add_bug_report --client Codex --project NALA --title "Local-only bind" --severity medium --description "Reject 0.0.0.0"
```

## JSON-Lines Stdio

```bash
.build/debug/nala-mcp-core-helper --stdio-jsonl --client Codex
```

Input:

```json
{"tool":"search_context","arguments":{"query":"backup","project":"NALA"}}
```

## Antigravity Note

The Antigravity MCP Tools permission screen only allows or denies tools. It does not register the server.

The server config belongs in:

```text
~/.gemini/antigravity/mcp_config.json
```
