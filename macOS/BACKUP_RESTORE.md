# Backup And Restore

## Backup Now

The app creates:

```text
Vault/backups/NALA-MCP-cORe-Backups/
  full/full-YYYY-MM-DD-HHMMSS/
    manifest.json
    checksums.sha256
    nala-mcp-core.sqlite
    events.jsonl
    restore-readme.md
  full/full-YYYY-MM-DD-HHMMSS.zip
  deltas/delta-YYYY-MM-DD-HHMMSS.jsonl
  manifests/manifest-YYYY-MM-DD-HHMMSS.json
```

SQLite is checkpointed before the database copy.

## Restore Dry-Run

Restore dry-run:

1. Reads `manifest.json`.
2. Verifies `checksums.sha256`.
3. Opens the backup database copy.
4. Counts available data by table.
5. Produces a preview.

Write restore remains guarded in v0.1 safe mode.
