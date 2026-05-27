# Backup / Restore

Backups include:

- manifest.json
- checksums.sha256
- SQLite database copy
- events.jsonl
- restore-readme.md
- ZIP package

Restore always starts with dry-run. v0.1 keeps write restore guarded.
