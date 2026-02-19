#!/bin/bash
set -euo pipefail

# Restore files from a given version hash.
# Usage: versions-restore.sh <hash>
# Expects the AI to have already confirmed with the user.
# Saves current work if dirty, then restores from the hash.

if [[ $# -lt 1 || -z "$1" ]]; then
  echo "Usage: versions-restore.sh <hash>" >&2
  exit 1
fi

HASH="$1"

cd "$(git rev-parse --show-toplevel)"

# Validate hash
if ! git cat-file -t "$HASH" &>/dev/null; then
  echo "Invalid version: $HASH" >&2
  exit 1
fi

# Save current work if dirty
git add -A
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
  TIMESTAMP=$(LC_ALL=C date "+%b %d, %I:%M %p")
  BODY=$(git diff --cached --stat --stat-width=60)
  git -c user.name="Auto-save" -c user.email="auto-save@local" \
    commit -m "[auto] ${TIMESTAMP}" -m "${BODY}"
fi

# Get version name for the restore commit
VERSION_NAME=$(git log -1 --pretty=format:"%s" "$HASH")

# Restore
git rm -rf . 2>/dev/null || true
if ! git checkout "$HASH" -- .; then
  # Recovery
  git reset HEAD 2>/dev/null || true
  git checkout HEAD -- . 2>/dev/null || true
  echo "Something went wrong. Your files are unchanged." >&2
  exit 1
fi

# Create restore marker commit
git add -A
printf '[restore] Restored to %s\n' "$VERSION_NAME" | \
  git -c user.name="Auto-save" -c user.email="auto-save@local" commit -F -

echo "Restored to version '$VERSION_NAME'."
