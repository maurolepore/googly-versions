#!/bin/bash
set -euo pipefail

# Toggle autosave on or off.
# Usage: versions-autosave.sh on|off

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ $# -lt 1 ]] || [[ "$1" != "on" && "$1" != "off" ]]; then
  echo "Usage: versions-autosave.sh on|off" >&2
  exit 1
fi

ACTION="$1"
SETTINGS_DIR=".claude"
MARKER="${SETTINGS_DIR}/.versions-off"

if [[ "$ACTION" == "off" ]]; then
  mkdir -p "$SETTINGS_DIR"
  touch "$MARKER"
  echo "Auto-save off."
elif [[ "$ACTION" == "on" ]]; then
  rm -f "$MARKER"
  "$SCRIPT_DIR/setup.sh" 2>&1
  echo "Auto-save on."
fi
