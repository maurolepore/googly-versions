#!/bin/bash
set -euo pipefail

# Show versions as a markdown table.
# Usage: versions-show.sh [--named] [-n COUNT]
# --named: exclude [auto] and [restore] entries
# -n COUNT: limit output (default 20)

NAMED=false
COUNT=20

while [[ $# -gt 0 ]]; do
  case "$1" in
    --named) NAMED=true; shift ;;
    -n) COUNT="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Get log entries
LOG=$(git log --pretty=format:"%h|%ad|%s" --date=format:"%b %d, %I:%M %p" -n "$COUNT")

if [[ -z "$LOG" ]]; then
  echo "No versions found."
  exit 0
fi

HEAD_HASH=$(git rev-parse --short HEAD)

echo "| Name | Created |"
echo "|------|---------|"

PREV_DATE=""
while IFS='|' read -r hash date subject; do
  # Skip auto/restore if --named
  if $NAMED; then
    [[ "$subject" == "[auto]"* || "$subject" == "[restore]"* ]] && continue
  fi

  # Strip prefixes for display
  display="$subject"
  display="${display#\[auto\] }"
  display="${display#\[restore\] }"

  # Auto-save entries show empty name
  if [[ "$subject" == "[auto]"* ]]; then
    display=""
  fi

  # Mark HEAD as current
  if [[ "$hash" == "$HEAD_HASH" ]]; then
    if [[ -n "$display" ]]; then
      display="$display (current)"
    else
      display="(current)"
    fi
  fi

  # Group by date (extract "Mon DD" portion)
  day="${date%%,*}"

  # Add separator between different dates
  if [[ -n "$PREV_DATE" && "$day" != "$PREV_DATE" ]]; then
    echo "| | |"
  fi
  PREV_DATE="$day"

  echo "| $display | $date |"
done <<< "$LOG"

# Check for unsaved changes
if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
  echo ""
  echo "You have unsaved changes."
fi
