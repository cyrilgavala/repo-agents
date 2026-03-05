#!/bin/bash

set -euo pipefail

REPO="$HOME/REPOS/Macys_Java"
TAG1="$1"
TAG2="$2"
OUTPUT_FILE="$HOME/REPOS/repo-agents/tmp/collected_diff.patch"

mkdir -p "$(dirname "$OUTPUT_FILE")"
cd "$REPO"
git fetch --tags --force
git diff "$TAG1".."$TAG2" -- apps/wave2/soap -- apps/wave2/amt > "$OUTPUT_FILE"
echo "Diff saved to $OUTPUT_FILE"