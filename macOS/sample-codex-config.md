# Sample Codex MCP Config

Build the helper first:

```bash
swift build --product nala-mcp-core-helper
```

Example command:

```json
{
  "mcpServers": {
    "nala_mcp_core": {
      "command": "/absolute/path/to/NALA-MCP-cORe/.build/debug/nala-mcp-core-helper",
      "args": ["--stdio-jsonl", "--client", "Codex"]
    }
  }
}
```

Replace `/absolute/path/to/NALA-MCP-cORe` with this repository path.

The helper accepts standard MCP JSON-RPC over stdio and keeps the older project
JSON-lines tool format for manual local smoke tests.
