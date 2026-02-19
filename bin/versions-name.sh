#!/bin/bash
set -euo pipefail

# Name the current version.
# Usage: versions-name.sh <name>
# If dirty: stage all and commit with the name.
# If clean + latest is [auto]: amend with the name.
# If clean + latest is named: exit 1 with message.

if [[ $# -lt 1 || -z "$1" ]]; then
  echo "Usage: versions-name.sh <name>" >&2
  exit 1
fi

NAME="$1"

cd "$(git rev-parse --show-toplevel)"

git add -A
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
  # Dirty: commit with the name
  printf '%s\n' "$NAME" | git -c user.name="Auto-save" -c user.email="auto-save@local" \
    commit -F -
  echo "Named this version '$NAME'."
  exit 0
fi

# Clean: check latest commit
LATEST=$(git log -1 --pretty=format:"%s")

if [[ "$LATEST" == "[auto]"* ]]; then
  # Safe to amend
  printf '%s\n' "$NAME" | git -c user.name="Auto-save" -c user.email="auto-save@local" \
    commit --amend -F -
  echo "Named this version '$NAME'."
  exit 0
fi

# Already named
echo "Already named: '$LATEST'" >&2
exit 1
