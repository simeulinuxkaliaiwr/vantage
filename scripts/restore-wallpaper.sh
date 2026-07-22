#!/usr/bin/env bash
# restore-wallpaper.sh
#
# Called by launch.sh at boot, after awww-daemon comes up. Reads the
# last real wallpaper saved by apply-wallpaper.sh and:
#   - if it's a video: reapplies everything (mpvpaper + pywal + colors),
#     since nothing else relaunches mpvpaper after a reboot;
#   - if it's an image: does nothing — awww-daemon restores it on its
#     own and colors are already persisted in colors-wal.lua/foot.ini/zsh.

set -euo pipefail

STATE_FILE="$HOME/.cache/quickshell-rice/current-wallpaper"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[ -f "$STATE_FILE" ] || exit 0

IMG="$(sed -n '1p' "$STATE_FILE")"
TYPE="$(sed -n '2p' "$STATE_FILE")"

[ -n "$IMG" ] && [ -f "$IMG" ] || exit 0

if [ "$TYPE" = "video" ]; then
	exec "$SCRIPT_DIR/apply-wallpaper.sh" "$IMG"
fi
