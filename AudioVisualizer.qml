import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "." as Local

// cava-driven bar visualizer along the bottom edge. Stops well
// short of BigClock's position so the two never overlap even at
// full amplitude.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        property var modelData
        screen: modelData

        anchors { bottom: true; left: true; right: true }
        margins { bottom: 0 }

        readonly property int numBars: 64
        readonly property int maxRange: 100
        readonly property int maxHeight: 220
        readonly property int barSpacing: 4

        readonly property real barWidth: Math.max(1, (width - (numBars - 1) * barSpacing) / numBars)

        implicitHeight: maxHeight

        color: "transparent"
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}
        visible: Local.AppState.showDesktopWidgets

        property var bars: {
            const a = [];
            for (let i = 0; i < numBars; ++i) a.push(0);
            return a;
        }

        Process {
            id: cavaProc
            command: ["cava", "-p", Quickshell.env("HOME") + "/.config/cava/cava-config-rice"]
            running: true
            onRunningChanged: if (!running) running = true

            stdout: SplitParser {
                onRead: (data) => {
                    if (!data || data.trim().length === 0) return;
                    const parts = data.trim().split(";");
                    const newBars = [];
                    for (let i = 0; i < parts.length; ++i) {
                        const v = parseInt(parts[i], 10);
                        newBars.push(isNaN(v) ? 0 : Math.max(0, Math.min(win.maxRange, v)));
                    }
                    while (newBars.length < win.numBars) newBars.push(0);
                    win.bars = newBars.slice(0, win.numBars);
                }
            }
        }

        Row {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: win.barSpacing

            Repeater {
                model: win.numBars

                Item {
                    width: win.barWidth
                    height: win.maxHeight

                    readonly property real value: win.bars[index] / win.maxRange
                    readonly property int barH: Math.round(value * win.maxHeight)

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: parent.barH
                        radius: width / 2

                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Local.Colors.accent2 }
                            GradientStop { position: 1.0; color: Local.Colors.accent }
                        }

                        Behavior on height {
                            enabled: Local.Colors.animationsEnabled
                            NumberAnimation { duration: 60 }
                        }
                    }

                    Rectangle {
                        visible: parent.barH > 4
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.min(24, parent.barH * 0.25)
                        radius: width / 2
                        color: Local.Colors.accent
                        opacity: 0.18
                    }
                }
            }
        }
    }
}
