import Quickshell
import "." as Local

// Entry point. Install this folder at ~/.config/quickshell/rice/
// and launch it with `qs -c rice`, ideally from an exec-once in
// your Hyprland config so it survives as a background daemon.
ShellRoot {
    Local.Bar {}
    Local.BarMorph {}
    Local.WallpaperSelector {}
    Local.ClipboardHistory {}
    Local.AppLauncher {}
    Local.ModeSwitcher {}
    Local.ColorSchemeSwitcher {}
    Local.PaletteEditor {}
    Local.BigClock {}
    Local.AudioVisualizer {}
    Local.Dock {}
    Local.SystemMonitor {}
    Local.HoloRings {}
    Local.NotificationCenter {}
}
