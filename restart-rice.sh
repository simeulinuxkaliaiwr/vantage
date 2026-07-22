#!/usr/bin/env bash
# Kills and relaunches `qs -c rice` without touching the daemons that
# live outside of it (awww-daemon, the wl-paste watchers) — those are
# independent and don't need restarting every time you edit a .qml.
#
#   ~/.config/quickshell/rice/restart-rice.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Killing current Quickshell instance..."
pkill -9 qs
pkill -f "qs -c rice" 2>/dev/null
sleep 0.3

echo "Relaunching..."
nohup "$SCRIPT_DIR/launch.sh" > /dev/null 2>&1 &
disown

echo "Rice restarted."
