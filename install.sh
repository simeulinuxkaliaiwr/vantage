#!/usr/bin/env bash
set -euo pipefail

# install.sh — installs Vantage into ~/.config/quickshell/yourusername/,
# checks dependencies, and optionally wires up compositor blur in
# hyprland.lua. Safe to re-run: existing installs and hyprland.lua
# are always backed up before being touched. Keybinds are never
# auto-applied — see the "Keybindings" section this script prints
# at the end.

RICE_NAME="vantage"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="$HOME/.config/quickshell/$RICE_NAME"
HYPR_CONF="$HOME/.config/hypr/hyprland.lua"

BLUR_MARKER_BEGIN="-- BEGIN VANTAGE BLUR"
BLUR_MARKER_END="-- END VANTAGE BLUR"

c_green() { printf '\033[32m%s\033[0m\n' "$1"; }
c_yellow() { printf '\033[33m%s\033[0m\n' "$1"; }
c_red() { printf '\033[31m%s\033[0m\n' "$1"; }

echo "Installing to: $DEST_DIR"
echo

REQUIRED=(qs wal cliphist wl-copy cava ffmpeg foot python3)
MISSING=()

for bin in "${REQUIRED[@]}"; do
  command -v "$bin" >/dev/null 2>&1 || MISSING+=("$bin")
done

if ! command -v magick >/dev/null 2>&1 && ! command -v convert >/dev/null 2>&1; then
  MISSING+=("imagemagick (magick or convert)")
fi

if ! command -v awww >/dev/null 2>&1 && ! command -v swww >/dev/null 2>&1; then
  MISSING+=("awww or swww")
fi

if [ ${#MISSING[@]} -gt 0 ]; then
  c_yellow "Missing dependencies (things will break without them):"
  for m in "${MISSING[@]}"; do echo "  - $m"; done
  echo
fi

if ! command -v qutebrowser >/dev/null 2>&1; then
  c_yellow "qutebrowser not found — that's fine, its color sync is skipped automatically."
  echo
fi

if ! command -v hyprlock >/dev/null 2>&1; then
  c_yellow "hyprlock not found — the power menu's Lock button won't work unless"
  c_yellow "you edit the lock command in BarMorph.qml (powerContent) to your locker."
  echo
fi

if [ ${#MISSING[@]} -gt 0 ]; then
  read -rp "Continue anyway? [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]] || { c_red "Aborted."; exit 1; }
fi

# ---- copy the shell, backing up any existing install ----
mkdir -p "$HOME/.config/quickshell"

if [ -e "$DEST_DIR" ]; then
  BACKUP_DIR="${DEST_DIR}.bak-$(date +%Y%m%d-%H%M%S)"
  c_yellow "Existing install found — backing up to $BACKUP_DIR"
  mv "$DEST_DIR" "$BACKUP_DIR"
fi

cp -r "$SRC_DIR" "$DEST_DIR"
rm -rf "$DEST_DIR/.git" "$DEST_DIR/install.sh" "$DEST_DIR/keybinds-example.lua" \
       "$DEST_DIR/scripts/__pycache__" "$DEST_DIR/README.md"

chmod +x "$DEST_DIR/launch.sh" "$DEST_DIR/restart-rice.sh"
chmod +x "$DEST_DIR"/scripts/*.sh

c_green "Shell installed to $DEST_DIR"
echo

# ---- offer to wire up hyprland.lua blur rules ----
if [ ! -f "$HYPR_CONF" ]; then
  c_yellow "No hyprland.lua found at $HYPR_CONF — skipping compositor blur setup."
  c_yellow "See the README's 'Compositor blur' section to add it manually."
else
  if grep -qF "$BLUR_MARKER_BEGIN" "$HYPR_CONF"; then
    c_green "hyprland.lua already has the Vantage blur block — leaving it alone."
  else
    echo "Vantage needs a blur layer_rule block in hyprland.lua for the"
    echo "glass panels to actually blur (otherwise they're just flat and"
    echo "translucent). This will be appended to the end of the file."
    read -rp "Append it now? A backup will be made first. [y/N] " reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      HYPR_BACKUP="${HYPR_CONF}.bak-$(date +%Y%m%d-%H%M%S)"
      cp "$HYPR_CONF" "$HYPR_BACKUP"
      c_green "Backed up hyprland.lua to $HYPR_BACKUP"

      cat >> "$HYPR_CONF" << EOF

$BLUR_MARKER_BEGIN
-- Added by Vantage's install.sh — safe to edit or remove.
hl.config({ decoration = { blur = { enabled = true } } })

for _, ns in ipairs({
  "quickshell-bar", "quickshell-sysinfo", "quickshell-dock",
  "quickshell-holorings", "quickshell-bigclock", "quickshell-notifications"
}) do
  hl.layer_rule({ match = { namespace = ns }, blur = true, ignore_alpha = 0.2 })
end

hl.layer_rule({ match = { namespace = "quickshell-bar" }, blur = true, ignore_alpha = 0.08 })
$BLUR_MARKER_END
EOF
      c_green "Appended blur config to hyprland.lua"

      if ! grep -qF "colors-wal" "$HYPR_CONF"; then
        c_yellow "Note: hyprland.lua doesn't seem to require colors-wal.lua yet."
        c_yellow "Add this so pywal colors actually apply to borders/rounding:"
        echo '    require("colors-wal")'
      fi
    else
      c_yellow "Skipped. See the README's 'Compositor blur' section to add it later."
    fi
  fi
fi

echo

KEYBINDS_SRC="$SRC_DIR/keybinds-example.lua"
KEYBINDS_DEST="$HOME/.config/hypr/${RICE_NAME}-keybinds-example.lua"

if [ -f "$KEYBINDS_SRC" ]; then
  cp "$KEYBINDS_SRC" "$KEYBINDS_DEST"
  c_green "Example keybinds copied to $KEYBINDS_DEST"
  c_yellow "These are NOT active — review them (hl.bind syntax) and merge"
  c_yellow "into your hyprland.lua manually to avoid clobbering binds you"
  c_yellow "already have."
fi

# ---- cava config ----
CAVA_SRC="$SRC_DIR/cava-config-rice"
CAVA_DEST_DIR="$HOME/.config/cava"
CAVA_DEST="$CAVA_DEST_DIR/cava-config-rice"

if [ -f "$CAVA_SRC" ]; then
  mkdir -p "$CAVA_DEST_DIR"
  if [ -f "$CAVA_DEST" ]; then
    c_yellow "Existing cava-config-rice found — leaving it alone."
    c_yellow "(Compare against $CAVA_SRC if the visualizer looks wrong.)"
  else
    cp "$CAVA_SRC" "$CAVA_DEST"
    c_green "cava config installed to $CAVA_DEST"
  fi
else
  c_yellow "cava-config-rice not found in the repo — the audio visualizer"
  c_yellow "widget will fail silently without it. See the README."
fi

echo
c_green "Done."
echo "Start it with:"
echo "  qs -c $RICE_NAME"
echo
echo "Or add to hyprland.lua for autostart:"
echo "  exec_once = { \"qs -c $RICE_NAME\" }"
echo
echo "Keybind ideas: $KEYBINDS_DEST"
