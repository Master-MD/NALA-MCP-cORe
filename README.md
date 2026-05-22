# NALA-MCP-cORe

Native macOS SwiftUI control center for a local-only MCP memory/database core.

Version: `0.1.0`
Bundle identifier: `ch.nala.mcp-core`

## What It Does

NALA-MCP-cORe stores project memory in a local SQLite vault, indexes it with SQLite FTS5, writes append-only JSONL events, and exposes a small local MCP helper surface for tools such as Codex, Gemini CLI, Google Antigravity, and future NALA-bRaiN workflows.

Stable Core v0.1 includes:

- First-launch vault picker
- SQLite database with WAL mode
- FTS5 indexed search
- Fingerprint index
- JSONL event journal
- Manual project, memory, decision, bug, and session summary entry
- Local MCP helper tool dispatch
- Backup Now with manifest, checksums, ZIP, and delta JSONL
- Restore dry-run with checksum verification
- NALA Full Dump export
- NALA-bRaiN Sync package export
- Permission policy where unknown clients and destructive tools are denied
- Logs, health, settings, and visible planned Labs

UI/Stats/Flow patch additions:

- MCP Clients connection wizard with copy-ready Codex, Gemini CLI, Antigravity, and Manual STDIO config
- Real client state badges without fake active state
- Responsive Status dashboard cards
- Deep Stats with in-memory CPU/RAM/request samples
- Optional menu bar status item
- Flow Monitor policy matrix
- Local bundled Help window
- Side-by-side preview build so the current v0.1 app bundle is not replaced

## Build And Run

```bash
swift test
./script/build_and_run.sh --verify
```

The app bundle is staged at:

```text
dist/NALA-MCP-cORe-UIStatsPreview.app
```

The supplied NALA app icon is embedded into the generated `.app` bundle.

To intentionally package the original stable bundle name:

```bash
./script/build_and_run.sh --stable
```

## Vault Location

Recommended default:

```text
~/Library/Application Support/NALA-MCP-cORe/
```

The first-launch picker also supports a custom local folder, including folders synced by iCloud Drive, Google Drive Desktop, Dropbox, Synology Drive, NAS mounts, or external SSDs. No cloud API or OAuth is used in v0.1.

## Safety Defaults

- Local-only
- No root requirement
- No system-wide LaunchDaemon
- No telemetry
- Unknown clients denied
- Destructive actions denied
- Labs run on snapshots or stay disabled
- HTTP binding validation rejects `0.0.0.0` and LAN IPs

## Helper

After build:

```bash
.build/debug/nala-mcp-core-helper --tool health_check --client Codex
.build/debug/nala-mcp-core-helper --tool search_context --client Codex --query "loopback"
```

JSON-lines stdio mode:

```bash
.build/debug/nala-mcp-core-helper --stdio-jsonl --client Codex
```

Send:

```json
{"tool":"health_check","arguments":{}}
```

## v0.1 to v0.2 Upgrade Strategy

v0.2 should first run a preflight:

1. Find v0.1 vault candidates.
2. Verify `Vault/nala-mcp-core.sqlite` and `Vault/events.jsonl`.
3. Create or verify a backup/dump.
4. Detect recent MCP client activity.
5. Inspect data while running if needed.
6. Require the user to stop active clients before final migration.

It is technically possible to inspect a WAL-mode SQLite vault while the old helper is running. Final migration should not proceed during active writes.
