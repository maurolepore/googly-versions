#!/bin/bash
set -euo pipefail

# Squash consecutive [auto] commits from HEAD into one.
# Usage: versions-squash-autosaves.sh

cd "$(git rev-parse --show-toplevel)"

# Count consecutive [auto] commits from HEAD
COUNT=0
while true; do
  SUBJECT=$(git log -1 --skip="$COUNT" --pretty=format:"%s" 2>/dev/null) || break
  [[ "$SUBJECT" == "[auto]"* ]] || break
  COUNT=$((COUNT + 1))
done

if [[ "$COUNT" -le 1 ]]; then
  echo "Nothing to squash."
  exit 0
fi

# Get timestamp of newest [auto] (HEAD)
NEWEST_TS=$(git log -1 --pretty=format:"%ad" --date=format:"%Y-%m-%d %H:%M:%S")

# Parent of the oldest consecutive [auto] commit
TARGET=$(git rev-parse "HEAD~${COUNT}")

# Stash uncommitted changes if any
STASHED=false
if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
  git stash push -q -m "squash-autosaves-temp"
  STASHED=true
fi

# Squash: soft reset then recommit
git reset --soft "$TARGET"
git -c user.name="Auto-save" -c user.email="auto-save@local" \
  commit -m "[auto] $NEWEST_TS"

# Restore stash if needed
if $STASHED; then
  git stash pop -q
fi

echo "Squashed $COUNT versions into 1."
