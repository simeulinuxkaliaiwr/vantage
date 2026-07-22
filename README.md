# Vantage

A floating-pill Quickshell rice for Hyprland. Glass bar, morphing
panels (the bar itself grows into the launcher/volume/power/wallpaper
picker instead of popping a separate window), pywal-driven color
sync across Hyprland, foot, zsh, and (optionally) qutebrowser.

## Requirements

Core:
- [Hyprland](https://hyprland.org/) with Lua config (`hyprland.lua`)
- [Quickshell](https://quickshell.outfoxxed.me/)
- [pywal](https://github.com/dylanaraps/pywal) (`wal`)
- `awww` or `swww` (wallpaper daemon)
- `cliphist` + `wl-clipboard` (clipboard history)
- `cava` (audio visualizer)
- `ffmpeg` (video wallpaper thumbnails/frames)
- ImageMagick (`magick` or `convert`, thumbnail resizing)
- `foot` (terminal, for the color sync + Dock shortcut)
- `python3`
- A Nerd Font (icons use JetBrainsMono Nerd Font + Symbols Nerd Font glyphs)

Optional:
- `qutebrowser` — if `~/.config/qutebrowser/` doesn't exist, the
  color-sync scripts skip it automatically.
- `hyprlock` — used by the power menu's lock button. If you use a
  different locker, edit the command in `BarMorph.qml`
  (`powerContent` → `cmd = "hyprlock"`).

## Install

```bash
git clone https://github.com/simeulinuxkaliaiwr/vantage ~/vantage-src
cd ~/vantage-src
./install.sh
```

By default this installs to `~/.config/quickshell/vantage/`.

The installer:
1. checks for the dependencies above and warns about anything missing
2. copies the shell into `~/.config/quickshell/vantage/`, backing up
   any existing folder with that name first
3. offers to append a blur `layer_rule` block to your
   `~/.config/hypr/hyprland.lua` — backs the file up before touching it,
   and only if you confirm
4. drops an example keybinds file for you to review (see
   [Keybindings](#keybindings) below) — never auto-applied

Then start it:

```bash
qs -c vantage
```

or add it to `hyprland.lua` so it survives logout:

```lua
exec_once = { "qs -c vantage" }
```

## Manual install

If you'd rather skip the script:

```bash
cp -r vantage ~/.config/quickshell/vantage
chmod +x ~/.config/quickshell/vantage/scripts/*.sh
chmod +x ~/.config/quickshell/vantage/launch.sh
chmod +x ~/.config/quickshell/vantage/restart-rice.sh
qs -c vantage
```

You'll need to add the blur `layer_rule` block yourself — see below.

## Compositor blur

The widgets relies on the layer rule, without the
layer rule below they'll just look flat and semi-transparent. Add
this to your `hyprland.lua` (the installer offers to do it for you):

```lua
hl.config({ decoration = { blur = { enabled = true } } })

for _, ns in ipairs({
  "quickshell-bar", "quickshell-sysinfo", "quickshell-dock",
  "quickshell-holorings", "quickshell-bigclock", "quickshell-notifications"
}) do
  hl.layer_rule({ match = { namespace = ns }, blur = true, ignore_alpha = 0.2 })
end

hl.layer_rule({ match = { namespace = "quickshell-bar" }, blur = true, ignore_alpha = 0.08 })
```

`scripts/write-hypr-theme.sh` also writes rounding/border/animation
config into `~/.config/hypr/colors-wal.lua` on every wallpaper/color
change — make sure your `hyprland.lua` requires it:

```lua
require("colors-wal")
```

## Wallpapers

Drop images/videos into `~/Pictures/Wallpapers/`. Supported:
`.jpg .jpeg .png .webp .mp4 .mkv .webm .mov`. Open the picker with:

```bash
qs -c vantage ipc call wallpaperSelector toggle
```

or click the wallpaper icon in the bar's right-hand cluster.

## Keybindings

Vantage doesn't set any keybinds automatically — `install.sh` drops
an example file at `~/.config/hypr/vantage-keybinds-example.lua`
(hl.bind syntax) for you to review and merge yourself, since
auto-injecting binds risks overwriting ones you already use.

Quick copy-paste if you're starting from scratch:

```lua
local mainMod = "SUPER"

hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("qs -c vantage ipc call appLauncher toggle"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("qs -c vantage ipc call clipboardHistory toggle"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("qs -c vantage ipc call wallpaperSelector toggle"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("qs -c vantage ipc call modeSwitcher toggle"))
hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd("qs -c vantage ipc call colorScheme toggle"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("qs -c vantage ipc call paletteEditor toggle"))
```

Check these don't collide with binds you already have before adding them.

## IPC targets

Full list, for building your own binds:

| Target              | Calls                        | What it does                          |
|---------------------|-------------------------------|-----------------------------------------|
| `appLauncher`        | `toggle` / `open` / `close`   | App launcher (morphs from the bar)      |
| `clipboardHistory`   | `toggle` / `open` / `close`   | Clipboard history (morphs from the bar) |
| `wallpaperSelector`  | `toggle` / `open` / `close`   | Full-screen wallpaper picker            |
| `modeSwitcher`       | `toggle` / `open` / `close`   | normal / minimal / cinema visual mode   |
| `colorScheme`        | `toggle` / `open` / `close`   | auto / dark / light pywal scheme        |
| `paletteEditor`      | `toggle` / `open` / `close`   | Manual 16-color HSL editor              |
| `notifications`      | `notify(summary, body, urgency)` / `clear` | Push/clear notifications  |

## Restarting after edits

```bash
~/.config/quickshell/vantage/restart-rice.sh
```

Kills and relaunches `qs -c vantage` without touching the background
daemons (`awww-daemon`, the `wl-paste --watch` clipboard listeners) —
those don't need restarting on a QML edit.

## License

MIT
