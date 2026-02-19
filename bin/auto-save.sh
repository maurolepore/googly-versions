#!/bin/bash

# Auto-save hook for Claude Code "Stop" event.
# Must NEVER exit non-zero (would surface as hook failure).
trap 'exit 0' EXIT

# Check for marker file — user turned off autosave
DIR="${CLAUDE_PROJECT_DIR:-.}"
if [[ -f "${DIR}/.claude/.versions-off" ]]; then
  exit 0
fi

if ! command -v git &>/dev/null; then
  echo "[versions] git is not installed. Install git to enable auto-save." >&2
  exit 0
fi

[[ -d "$DIR" ]] || exit 0
cd "$DIR"

# Init git if needed (but not in home dir or root)
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  [[ "$PWD" == "$HOME" || "$PWD" == "/" ]] && exit 0
  git init || exit 0
  [[ -f .gitignore ]] || printf '.env\n.DS_Store\nThumbs.db\nnode_modules/\n*.tmp\n' > .gitignore
  git add -A && git -c user.name="Auto-save" -c user.email="auto-save@local" \
    commit -m "[auto] Initial version" --allow-empty
  exit 0
fi

# Don't interfere with in-progress git operations
GIT_DIR=$(git rev-parse --git-dir 2>/dev/null) || exit 0
if [[ -d "$GIT_DIR/rebase-merge" || -d "$GIT_DIR/rebase-apply" || -f "$GIT_DIR/MERGE_HEAD" ]]; then
  exit 0
fi

# Skip if lock held (another git process running)
[[ -f "$GIT_DIR/index.lock" ]] && exit 0

# Stage all, skip if nothing changed
git add -A
if git rev-parse HEAD &>/dev/null; then
  git diff-index --quiet HEAD -- && exit 0
fi

# Commit with timestamp
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
BODY=$(git diff --cached --stat --stat-width=60)
git -c user.name="Auto-save" -c user.email="auto-save@local" \
  commit -m "[auto] ${TIMESTAMP}" -m "${BODY}"
