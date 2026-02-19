#!/bin/bash
set -euo pipefail

# Find a version by query (fixed-string match).
# Usage: versions-find.sh <query>
# Output: HASH SUBJECT (single best match)
# Exit 1: no match. Exit 2: multiple matches (top 5 on stderr).

if [[ $# -lt 1 || -z "$1" ]]; then
  echo "Usage: versions-find.sh <query>" >&2
  exit 1
fi

QUERY="$1"

if command -v fzf &>/dev/null; then
  MATCHES=$(git log --pretty=format:"%h %s" | fzf --filter="$QUERY" || true)
else
  # Use -F for fixed-string matching (no regex injection)
  MATCHES=$(git log --pretty=format:"%h %s" | grep -iF "$QUERY" || true)
fi

COUNT=$(echo "$MATCHES" | grep -c . || true)

if [[ "$COUNT" -eq 0 ]]; then
  echo "No version matching '$QUERY'" >&2
  exit 1
fi

if [[ "$COUNT" -gt 1 ]]; then
  echo "Multiple matches for '$QUERY':" >&2
  echo "$MATCHES" | head -5 >&2
  exit 2
fi

echo "$MATCHES"
