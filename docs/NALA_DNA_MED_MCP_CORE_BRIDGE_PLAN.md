# NALA-DNA-Med MCP-cORe Bridge Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let NALA-DNA-Med and NALA-MCP-cORe discover each other locally, pair with explicit capabilities, and exchange safe research/project memory without exposing raw biomedical data by default.

**Architecture:** Add a local NALA App Registry plus a capability-based pairing layer in NALA-MCP-cORe. NALA-DNA-Med writes a small manifest, asks the user to pair, then uses the existing local MCP helper for health, project context, and approved summary writes. NALA-bRaiN and Beelink compute stay out of the first MVP except as documented future routing through NALA-bRaiN Control Plane / LLM Router.

**Tech Stack:** Swift 6.3, SwiftUI, SwiftPM, XCTest, local JSON manifests, NALA-MCP-cORe stdio JSON-RPC helper, SQLite/FTS5, local Markdown Help/FAQ.

---

## Safety Rules

- No diagnosis, treatment, prescription, emergency guidance, or clinical decision support.
- No patient identifiers, raw DNA files, raw medical records, or restricted source files in shared memory unless a later explicit capability and UI confirmation exist.
- Unknown apps are denied.
- Unpaired apps are denied.
- Paired apps receive only the capabilities the user approved.
- NALA-DNA-Med default capabilities are limited to `health_check`, `search_context`, `list_projects`, `add_session_summary`, and `add_decision_candidate`.
- Compute requests to NALA-bRaiN, Nalchen, or Beelink are not part of the first MVP.

## Phase 1: Local Discovery

**Files:**
- Create: `Sources/NALAMCPcOReCore/Services/NALAAppRegistryManager.swift`
- Modify: `Sources/NALAMCPcOReCore/Models/UIStatsModels.swift`
- Test: `Tests/NALAMCPcOReCoreTests/NALAAppRegistryTests.swift`

- [ ] Define `NALAAppManifest` with `appID`, `displayName`, `bundleID`, `version`, `manifestVersion`, `capabilitiesRequested`, `safetyClass`, `endpointKind`, and `lastSeenAt`.
- [ ] Read manifests from `~/Library/Application Support/NALA/AppRegistry/*.json`.
- [ ] Reject manifests without stable app ID, bundle ID, safety class, or capability list.
- [ ] Add a fixture manifest for `ch.nala.dna-med`.
- [ ] Test that a valid DNA-MED manifest is discovered.
- [ ] Test that malformed manifests are ignored and logged.

## Phase 2: Pairing And Permissions

**Files:**
- Create: `Sources/NALAMCPcOReCore/Services/AppPairingManager.swift`
- Modify: `Sources/NALAMCPcOReCore/Services/PermissionManager.swift`
- Test: `Tests/NALAMCPcOReCoreTests/NALAAppPairingTests.swift`

- [ ] Store pairing state in `Config/app-pairings.json`.
- [ ] Add statuses: `unpaired`, `requested`, `paired`, `denied`, `revoked`.
- [ ] Add capability decisions per app, not only per client name.
- [ ] Default NALA-DNA-Med to no raw export and no compute.
- [ ] Test that unpaired DNA-MED cannot call read or write tools.
- [ ] Test that paired DNA-MED can call only approved safe tools.
- [ ] Test that capability revocation blocks the next request.

## Phase 3: MCP Tool Surface

**Files:**
- Modify: `Sources/NALAMCPcOReCore/Services/MCPServer.swift`
- Modify: `Sources/NALAMCPcOReCore/Services/MCPJSONRPCBridge.swift`
- Test: `Tests/NALAMCPcOReCoreTests/NALAAppMCPBridgeTests.swift`

- [ ] Add `list_nala_apps` to show discovered local NALA apps and pairing state.
- [ ] Add `request_app_pairing` for an app to request a pairing ticket.
- [ ] Add `add_research_note_summary` as a safe write path for DNA-MED summary data.
- [ ] Keep `export_dump` blocked for DNA-MED unless an explicit export capability is approved.
- [ ] Return structuredContent with app ID, capability, status, and audit ID.
- [ ] Test unknown app denial.
- [ ] Test successful safe summary write from paired DNA-MED.

## Phase 4: UI And Help

**Files:**
- Modify: `Sources/NALAMCPcOReApp/Views/ConnectionWizardView.swift`
- Modify: `Sources/NALAMCPcOReApp/Views/FlowMonitorView.swift`
- Create: `Sources/NALAMCPcOReApp/Resources/Help/connect-nala-dna-med.md`
- Modify: `README.md`
- Modify: `README-CAVEMAN.md`

- [ ] Add a NALA Apps section next to MCP Clients.
- [ ] Show DNA-MED as `found`, `pairing requested`, `paired`, `denied`, or `revoked`.
- [ ] Show requested capabilities with plain-language explanations.
- [ ] Add Help/FAQ text for safe research-note sharing.
- [ ] Add Caveman copy: "DNA-MED can share notes, not private medical files, unless you explicitly allow it later."

## Phase 5: Verification

- [ ] Run `swift test`.
- [ ] Run `./script/build_and_run.sh --verify`.
- [ ] Test pairing from a sample DNA-MED manifest.
- [ ] Confirm README, README-CAVEMAN, Help, and FAQ are present for tester builds.
- [ ] Confirm no runtime vault, index, log, backup, patient, DNA, or secret data is staged for GitHub.

## Later: NALA-bRaiN / Nalchen / Beelink

- Route compute through NALA-bRaiN Control Plane or LLM Router.
- Treat Beelink as a registered compute node behind NALA-bRaiN policy.
- Do not let DNA-MED call a raw model endpoint directly.
- Add request types such as `summarize_sources`, `rank_literature`, and `draft_research_note`.
- Require data-class labels before compute: `public`, `project-private`, `biomedical-sensitive`, or `patient-restricted`.
