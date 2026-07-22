#!/usr/bin/env bash
set -Eeuo pipefail

colors_json="${1:-$HOME/.cache/wal/colors.json}"
palette_image="${2:-$(cat "$HOME/.cache/quickshell-rice/current-palette-image" 2>/dev/null || true)}"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

[[ -s "$colors_json" ]] || { echo "missing colors.json: $colors_json" >&2; exit 1; }

bash "$script_dir/write-hypr-theme.sh" "$colors_json"

if [[ -f "$HOME/.config/foot/foot.ini" ]]; then
  python3 "$script_dir/apply-foot-colors.py" "$colors_json" "$HOME/.config/foot/foot.ini"
fi

if [[ -d "$HOME/.config/qutebrowser" ]]; then
  python3 "$script_dir/apply-qutebrowser-colors.py" "$colors_json" "$HOME/.config/qutebrowser"
  if [[ -n "$palette_image" && -f "$palette_image" ]]; then
    python3 "$script_dir/apply-qutebrowser-startpage.py" "$colors_json" "$palette_image" "$HOME/.config/qutebrowser"
  fi
  pkill -HUP -x qutebrowser 2>/dev/null || true
fi

python3 - "$colors_json" "$HOME/.cache/wal/colors-zsh.sh" << 'PY_EOF'
import json, sys
c = json.load(open(sys.argv[1]))["colors"]

def to256(hexcolor):
    h = hexcolor.lstrip("#")
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    return 16 + 36 * round(r / 255 * 5) + 6 * round(g / 255 * 5) + round(b / 255 * 5)

pairs = [("RICE_COL_ACCENT", c["color4"]), ("RICE_COL_MUTED", c["color8"]),
         ("RICE_COL_OK", c["color2"]), ("RICE_COL_ERROR", c["color1"])]
with open(sys.argv[2], "w") as f:
    for key, color in pairs:
        f.write('typeset -g %s="%d"\n' % (key, to256(color)))
PY_EOF

echo "colors propagated: Hyprland, foot, qutebrowser, zsh"
