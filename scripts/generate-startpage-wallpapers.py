#!/usr/bin/env python3
from pathlib import Path
p = Path.home() / ".cache/quickshell-rice/startpage-wallpapers"
p.mkdir(parents=True, exist_ok=True)
data = {
    "gruvbox": ("282828", "d79921", "98971a"),
    "catppuccin-mocha": ("1e1e2e", "89b4fa", "cba6f7"),
    "rose-pine": ("191724", "c4a7e7", "eb6f92"),
    "nord": ("2e3440", "88c0d0", "81a1c1"),
    "tokyo-night": ("1a1b26", "7aa2f7", "bb9af7"),
    "dracula": ("282a36", "bd93f9", "ff79c6"),
}
t = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1920 1080"><defs><radialGradient id="g"><stop stop-color="#%s" stop-opacity=".65"/><stop offset="1" stop-color="#%s"/></radialGradient></defs><rect width="1920" height="1080" fill="#%s"/><circle cx="350" cy="250" r="700" fill="url(#g)"/><circle cx="1600" cy="830" r="620" fill="#%s" opacity=".35"/></svg>'
for name, (bg, a, b) in data.items():
    (p / (name + ".svg")).write_text(t % (a, b, bg, b))
