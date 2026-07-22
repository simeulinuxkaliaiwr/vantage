#!/usr/bin/env bash
# cliphist-thumbnail.sh <full cliphist-list line>
#
# Generates (and caches) a small PNG thumbnail from a cliphist image
# entry and prints the thumbnail's path to stdout — that's what QML
# uses as an Image source.
#
# Cache: thumbnails live in ~/.cache/quickshell-rice/thumbnails/,
# named by the cliphist entry ID (stable unless the entry gets deleted
# and recreated). Avoids re-running ImageMagick every time the list
# view re-renders.
#
# Based on cliphist's own contrib scripts (cliphist-wofi-img,
# cliphist-fuzzel-img): decode -> resize -> cache.

set -euo pipefail

LINE="${1:?Usage: cliphist-thumbnail.sh <line>}"

ID="${LINE%%$'\t'*}"

THUMB_DIR="$HOME/.cache/quickshell-rice/thumbnails"
mkdir -p "$THUMB_DIR"

THUMB_PATH="$THUMB_DIR/$ID.png"

if [ -f "$THUMB_PATH" ]; then
	echo "$THUMB_PATH"
	exit 0
fi

if command -v magick > /dev/null; then
	RESIZE_CMD="magick"
elif command -v convert > /dev/null; then
	RESIZE_CMD="convert"
else
	echo "ERROR: ImageMagick (magick/convert) not found" >&2
	exit 1
fi

# decode -> resize -> cache as PNG. "256x256>" only shrinks, never
# upscales, preserving aspect ratio.
printf '%s' "$LINE" | cliphist decode | "$RESIZE_CMD" - -resize "256x256>" "$THUMB_PATH"

echo "$THUMB_PATH"
