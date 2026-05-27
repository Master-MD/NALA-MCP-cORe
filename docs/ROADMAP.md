# NALA-MCP-cORe Roadmap

Status: 2026-05-27

NALA-MCP-cORe stays the local, deny-by-default memory and MCP control center. Future integrations must preserve local ownership, explicit pairing, auditability, and no automatic sharing of sensitive app data.

## Near-Term

- Keep v0.1 Stable Core and UI Stats Flow builds side by side.
- Stabilize v0.2 upgrade preflight before any final migration from old vaults.
- Add a local NALA App Registry so sibling NALA apps on the same Mac can discover NALA-MCP-cORe without LAN exposure.
- Add first-class planning support for NALA-DNA-Med as the first sensitive-app integration.

## NALA-DNA-Med Bridge

- [ ] Add an app-registry reader for manifests under `~/Library/Application Support/NALA/AppRegistry/`.
- [ ] Add capability-aware pairing: `read_context`, `write_summary`, `write_research_note`, `request_compute`, and `sync_export`.
- [ ] Add MCP tools for app discovery and safe app summaries without exposing raw biomedical data by default.
- [ ] Add a NALA-DNA-Med client profile with stricter defaults than normal project apps.
- [ ] Add UI copy that clearly says NALA-DNA-Med can share research notes and project summaries, but not diagnosis, treatment advice, patient data, raw DNA data, or private files unless explicitly approved.
- [ ] Add tests proving unknown apps are denied, unpaired apps cannot read or write, and DNA-MED cannot export raw protected data without a dedicated capability.
- [ ] Document the enduser flow in Help, FAQ, README, and README-CAVEMAN before shipping any tester build.

## NALA-bRaiN Bridge

- [ ] Keep first bridge as package import/export, not live writes into the MCP SQLite vault.
- [ ] Validate manifest, checksums, schema version, and fingerprints before import.
- [ ] Put conflicts into a review queue.
- [ ] Route later LLM/compute requests through NALA-bRaiN Control Plane or LLM Router, not direct ad-hoc model endpoints.
- [ ] Keep Beelink/Nalchen/edge compute as registered compute nodes behind policy, quota, audit, and explicit user consent.

## Reference Plan

See [NALA-DNA-Med MCP-cORe Bridge Plan](NALA_DNA_MED_MCP_CORE_BRIDGE_PLAN.md).
