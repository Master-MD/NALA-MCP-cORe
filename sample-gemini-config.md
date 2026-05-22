# Sample Gemini CLI Config

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
      "args": ["--stdio-jsonl", "--client", "Gemini CLI"]
    }
  }
}
```

For Gemini CLI, add it globally with:

```bash
gemini mcp add -s user -e NALA_MCP_CORE_CLIENT="Gemini CLI" -e NALA_MCP_CORE_VAULT="$HOME/Library/Application Support/NALA-MCP-cORe" nala_mcp_core /absolute/path/to/NALA-MCP-cORe/.build/debug/nala-mcp-core-helper --stdio-jsonl --client "Gemini CLI"
```
