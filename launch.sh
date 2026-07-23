#!/usr/bin/env bash
# Boots the whole shell as a background daemon.
#
# Meant to be called from exec-once in hyprland.lua — stays running
# for the rest of the session.
#
#   qs -c rice ipc call wallpaperSelector toggle

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! pgrep -x awww-daemon > /dev/null; then
	awww-daemon &
	sleep 0.5
fi

# awww-daemon only restores static images on its own; if the last
# wallpaper was a video, nothing relaunches mpvpaper after a reboot
"$SCRIPT_DIR/scripts/restore-wallpaper.sh" >/dev/null 2>&1 &

if ! pgrep -f "wl-paste --type text --watch cliphist store" > /dev/null; then
	wl-paste --type text --watch cliphist store &
fi
if ! pgrep -f "wl-paste --type image --watch cliphist store" > /dev/null; then
	wl-paste --type image --watch cliphist store &
fi

chmod +x "$SCRIPT_DIR/scripts/apply-wallpaper.sh" \
         "$SCRIPT_DIR/scripts/apply-foot-colors.py" \
         "$SCRIPT_DIR/scripts/cliphist-restore.sh" \
         "$SCRIPT_DIR/scripts/cliphist-delete.sh" \
         "$SCRIPT_DIR/scripts/restore-wallpaper.sh" \
         "$SCRIPT_DIR/scripts/wallpaper-thumbnail.sh"

exec qs -c vantage
