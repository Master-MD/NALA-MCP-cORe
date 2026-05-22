# NALA-MCP-cORe — Caveman README

## What is this?

NALA-MCP-cORe is your local memory box.

It runs on your Mac. It stores project stuff. Codex, Gemini, Antigravity, and later NALA-bRaiN can ask it what happened before.

No internet needed. No cloud API. Your data stays local.

## Why do I need it?

Because project memory gets split across tools.

One tool knows one thing. Another tool knows something else. Codex starts from zero.

NALA-MCP-cORe keeps the local truth.

## Where is my data?

Default:

```text
~/Library/Application Support/NALA-MCP-cORe/
```

You can choose another folder on first launch.

## How do I start the server?

Open the app.

Go to:

```text
Status
```

Click:

```text
Start Server
```

In v0.1 this starts the local helper state. The helper executable is built as:

```text
.build/debug/nala-mcp-core-helper
```

## How do I connect Codex?

Build the project:

```bash
swift build --product nala-mcp-core-helper
```

Use the sample config in:

```text
sample-codex-config.md
```

## How do I connect Gemini?

Use:

```text
sample-gemini-config.md
```

## How do I connect Antigravity?

Use:

```text
sample-antigravity-config.md
```

## How do I save project memory?

Open:

```text
Projects
```

Pick:

```text
Project / Memory / Decision / Bug / Session Summary
```

Write the content. Click `Save Entry`.

## How do I search old stuff?

Open:

```text
Search
```

Type query. Click `Search`.

Search uses SQLite FTS5. It does not scan all files.

## How do I backup?

Open:

```text
Backups
```

Click:

```text
Backup Now
```

You get a manifest, checksums, ZIP, database copy, events copy, and restore readme.

## How do I restore?

Open:

```text
Restore
```

Choose a full backup folder. Click:

```text
Run Dry-Run
```

v0.1 verifies first. Write restore is guarded and disabled in the UI.

## What are Labs?

Labs are experiments.

Labs do not touch the live vault. They use snapshot sandboxes.

## What is safe?

- Local vault
- Backup Now
- Restore dry-run
- Full dump export
- NALA-bRaiN sync export
- Unknown clients denied
- Destructive tools denied

## What is experimental?

- Import Lab
- Export Lab
- MongoDB export package
- ChromaDB export package
- MemPalace export package
- Docling/RAG export package
- SSH sync
- Cloud folder export lab

## What should I not touch?

Do not manually edit the SQLite database unless you made a backup.

Do not expose the helper to LAN.

Do not add destructive MCP tools in v0.1.

## Why are clients gray/yellow/green?

Gray = known only.

Yellow = configured or reachable, but no real call yet.

Green = healthy or active.

Red = error or denied.

Do not panic if Gemini is gray. It means Gemini has not talked to NALA-MCP-cORe yet.

## How do I connect Antigravity?

Antigravity has two places:

1. Permissions
2. Real MCP config

Permissions only allow or deny. They do not create the server.

The real server config goes here:

```text
~/.gemini/antigravity/mcp_config.json
```

Use the Copy Antigravity Config button.

## Why does STDIO look like it hangs?

Because STDIO waits for the MCP client. That can be normal.

Do not kill it only because it does not print text.

## What is the menu bar icon?

Small NALA status in the macOS menu bar.

Green = running.
Yellow = warning.
Red = error.
Gray = stopped.
Blue pulse = recent request.

## What is Flow Monitor?

It shows where data flows.

Allowed flows are green.
Blocked flows are red.
Local internal flows are blue.
Planned flows are gray.

Internet and LAN should stay blocked.

## What is Deep Stats?

Deep Stats shows CPU, RAM, requests, tool usage, client usage, errors, database size, and backup history.

## How does v0.2 upgrade work?

First NALA looks for v0.1 data. Then it checks the database and event journal. Then it tells you which clients look active.

You stop those apps first. Then migration uses a verified snapshot.
