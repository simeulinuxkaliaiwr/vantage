#!/usr/bin/env bash
set -Eeuo pipefail
cache="$HOME/.cache/quickshell-rice"; mkdir -p "$cache"
exec 9>"$cache/apply.lock"; flock 9
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
"$script_dir/apply-wallpaper-colors-only.sh"
