#!/usr/bin/env bash
# wallpaper-thumbnail.sh <video>
#
# Generates (with caching) a PNG thumbnail for a video and prints the
# path to stdout. Cached by path+mtime hash in
# ~/.cache/quickshell-rice/wallpaper-thumbs/ — ffmpeg only runs once
# per file; subsequent calls are just a stat + md5sum.

set -euo pipefail

SRC="${1:?Usage: wallpaper-thumbnail.sh <video>}"
[ -f "$SRC" ] || exit 1

THUMB_DIR="$HOME/.cache/quickshell-rice/wallpaper-thumbs"
mkdir -p "$THUMB_DIR"

MTIME="$(stat -c %Y "$SRC")"
HASH="$(printf '%s|%s' "$SRC" "$MTIME" | md5sum | cut -d' ' -f1)"
OUT="$THUMB_DIR/$HASH.png"

if [ ! -s "$OUT" ]; then
	ffmpeg -y -ss 1 -i "$SRC" -frames:v 1 -vf "scale=440:-1" -update 1 "$OUT" >/dev/null 2>&1 \
		|| ffmpeg -y -i "$SRC" -frames:v 1 -vf "scale=440:-1" -update 1 "$OUT" >/dev/null 2>&1 \
		|| exit 1
fi

[ -s "$OUT" ] && printf '%s\n' "$OUT"
