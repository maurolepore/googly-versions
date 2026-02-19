#!/bin/bash
set -euo pipefail

# Copy a version to a sibling directory.
# Usage: versions-copy.sh <hash> <name>
# Outputs the created directory path.

if [[ $# -lt 2 || -z "$1" || -z "$2" ]]; then
  echo "Usage: versions-copy.sh <hash> <name>" >&2
  exit 1
fi

HASH="$1"
NAME="$2"

cd "$(git rev-parse --show-toplevel)"

# Validate hash
if ! git cat-file -t "$HASH" &>/dev/null; then
  echo "Invalid version: $HASH" >&2
  exit 1
fi

# Resolve real path of parent dir to avoid symlink traversal
REAL_PWD=$(pwd -P)
PARENT_DIR=$(dirname "$REAL_PWD")

# Sanitize name for directory
SAFE_NAME=$(echo "$NAME" | tr -cs '[:alnum:]-_.' '-' | sed 's/^-//;s/-$//')
COPY_DIR="${PARENT_DIR}/$(basename "$REAL_PWD")-copy-of-${SAFE_NAME}"

# Collision avoidance
i=2
while [[ -d "$COPY_DIR" ]]; do
  COPY_DIR="${PARENT_DIR}/$(basename "$REAL_PWD")-copy-of-${SAFE_NAME}-${i}"
  ((i++))
done

mkdir "$COPY_DIR"
git archive "$HASH" | tar -x -C "$COPY_DIR"

# Output the resolved path
echo "$COPY_DIR"
