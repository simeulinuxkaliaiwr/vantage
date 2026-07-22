#!/usr/bin/env bash
# apply-color-scheme.sh <dark|light|auto>
#
# Reruns pywal on the current wallpaper in dark or light mode without
# swapping the wallpaper, then propagates the new colors to Hyprland,
# foot, zsh, and qutebrowser.
#
# "auto" picks dark or light based on the wallpaper's average luminance.

set -euo pipefail

SCHEME="${1:-auto}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WAL_FILE="$HOME/.cache/wal/wal"

if [ ! -f "$WAL_FILE" ]; then
    echo "ERROR: no wallpaper found at $WAL_FILE" >&2
    echo "Apply a wallpaper from the picker first." >&2
    exit 1
fi

IMG="$(cat "$WAL_FILE")"

if [ ! -f "$IMG" ]; then
    echo "ERROR: wallpaper not found: $IMG" >&2
    exit 1
fi

if [ "$SCHEME" = "auto" ]; then
    LUMINANCE=$(python3 -c "
import sys
try:
    from PIL import Image
    img = Image.open('$IMG').convert('L').resize((50, 50))
    avg = sum(img.getdata()) / len(img.getdata())
    print('light' if avg > 127 else 'dark')
except ImportError:
    import subprocess
    result = subprocess.run(
        ['magick', '$IMG', '-resize', '1x1!', '-format', '%[mean]', 'info:'],
        capture_output=True, text=True
    )
    val = float(result.stdout.strip() or '0')
    print('light' if val > 32767 else 'dark')
except Exception:
    print('dark', file=sys.stderr)
    print('dark')
" 2>/dev/null || echo "dark")
    echo "Auto detected: $LUMINANCE"
    SCHEME="$LUMINANCE"
fi

CACHE_DIR="$HOME/.cache/quickshell-rice"
mkdir -p "$CACHE_DIR"
echo "$SCHEME" > "$CACHE_DIR/color-scheme"

echo "Applying color scheme: $SCHEME"
if [ "$SCHEME" = "light" ]; then
    wal -i "$IMG" -n -s -q -l
else
    wal -i "$IMG" -n -s -q
fi

echo "Palette regenerated, propagating..."
bash "$SCRIPT_DIR/apply-wallpaper-colors-only.sh"
