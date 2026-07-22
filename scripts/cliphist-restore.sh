#!/usr/bin/env bash
# cliphist-restore.sh <full cliphist-list line>
#
# Content comes in via argv, not string interpolation — avoids any
# shell injection risk even if the copied content has quotes, $,
# backticks, etc.

set -euo pipefail

LINE="${1:?Usage: cliphist-restore.sh <line>}"

printf '%s' "$LINE" | cliphist decode | wl-copy
