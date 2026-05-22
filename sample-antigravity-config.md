# Sample Google Antigravity Config

Build the helper:

```bash
swift build --product nala-mcp-core-helper
```

Example:

```json
{
  "mcpServers": {
    "nala_mcp_core": {
      "command": "/absolute/path/to/NALA-MCP-cORe/.build/debug/nala-mcp-core-helper",
      "args": ["--stdio-jsonl", "--client", "Google Antigravity"]
    }
  }
}
```

On macOS, Antigravity reads:

```text
~/.gemini/antigravity/mcp_config.json
```

This helper accepts standard MCP JSON-RPC over stdio.
