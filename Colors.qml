pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "." as Local

// Reads ~/.cache/wal/colors.json (pywal) and exposes the palette
// as reactive QML properties, plus the fixed layout tokens for the
// floating-pill look (radius, blur, fonts, etc).
QtObject {
    id: root

    readonly property string jsonPath: Quickshell.env("HOME") + "/.cache/wal/colors.json"

    readonly property string fontFamily: "JetBrainsMono Nerd Font"

    readonly property int radius: 16
    readonly property int borderWidth: 1
    readonly property int spacing: 14
    readonly property int barHeight: 40

    // the bar floats as a pill instead of spanning the screen edge to edge
    readonly property bool barFloating: true

    readonly property bool animationsEnabled: true
    readonly property int animDuration: 220

    readonly property bool glowEnabled: true
    readonly property real overlayOpacity: 0.7

    property color walBackground: "#0d0d0d"
    property color walForeground: "#e0e0e0"
    property color walCursor: "#e0e0e0"

    property var walPalette: [
        "#0d0d0d", "#cc6666", "#b5bd68", "#f0c674",
        "#81a2be", "#b294bb", "#8abeb7", "#e0e0e0",
        "#3a3a3a", "#cc6666", "#b5bd68", "#f0c674",
        "#81a2be", "#b294bb", "#8abeb7", "#ffffff"
    ]

    readonly property color background: walBackground
    readonly property color foreground: walForeground
    readonly property color cursor: walCursor
    readonly property var palette: walPalette

    readonly property color accent: palette[4]
    readonly property color accent2: palette[6]
    readonly property color muted: palette[8]

    property FileView _file: FileView {
        path: root.jsonPath
        watchChanges: true
        blockLoading: false
        printErrors: false
        onFileChanged: reload()
        onLoaded: root._parse(text())
    }

    // pywal is sometimes still writing the file when we boot, so
    // keep polling until it actually loads once
    property Timer _retryTimer: Timer {
        interval: 1000
        running: !root._hasLoadedOnce
        repeat: true
        onTriggered: root._file.reload()
    }

    property bool _hasLoadedOnce: false

    function _parse(text) {
        if (!text || text.length === 0) return;
        try {
            const data = JSON.parse(text);
            if (data.special) {
                root.walBackground = data.special.background || root.walBackground;
                root.walForeground = data.special.foreground || root.walForeground;
                root.walCursor = data.special.cursor || root.walCursor;
            }
            if (data.colors) {
                const newPalette = [];
                for (let i = 0; i < 16; ++i) {
                    newPalette.push(data.colors["color" + i] || root.walPalette[i]);
                }
                root.walPalette = newPalette;
            }
            root._hasLoadedOnce = true;
        } catch (e) {
            console.warn("Colors: failed to parse colors.json —", e);
        }
    }
}
