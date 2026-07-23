import QtQuick
import Quickshell
import Quickshell.Io
import "." as Local

// Thin IPC entry point — the actual launcher UI lives inside
// BarMorph.qml (the bar grows into the launcher panel). This file
// only exists so `qs -c vantage ipc call appLauncher toggle` works
// from outside (e.g. a Hyprland keybind).
Item {
    IpcHandler {
        target: "appLauncher"
        function toggle(): void { Local.AppState.requestMorph("launcher"); }
        function open(): void { Local.AppState.requestMorph("launcher"); }
        function close(): void { Local.AppState.closeMorph(); }
    }
}
