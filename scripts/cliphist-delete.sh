#!/usr/bin/env bash
# cliphist-delete.sh <full cliphist-list line>
# Same argv-based safety as cliphist-restore.sh — never interpolated
# into a shell string.

set -euo pipefail

LINE="${1:?Usage: cliphist-delete.sh <line>}"

printf '%s' "$LINE" | cliphist delete
