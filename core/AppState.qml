pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// interaction state, and the pywal light/dark scheme.
QtObject {
    id: root

    property bool modeSwitcherVisible: false

    // The bar "morphs" into whatever panel is open (power menu,
    // wallpaper picker, volume...) growing out of the pill itself
    // instead of just popping a separate window on top of it.
    property string barMorph: ""

    property real morphOriginX: 0
    property real morphOriginY: 0
    property real morphOriginWidth: 0
    property real morphOriginHeight: 0
    property real morphScreenHeight: 1080
    property string morphScreenName: ""

    function openMorph(name, originX, originY, originWidth, originHeight, screenName, screenHeight) {
        root.morphOriginX = originX;
        root.morphOriginY = originY;
        root.morphOriginWidth = originWidth;
        root.morphOriginHeight = originHeight;
        root.morphScreenName = screenName;
        root.morphScreenHeight = screenHeight;
        root.barMorph = name;
    }

    function closeMorph() {
        root.barMorph = "";
    }

    signal morphRequested(string name)
    signal morphClosed(string screenName)

    function requestMorph(name) { root.morphRequested(name); }

    property bool barTemporarilyHidden: false
    property Timer barHideTimer: Timer {
        interval: 1600
        repeat: false
        onTriggered: root.barTemporarilyHidden = false
    }
    function hideBarTemporarily(ms) {
        barHideTimer.interval = ms;
        root.barTemporarilyHidden = true;
        barHideTimer.restart();
    }

    // normal / minimal / cinema — persisted to disk so it survives restarts
    property string mode: "normal"
    readonly property bool showBar: mode !== "cinema"
    readonly property bool showDesktopWidgets: mode === "normal"

    readonly property string persistPath: Quickshell.env("HOME") + "/.cache/quickshell-rice/mode"

    Component.onCompleted: modeReader.running = true

    onModeChanged: {
        // capture the value explicitly before building the command —
        // binding root.mode straight into the Process command caused a
        // real race where the value written to disk lagged one step
        // behind what was actually selected
        const modeToWrite = root.mode;
        modeWriter.command = ["bash", "-c",
            "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"",
            "--", root.persistPath, modeToWrite];
        modeWriter.running = true;
    }

    property Process modeReader: Process {
        command: ["cat", root.persistPath]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const saved = this.text.trim();
                if (saved === "normal" || saved === "minimal" || saved === "cinema") {
                    root.mode = saved;
                }
            }
        }
    }

    property Process modeWriter: Process { running: false }

    // auto = pywal decides from wallpaper luminance, dark/light = forced
    property string colorScheme: "dark"
    readonly property string schemePersistPath: Quickshell.env("HOME") + "/.cache/quickshell-rice/color-scheme"

    onColorSchemeChanged: {
        const schemeToWrite = root.colorScheme;
        schemeWriter.command = ["bash", "-c",
            "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"",
            "--", root.schemePersistPath, schemeToWrite];
        schemeWriter.running = true;
    }

    property Process schemeReader: Process {
        command: ["cat", root.schemePersistPath]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const saved = this.text.trim();
                if (saved === "auto" || saved === "dark" || saved === "light") {
                    root.colorScheme = saved;
                }
            }
        }
    }

    property Process schemeWriter: Process { running: false }
    property Process schemeApply: Process { running: false }

    function applyColorScheme(scheme) {
        root.colorScheme = scheme;
        schemeApply.command = ["bash",
            Quickshell.env("HOME") + "/.config/quickshell/rice/scripts/apply-color-scheme.sh",
            scheme];
        schemeApply.running = true;
    }

    property var notifications: []
    property int notificationSerial: 0
    function addNotification(summary, body, urgency) {
        const item = { id: ++notificationSerial, summary: String(summary || "Notification"), body: String(body || ""), urgency: String(urgency || "normal") };
        notifications = [item].concat(notifications).slice(0, 50);
    }
    function dismissNotification(id) { notifications = notifications.filter(item => item.id !== id); }
    function clearNotifications() { notifications = []; }
}
