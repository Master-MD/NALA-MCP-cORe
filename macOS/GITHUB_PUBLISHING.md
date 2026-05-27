# GitHub Publishing Safety

Target repository:

```text
https://github.com/Master-MD/NALA-MCP-cORe
```

The repository can stay private, but local safety still matters. Do not push vaults, indexes, logs, dumps, backups, personal planning packs, API keys, or credentials.

## Local Guardrails

Before committing or pushing:

```bash
./script/preflight_github_publish.sh
```

The preflight blocks staged files matching:

- `Vault/`, `Config/`, `Index/`, `Logs/`, `Sandboxes/`, `Exports/`
- `dist/`, `.app` bundles, DMGs, and checksum sidecars
- backups, dumps, ZIPs
- SQLite databases and WAL/SHM sidecars
- JSONL journals and indexes
- `.env`, private keys, certificates, provisioning profiles
- `NALA-MCP-cORe-MASTERPACK*.md`
- common API token/key patterns

Install the local hook once:

```bash
git config core.hooksPath .githooks
```

## Recommended First Publish

1. Confirm the target GitHub repo is private in the GitHub web UI.
2. Keep `main` local until the preflight is green.
3. Stage explicit source/docs files only.
4. Run tests.
5. Commit.
6. Push to the private remote.

Commands:

```bash
git remote add origin https://github.com/Master-MD/NALA-MCP-cORe.git
git add Package.swift Sources Tests script .codex .githooks .gitignore README.md README-CAVEMAN.md SECURITY.md BACKUP_RESTORE.md MCP_CLIENTS.md LABS.md DEVELOPMENT.md GITHUB_PUBLISHING.md sample-codex-config.md sample-gemini-config.md sample-antigravity-config.md docs/superpowers/plans
./script/preflight_github_publish.sh
swift test
./script/build_dmg.sh
git commit -m "Initial NALA-MCP-cORe stable core"
git push -u origin main
```

Do not use `git add -A` until you have checked `git status --short`.
Upload `dist/NALA-MCP-cORe-UIStatsPreview-v0.1.0.dmg` as a GitHub Release asset, not as a committed repository file.
