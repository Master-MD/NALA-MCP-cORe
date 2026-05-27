#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
cd "$ROOT_DIR"

fail() {
  echo "preflight failed: $*" >&2
  exit 1
}

echo "Checking staged files for GitHub publish safety..."

staged_files="$(git diff --cached --name-only --diff-filter=ACMR || true)"
if [[ -z "$staged_files" ]]; then
  echo "No staged files. Running workspace ignore/secret checks only."
fi

blocked_regex='(^|/)(Vault|Config|Index|Logs|Sandboxes|Exports|Backups|backups|dumps|dist)(/|$)|\.app(/|$)|\.dmg$|\.sha256$|\.sqlite($|-)|\.db($|-)|\.jsonl$|\.log$|\.zip$|(^|/)\.env(\.|$)|\.(pem|key|p8|p12|cer|mobileprovision)$|(^|/)NALA-MCP-cORe-MASTERPACK.*\.md$'

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  if [[ "$file" =~ $blocked_regex ]]; then
    fail "blocked staged path: $file"
  fi
done <<< "$staged_files"

credential_pattern='(sk-[A-Za-z0-9_-]{20,}|ghp_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|AIza[0-9A-Za-z_-]{20,}|xox[baprs]-[0-9A-Za-z-]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|([Aa][Pp][Ii][_-]?[Kk][Ee][Yy]|[Tt][Oo][Kk][Ee][Nn]|[Ss][Ee][Cc][Rr][Ee][Tt]|[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd])[[:space:]]*[:=][[:space:]]*["'\'']?[A-Za-z0-9_./+=-]{12,})'

if [[ -n "$staged_files" ]]; then
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    [[ -f "$file" ]] || continue
    if file "$file" | grep -qi 'text\|json\|swift\|markdown\|shell script\|toml\|xml'; then
      if LC_ALL=C grep -En "$credential_pattern" "$file" >/tmp/nala_preflight_hits.txt 2>/dev/null; then
        cat /tmp/nala_preflight_hits.txt >&2
        fail "possible secret in staged file: $file"
      fi
    fi
  done <<< "$staged_files"
fi

tracked_ignored="$(git ls-files -ci --exclude-standard || true)"
if [[ -n "$tracked_ignored" ]]; then
  echo "$tracked_ignored" >&2
  fail "ignored files are already tracked"
fi

if git status --short --ignored | grep -E '!! (Vault|Config|Index|Logs|Sandboxes|Exports|Backups|backups|dumps|.*\.sqlite|.*\.jsonl|.*\.env)' >/dev/null; then
  echo "Runtime/private files are ignored as expected."
fi

echo "GitHub publish preflight passed."
