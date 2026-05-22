# Security

NALA-MCP-cORe v0.1.0 is local-first and deny-by-default.

## Defaults

- Runs for the current macOS user only.
- No root privileges are required.
- No system-wide LaunchDaemon is installed.
- No telemetry is sent.
- No cloud APIs or OAuth are used.
- Unknown MCP clients are denied.
- Destructive actions are denied.
- Labs run against snapshots or remain disabled.

## Network Posture

The stable helper is stdio/local oriented. HTTP listener code is not enabled in v0.1.

Loopback validation rejects:

```text
0.0.0.0
LAN IPs
public IPs
```

Allowed bind names are:

```text
127.0.0.1
localhost
::1
```

## Denied Tools

These tools are intentionally absent or denied:

- `delete_memory`
- `overwrite_decision`
- `bulk_import_without_review`
- `wipe_database`
- `remote_execute`

## Logs

Logs are local files under `Logs/`. The log manager redacts simple token, secret, password, and API-key patterns.

## Upgrade Safety

v0.2 upgrade should not mutate v0.1 data in place.

Safe approach:

1. Inspect v0.1 vault candidates.
2. Verify database and event journal.
3. Create or require a current backup.
4. Detect active clients from recent MCP activity.
5. Ask the user to stop those clients before final migration.
6. Migrate from a snapshot.

Inspecting while running is acceptable. Final migration while active clients are writing is not.
