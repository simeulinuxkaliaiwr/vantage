-- Example Hyprland keybinds for Vantage.
-- Written in hl.bind syntax (Hyprland Lua config, 0.5x+).
--
-- This file is NOT auto-loaded by install.sh — copy the binds you
-- want into your own hyprland.lua, adjusting mainMod/exec_cmd calls
-- to match your setup. Skip any line that collides with a bind you
-- already have.
--
-- Replace "vantage" below if you installed under a different name
-- (qs -c <name>).

local mainMod = "SUPER"

hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("qs -c vantage ipc call appLauncher toggle"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("qs -c vantage ipc call clipboardHistory toggle"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("qs -c vantage ipc call wallpaperSelector toggle"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("qs -c vantage ipc call modeSwitcher toggle"))
hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd("qs -c vantage ipc call colorScheme toggle"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("qs -c vantage ipc call paletteEditor toggle"))
