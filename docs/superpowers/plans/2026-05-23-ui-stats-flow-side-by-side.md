# NALA-MCP-cORe UI Stats Flow Side-by-Side Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Patch the existing Stable Core with the v2 UI/Stats/Connection/Flow upgrade while preserving the currently runnable v0.1 app bundle and preparing a safe v0.1-to-v0.2 upgrade preflight.

**Architecture:** Keep the Stable Core database and write APIs unchanged. Add small, testable core services for connection state, copy-ready configs, helper symlink planning, flow policies, lightweight monitoring, menu-bar state mapping, and upgrade preflight, then layer SwiftUI screens over those services.

**Tech Stack:** Swift 6.3, SwiftUI, AppKit, SwiftPM, XCTest, SQLite3/FTS5, process-local monitoring models, local Markdown help resources.

---

## Dry-Run Checklist

- [x] Read `NALA-MCP-cORe-MASTERPACK-v2-UI-Stats-Flow.md`.
- [x] Confirmed this is a patch, not a Stable Core rewrite.
- [x] Confirmed existing workspace is a Git root on `main`.
- [x] Confirmed existing source and docs are uncommitted/untracked, so no git worktree will be created.
- [x] Preserve current running v0.1 by changing the build script to stage a side-by-side preview bundle.
- [x] Do not run `pkill -x NALA-MCP-cORe`; preview process name must be distinct.
- [x] Keep destructive actions denied.
- [x] Keep LAN/internet blocked.
- [x] Do not fake active client state or resource metrics.
- [x] v0.2 upgrade strategy: inspect/verify while running, but require user-assisted stop for final migration if active clients or helper activity are detected.

## Implementation Tasks

### Task 1: Core UI/Connection Services

**Files:**
- Create: `Sources/NALAMCPcOReCore/Models/UIStatsModels.swift`
- Create: `Sources/NALAMCPcOReCore/Services/ClientConnectionManager.swift`
- Create: `Sources/NALAMCPcOReCore/Services/ClientConfigGenerator.swift`
- Create: `Sources/NALAMCPcOReCore/Services/HelperSymlinkManager.swift`
- Create: `Sources/NALAMCPcOReCore/Services/ResourceMonitor.swift`
- Create: `Sources/NALAMCPcOReCore/Services/FlowMatrixBuilder.swift`
- Create: `Sources/NALAMCPcOReCore/Services/UpgradePreflightManager.swift`
- Modify: `Sources/NALAMCPcOReCore/StableCore.swift`
- Test: `Tests/NALAMCPcOReCoreTests/UIStatsFlowTests.swift`

- [x] Write failing tests for client state resolution, config generation, symlink plan, monitor sample aggregation, flow policies, menu-bar state mapping, and upgrade preflight.
- [x] Implement the minimal core services.
- [x] Wire services into `StableCore`.
- [x] Run tests and keep existing Stable Core tests green.

### Task 2: SwiftUI Surfaces

**Files:**
- Modify: `Sources/NALAMCPcOReApp/App/AppModel.swift`
- Modify: `Sources/NALAMCPcOReApp/App/NALAMCPcOReApp.swift`
- Modify: `Sources/NALAMCPcOReApp/Views/MainContentView.swift`
- Modify: `Sources/NALAMCPcOReApp/Views/StableCoreViews.swift`
- Modify: `Sources/NALAMCPcOReApp/Views/OperationsViews.swift`
- Create: `Sources/NALAMCPcOReApp/Views/ConnectionWizardView.swift`
- Create: `Sources/NALAMCPcOReApp/Views/StatusDashboardView.swift`
- Create: `Sources/NALAMCPcOReApp/Views/DeepStatsView.swift`
- Create: `Sources/NALAMCPcOReApp/Views/FlowMonitorView.swift`
- Create: `Sources/NALAMCPcOReApp/Views/HelpView.swift`
- Create: `Sources/NALAMCPcOReApp/Views/MenuBarStatusView.swift`

- [x] Replace flat MCP Clients screen with connection wizard tabs.
- [x] Replace Status screen with responsive dashboard cards.
- [x] Add Deep Stats and Flow Monitor destinations.
- [x] Expand Settings with General, Vault, Server, MCP Connections, Permissions, Monitoring, Menu Bar, Backups, Dumps, Labs, Advanced sections.
- [x] Add Help menu/window and optional MenuBarExtra.
- [x] Improve adaptive layout and bottom status truncation.

### Task 3: Help And Documentation

**Files:**
- Modify: `Package.swift`
- Create: `Sources/NALAMCPcOReApp/Resources/Help/*.md`
- Modify: `README.md`
- Modify: `README-CAVEMAN.md`
- Modify: `MCP_CLIENTS.md`
- Modify: `DEVELOPMENT.md`
- Modify: `SECURITY.md`

- [x] Bundle local Markdown help files.
- [x] Document client badges, Antigravity config distinction, STDIO behavior, menu bar, Flow Monitor, Deep Stats, and v0.2 upgrade preflight.

### Task 4: Side-by-Side Build Safety

**Files:**
- Modify: `script/build_and_run.sh`
- Modify: `.codex/environments/environment.toml`

- [x] Stage default builds as `dist/NALA-MCP-cORe-UIStatsPreview.app`.
- [x] Use preview executable/process name to avoid killing `NALA-MCP-cORe`.
- [x] Add a clearly named stable override for explicit old-name packaging only.
- [x] Verify `./script/build_and_run.sh --verify` launches preview without replacing `dist/NALA-MCP-cORe.app`.

### Task 5: Verification

- [x] Run `swift test`.
- [x] Run `./script/build_and_run.sh --verify`.
- [x] Inspect `git status --short`.
- [x] Confirm generated preview bundle path and no overwrite of current v0.1 bundle.
