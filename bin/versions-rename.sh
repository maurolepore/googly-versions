#!/bin/bash
set -euo pipefail

# Rename a version.
# Usage: versions-rename.sh <query> <new-name>
# Uses versions-find.sh to locate the version, then amends or rebases.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ $# -lt 2 || -z "$1" || -z "$2" ]]; then
  echo "Usage: versions-rename.sh <query> <new-name>" >&2
  exit 1
fi

QUERY="$1"
NEW_NAME="$2"

cd "$(git rev-parse --show-toplevel)"

# Find the version
MATCH=$("$SCRIPT_DIR/versions-find.sh" "$QUERY")
HASH=$(echo "$MATCH" | awk '{print $1}')

# Check if it's the latest commit
HEAD_HASH=$(git rev-parse --short HEAD)

if [[ "$HASH" == "$HEAD_HASH" ]]; then
  # Latest: amend directly
  printf '%s\n' "$NEW_NAME" | git -c user.name="Auto-save" -c user.email="auto-save@local" \
    commit --amend -F -
else
  # Older: non-interactive rebase to reword
  # Write new name to temp file to avoid command injection via GIT_EDITOR
  TMPFILE=$(mktemp)
  trap 'rm -f "$TMPFILE"' EXIT
  printf '%s\n' "$NEW_NAME" > "$TMPFILE"

  SHORT_HASH=$(git rev-parse --short "$HASH")
  GIT_SEQUENCE_EDITOR="sed -i '' 's/^pick '$SHORT_HASH'/reword '$SHORT_HASH'/'" \
  GIT_EDITOR="cp '$TMPFILE'" \
  git -c user.name="Auto-save" -c user.email="auto-save@local" rebase -i "$HASH"^
fi

echo "Renamed to '$NEW_NAME'."
