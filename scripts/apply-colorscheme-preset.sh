#!/usr/bin/env bash
set -Eeuo pipefail

# apply-colorscheme-preset.sh <auto|gruvbox|catppuccin mocha|rose pine|nord|tokyo night|dracula>
# "auto": rerun pywal on the current wallpaper (default behavior).
# preset: write a full colors.json for that palette and propagate it —
# Colors.qml watches colors.json and recolors itself automatically.
# Note: changing the wallpaper afterward reverts to pywal (auto).

preset="${1:?Usage: apply-colorscheme-preset.sh <name>}"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cache_dir="$HOME/.cache/quickshell-rice"
mkdir -p "$cache_dir"
python3 "$script_dir/generate-startpage-wallpapers.py"
printf '%s' "$preset" > "$cache_dir/colorscheme-preset"

if [ "$preset" = "auto" ]; then
  img="$(cat "$cache_dir/current-palette-image" 2>/dev/null || cat "$HOME/.cache/wal/wal" 2>/dev/null || true)"
  [ -n "$img" ] && [ -f "$img" ] || { echo "no current wallpaper for auto mode" >&2; exit 1; }
  wal -n -q -i "$img"
else
  python3 - "$preset" "$HOME/.cache/wal/colors.json" << 'PY_EOF'
import json, sys
preset, dst = sys.argv[1], sys.argv[2]

P = {
 "gruvbox":          (["#282828","#cc241d","#98971a","#d79921","#458588","#b16286","#689d6a","#a89984"],
                      ["#928374","#fb4934","#b8bb26","#fabd2f","#83a598","#d3869b","#8ec07c","#ebdbb2"],
                      "#282828", "#ebdbb2"),
 "catppuccin mocha": (["#45475a","#f38ba8","#a6e3a1","#f9e2af","#89b4fa","#f5c2e7","#94e2d5","#bac2de"],
                      ["#585b70","#f38ba8","#a6e3a1","#f9e2af","#89b4fa","#f5c2e7","#94e2d5","#a6adc8"],
                      "#1e1e2e", "#cdd6f4"),
 "rose pine":        (["#26233a","#9ccfd8","#31748f","#f6c177","#eb6f92","#c4a7e7","#ebbcba","#e0def4"],
                      ["#6e6a86","#9ccfd8","#31748f","#f6c177","#eb6f92","#c4a7e7","#ebbcba","#e0def4"],
                      "#191724", "#e0def4"),
 "nord":             (["#3b4252","#bf616a","#a3be8c","#ebcb8b","#81a1c1","#b48ead","#88c0d0","#e5e9f0"],
                      ["#4c566a","#bf616a","#a3be8c","#ebcb8b","#81a1c1","#b48ead","#8fbcbb","#eceff4"],
                      "#2e3440", "#d8dee9"),
 "tokyo night":      (["#15161e","#f7768e","#9ece6a","#e0af68","#7aa2f7","#bb9af7","#7dcfff","#a9b1d6"],
                      ["#414868","#f7768e","#9ece6a","#e0af68","#7aa2f7","#bb9af7","#7dcfff","#c0caf5"],
                      "#1a1b26", "#c0caf5"),
 "dracula":          (["#21222c","#ff5555","#50fa7b","#f1fa8c","#bd93f9","#ff79c6","#8be9fd","#f8f8f2"],
                      ["#6272a4","#ff6e6e","#69ff94","#ffffa5","#d6acff","#ff92df","#a4ffff","#ffffff"],
                      "#282a36", "#f8f8f2"),
}

if preset not in P:
    raise SystemExit("unknown preset: " + preset)

normal, bright, bg, fg = P[preset]
colors = {}
for i, c in enumerate(normal):
    colors["color%d" % i] = c
for i, c in enumerate(bright):
    colors["color%d" % (8 + i)] = c

json.dump({"special": {"background": bg, "foreground": fg, "cursor": fg},
           "colors": colors}, open(dst, "w"), indent=2)
print("colors.json written with preset:", preset)
PY_EOF
fi

bash "$script_dir/apply-wallpaper-colors-only.sh"
echo "Color scheme applied: $preset"
