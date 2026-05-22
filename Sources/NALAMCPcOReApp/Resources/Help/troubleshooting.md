# Troubleshooting

## Helper path missing

Open MCP Clients and click Install Symlink.

## STDIO appears to hang

STDIO waits for an MCP client. That can be normal.

## Antigravity permissions vs config

Permissions allow or deny tools. The server still belongs in `mcp_config.json`.

## Vault path with spaces

Use the copy buttons. They quote paths correctly for config formats.

## v0.2 upgrade

NALA can inspect v0.1 data while the old helper is running. Final migration should wait until active MCP clients are stopped.
