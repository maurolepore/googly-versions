#!/bin/bash
set -euo pipefail

# Squash consecutive [auto] commits from HEAD into one.
# Usage: versions-squash-autosaves.sh

cd "$(git rev-parse --show-toplevel)"

# Count consecutive [auto] commits from HEAD
TOTAL=$(git rev-list --count HEAD)
COUNT=0
while [[ "$COUNT" -lt "$TOTAL" ]]; do
  SUBJECT=$(git log -1 --skip="$COUNT" --pretty=format:"%s") || break
  [[ "$SUBJECT" == "[auto]"* ]] || break
  COUNT=$((COUNT + 1))
done

if [[ "$COUNT" -le 1 ]]; then
  echo "Nothing to squash."
  exit 0
fi

# Get timestamp of newest [auto] (HEAD)
NEWEST_TS=$(git log -1 --pretty=format:"%ad" --date=format:"%Y-%m-%d %H:%M:%S")

# Stash uncommitted changes if any
STASHED=false
if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
  git stash push -q -m "squash-autosaves-temp"
  STASHED=true
fi

# Restore stash on exit (success or failure)
cleanup() {
  if $STASHED; then
    git stash pop -q || echo "Warning: stash pop failed — your changes are still in 'git stash list'." >&2
  fi
}
trap cleanup EXIT

# Squash: soft reset (or delete HEAD if all are [auto]), then recommit
if [[ "$COUNT" -eq "$TOTAL" ]]; then
  git update-ref -d HEAD
else
  TARGET=$(git rev-parse "HEAD~${COUNT}")
  git reset --soft "$TARGET"
fi

git -c user.name="Auto-save" -c user.email="auto-save@local" \
  commit -m "[auto] $NEWEST_TS"

echo "Squashed $COUNT versions into 1."
