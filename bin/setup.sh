#!/bin/bash
set -euo pipefail

# Initialize git in the current project directory.
# No hook injection needed — hooks.json handles that natively.

PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-.}}"

cd "$PROJECT_DIR"

if ! command -v git &>/dev/null; then
  echo "Error: git is required." >&2
  exit 1
fi

# Init git if needed (but not in home dir or root)
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  if [[ "$PWD" == "$HOME" || "$PWD" == "/" ]]; then
    echo "Skipping git init in $PWD"
    exit 0
  fi
  git init
  echo "Initialized git in ${PROJECT_DIR}"
fi
