# NALA-MCP-cORe Stable Core v0.1.0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS SwiftUI Stable Core app for local-only MCP memory storage, search, backup, restore dry-run, dumps, permissions, logs, and isolated labs.

**Architecture:** Use a SwiftPM package with a reusable core library, a SwiftUI macOS app executable, and a small stdio helper executable. The core owns all vault writes, SQLite/FTS5 indexing, JSONL journaling, audit logging, permissions, backups, restore dry-runs, dumps, and lab sandbox snapshots.

**Tech Stack:** Swift 6.3, SwiftUI, AppKit, XCTest, SQLite3/FTS5, CryptoKit, SwiftPM, generated `.app` bundle packaging.

---

## Dry-Run Checklist

- [x] Repository inspected. The workspace only contained `NALA-MCP-cORe-MASTERPACK.md`.
- [x] No existing app files to preserve.
- [x] Git initialized at the workspace root for Codex app integration.
- [x] Target platform confirmed as macOS native SwiftUI.
- [x] Build approach selected: SwiftPM package plus generated `.app` bundle.
- [x] App icon source selected from the user-provided `NALA-MCP-cORe.png`.
- [x] Destructive v0.1 tools excluded from scope.
- [x] Labs scoped as visible but isolated or disabled.
- [x] Server scoped to stdio/local-only with non-loopback HTTP binding denied.

## Unknowns and Assumptions

- No blocking unknowns.
- The SwiftPM plus generated `.app` bundle approach is accepted as the v0.1 build form because it is reproducible, testable, and still launches as a native macOS app bundle with the supplied icon.
- The MCP helper implements the local tool surface and a JSON-lines stdio helper suitable for v0.1 integration samples; destructive tools are intentionally absent.
- Restore writes stay disabled in v0.1 safe mode while restore dry-run, manifest parsing, and checksum verification are functional.

## Task 1: Project Scaffold

**Files:**
- Create: `Package.swift`
- Create: `Sources/CSQLite/include/CSQLite.h`
- Create: `Sources/NALAMCPcOReApp/App/NALAMCPcOReApp.swift`
- Create: `Sources/NALAMCPcOReHelper/main.swift`
- Create: `script/build_and_run.sh`
- Create: `.codex/environments/environment.toml`

- [x] Create SwiftPM package targets for core library, GUI app, helper, and tests.
- [x] Add a C shim for SQLite3.
- [x] Add app and helper entrypoints.
- [x] Add project-local build/run script that packages a `.app` bundle and embeds the supplied icon.
- [x] Wire Codex Run action to the build/run script.

## Task 2: Stable Core Services

**Files:**
- Create: `Sources/NALAMCPcOReCore/Models/CoreModels.swift`
- Create: `Sources/NALAMCPcOReCore/Services/*.swift`
- Create: `Sources/NALAMCPcOReCore/Support/*.swift`

- [x] Implement vault directory creation and default/custom vault resolution.
- [x] Implement SQLite schema, WAL mode, FTS5 search index, canonical object tables, and seed clients.
- [x] Implement fingerprint hashing and metadata index export.
- [x] Implement JSONL event journal and audit logger.
- [x] Implement permission decisions with unknown-client denial and v0.1 destructive-action denial.
- [x] Implement core write APIs for projects, memories, decisions, bugs, session summaries, and decision candidates.
- [x] Implement local-only MCP tool dispatch.
- [x] Implement backup manager, restore dry-run, dump manager, lab sandbox manager, and log manager.

## Task 3: SwiftUI App

**Files:**
- Create: `Sources/NALAMCPcOReApp/Views/*.swift`

- [x] Implement first-launch vault picker.
- [x] Implement native sidebar for Stable Core and Experimental Labs.
- [x] Implement status, search, manual entry, clients, permissions, database, backups, restore, dumps, logs, health, and settings screens.
- [x] Keep visible buttons either functional or disabled with a planned/safe-mode label.
- [x] Keep Stable Core independent from Labs.

## Task 4: Tests

**Files:**
- Create: `Tests/NALAMCPcOReCoreTests/StableCoreTests.swift`

- [x] Add XCTest coverage for database initialization, WAL, FTS5, indexed search, JSONL events, fingerprints, permissions, unknown clients, backups, checksums, restore dry-run, dumps, NALA-bRaiN package, lab sandboxing, and localhost-only validation.
- [x] Run the tests red/green during implementation where practical for this blank scaffold.

## Task 5: Documentation

**Files:**
- Create: `README.md`
- Create: `README-CAVEMAN.md`
- Create: `SECURITY.md`
- Create: `BACKUP_RESTORE.md`
- Create: `MCP_CLIENTS.md`
- Create: `LABS.md`
- Create: `DEVELOPMENT.md`
- Create: `sample-codex-config.md`
- Create: `sample-gemini-config.md`
- Create: `sample-antigravity-config.md`

- [x] Document local-only operation, vault paths, backup/restore, MCP helper samples, labs, and development commands.

## Task 6: Verification

- [x] Run `swift test`.
- [x] Run `./script/build_and_run.sh --verify`.
- [x] Inspect git status and summarize changed files.
