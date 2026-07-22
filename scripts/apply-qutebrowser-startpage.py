#!/usr/bin/env python3
# Generates the qutebrowser startpage.
# Usage: apply-qutebrowser-startpage.py <colors.json> <palette-image> <qutebrowser-config-dir>
#
# >>> EDIT HERE: swap in your own shortcut list. Format: (title, url, icon).
import json
import sys
from pathlib import Path

SHORTCUTS = [
    ("github", "https://github.com", "\uf09b"),
    ("youtube", "https://youtube.com", "\uf16a"),
    ("claude", "https://claude.ai", "\uf0eb"),
    ("arch wiki", "https://wiki.archlinux.org", "\uf303"),
    ("reddit", "https://reddit.com", "\uf281"),
    ("proton mail", "https://mail.proton.me", "\uf0e0"),
]

TEMPLATE = '''<!doctype html><html><head><meta charset="utf-8"><title>// startpage</title><style>
*{box-sizing:border-box}
:root{--fg:@@FG@@;--bg:@@BG@@;--ac:@@ACCENT@@;--ac2:@@ACCENT2@@;--mu:@@MUTED@@}
body{margin:0;min-height:100vh;overflow:hidden;color:var(--fg);
  font-family:Inter,system-ui,sans-serif;position:relative;
  background:#05050a url("file://@@WALL@@") center/cover fixed;
  display:flex;flex-direction:column;align-items:center;justify-content:center;gap:36px}
body:before{content:"";position:fixed;inset:0;pointer-events:none;z-index:0;
  background:radial-gradient(ellipse at 50% 0%,var(--ac)22,transparent 55%),
             radial-gradient(ellipse at 50% 100%,var(--ac2)18,transparent 55%),
             linear-gradient(var(--bg)cc,var(--bg)ee)}
body:after{content:"";position:fixed;inset:0;pointer-events:none;z-index:0;opacity:.06;
  background-image:linear-gradient(var(--fg) 1px,transparent 1px),
                    linear-gradient(90deg,var(--fg) 1px,transparent 1px);
  background-size:44px 44px}
.bracket{position:fixed;width:26px;height:26px;pointer-events:none;z-index:2}
.bracket b{position:absolute;background:var(--ac);display:block}
.tl{top:22px;left:22px}.tl .h{top:0;left:0;width:26px;height:2px}.tl .v{top:0;left:0;width:2px;height:26px}
.tr{top:22px;right:22px}.tr .h{top:0;right:0;width:26px;height:2px}.tr .v{top:0;right:0;width:2px;height:26px}
.bl{bottom:22px;left:22px}.bl .h{bottom:0;left:0;width:26px;height:2px}.bl .v{bottom:0;left:0;width:2px;height:26px}
.br{bottom:22px;right:22px}.br .h{bottom:0;right:0;width:26px;height:2px}.br .v{bottom:0;right:0;width:2px;height:26px}
.hud{z-index:1;text-align:center}
.clock{font-size:64px;font-weight:200;letter-spacing:2px;color:var(--fg);
  text-shadow:0 0 24px var(--ac)aa;line-height:1}
.status{margin-top:10px;font-family:"Symbols Nerd Font",monospace;font-size:11px;
  letter-spacing:4px;text-transform:uppercase;color:var(--ac2);opacity:.85}
.status .dot{display:inline-block;width:6px;height:6px;border-radius:50%;
  background:var(--ac2);margin-right:8px;box-shadow:0 0 8px var(--ac2);
  animation:blink 2s ease-in-out infinite}
@keyframes blink{50%{opacity:.25}}
.grid{z-index:1;display:grid;grid-template-columns:repeat(3,200px);gap:14px}
.card{min-height:120px;padding:20px;text-decoration:none;color:var(--fg);
  display:flex;flex-direction:column;justify-content:center;gap:8px;
  border-radius:14px;border:1px solid var(--ac)44;
  background:var(--bg)55;
  backdrop-filter:blur(16px) saturate(1.4);-webkit-backdrop-filter:blur(16px) saturate(1.4);
  box-shadow:inset 0 1px #ffffff22,0 10px 24px #00000044;
  animation:enter .5s cubic-bezier(.2,.8,.2,1) both;
  transition:transform .22s cubic-bezier(.2,.9,.2,1),box-shadow .22s,border-color .22s}
@keyframes enter{from{opacity:0;transform:translateY(18px)}}
.card:hover{transform:translateY(-5px);border-color:var(--ac);
  box-shadow:0 0 22px var(--ac)66,inset 0 1px #ffffff33}
.card b{font-size:22px;font-weight:400;color:var(--ac2);
  font-family:"Symbols Nerd Font",monospace}
.card span{font-size:14px;letter-spacing:.5px}
</style></head><body>
<div class="bracket tl"><b class="h"></b><b class="v"></b></div>
<div class="bracket tr"><b class="h"></b><b class="v"></b></div>
<div class="bracket bl"><b class="h"></b><b class="v"></b></div>
<div class="bracket br"><b class="h"></b><b class="v"></b></div>
<div class="hud">
  <div class="clock" id="c">--:--</div>
  <div class="status"><span class="dot"></span>system online</div>
</div>
<main class="grid">@@CARDS@@</main>
<script>
function tick(){document.getElementById("c").textContent=
  new Date().toLocaleTimeString("en-US",{hour:"2-digit",minute:"2-digit"});}
tick();setInterval(tick,1000);
</script></body></html>'''


def fill(template, mapping):
    for key, value in mapping.items():
        template = template.replace("@@" + key + "@@", value)
    return template


def main():
    if len(sys.argv) < 4:
        raise SystemExit("usage: apply-qutebrowser-startpage.py <colors.json> <image> <output-dir>")

    data = json.load(open(sys.argv[1]))
    wall = sys.argv[2]
    out_dir = Path(sys.argv[3])
    out_dir.mkdir(parents=True, exist_ok=True)

    preset_file = Path.home() / ".cache/quickshell-rice/colorscheme-preset"
    preset = preset_file.read_text().strip() if preset_file.exists() else "auto"
    preset_wall = Path.home() / ".cache/quickshell-rice/startpage-wallpapers" / (preset.replace(" ", "-") + ".svg")
    if preset != "auto" and preset_wall.exists():
        wall = str(preset_wall)

    colors = {
        "BG": data["special"]["background"],
        "FG": data["special"]["foreground"],
        "ACCENT": data["colors"]["color4"],
        "ACCENT2": data["colors"]["color6"],
        "MUTED": data["colors"]["color8"],
        "WALL": wall,
    }

    cards = "".join(
        '<a class="card" style="animation-delay:{d}s" href="{u}">'
        '<b>{ic}</b><span>{n}</span></a>'.format(d=round(i * 0.06, 2), u=u, ic=ic, n=n)
        for i, (n, u, ic) in enumerate(SHORTCUTS)
    )
    html = fill(TEMPLATE, dict(colors, CARDS=cards))

    (out_dir / "startpage.html").write_text(html, encoding="utf-8")
    print("startpage written to", out_dir / "startpage.html")


if __name__ == "__main__":
    main()
