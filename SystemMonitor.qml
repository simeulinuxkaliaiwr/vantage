import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "." as Local

// CPU/memory/battery glass card, top-right of the desktop.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        property var modelData
        screen: modelData
        anchors { top: true; right: true }
        margins { top: 60; right: 28 }
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell-sysinfo"
        exclusionMode: ExclusionMode.Ignore
        visible: Local.AppState.showDesktopWidgets

        implicitWidth: 300
        implicitHeight: panel.implicitHeight + 40

        property real cpuUsage: 0
        property real memUsage: 0
        property real batLevel: 0
        property bool batCharging: false
        property bool batPresent: false
        property double prevIdle: 0
        property double prevTotal: 0

        function parseStats(text) {
            const lines = text.trim().split("\n");
            let memTotal = 1, memAvail = 1;
            for (const line of lines) {
                if (line.startsWith("cpu ")) {
                    const v = line.split(/\s+/).slice(1).map(Number);
                    const idle = v[3] + v[4];
                    const total = v.reduce((a, b) => a + b, 0);
                    if (prevTotal > 0 && total > prevTotal)
                        cpuUsage = 1 - (idle - prevIdle) / (total - prevTotal);
                    prevIdle = idle; prevTotal = total;
                } else if (line.startsWith("BATCAP")) {
                    const v = Number(line.split(/\s+/)[1]);
                    if (!isNaN(v)) { batLevel = v / 100; batPresent = true; }
                } else if (line.startsWith("BATST")) {
                    batCharging = line.indexOf("Charging") >= 0;
                } else if (line.startsWith("MemTotal:")) {
                    memTotal = Number(line.split(/\s+/)[1]);
                } else if (line.startsWith("MemAvailable:")) {
                    memAvail = Number(line.split(/\s+/)[1]);
                }
            }
            memUsage = 1 - memAvail / memTotal;
        }

        Process {
            id: statProc
            command: ["bash", "-c", "grep -m1 '^cpu ' /proc/stat; grep -E '^Mem(Total|Available):' /proc/meminfo; echo BATCAP $(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1); echo BATST $(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1)"]
            stdout: StdioCollector { onStreamFinished: win.parseStats(text) }
        }
        Timer {
            interval: 2000; repeat: true; running: win.visible
            triggeredOnStart: true
            onTriggered: statProc.running = true
        }

        Rectangle {
            anchors.fill: panel
            anchors.margins: -18
            radius: 18
            color: Qt.rgba(Local.Colors.background.r, Local.Colors.background.g, Local.Colors.background.b, 0.5)
            border.width: 1
            border.color: Qt.rgba(Local.Colors.accent.r, Local.Colors.accent.g, Local.Colors.accent.b, 0.55)

            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                anchors.margins: 1
                height: parent.height * 0.4
                radius: 17
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#22ffffff" }
                    GradientStop { position: 1.0; color: "#00ffffff" }
                }
            }
            Rectangle {
                id: scanline
                anchors { left: parent.left; right: parent.right }
                anchors.margins: 2
                height: 1
                color: Local.Colors.accent
                opacity: 0.5
                SequentialAnimation on y {
                    loops: Animation.Infinite
                    NumberAnimation { from: 4; to: scanline.parent.height - 4; duration: 3600 }
                    NumberAnimation { from: scanline.parent.height - 4; to: 4; duration: 3600 }
                }
            }
        }

        Column {
            id: panel
            anchors.centerIn: parent
            width: 250
            spacing: 12

            Row {
                spacing: 8
                Rectangle {
                    width: 8; height: 8; radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: Local.Colors.accent
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.2; duration: 900 }
                        NumberAnimation { to: 1.0; duration: 900 }
                    }
                }
                Text {
                    text: "SYS://MONITOR"
                    color: Local.Colors.accent
                    font { pixelSize: 13; bold: true; letterSpacing: 3; family: Local.Colors.fontFamily }
                }
            }

            Repeater {
                model: win.batPresent
                    ? [ { name: "CPU", value: win.cpuUsage },
                        { name: "MEM", value: win.memUsage },
                        { name: win.batCharging ? "BAT \u26a1" : "BAT", value: win.batLevel } ]
                    : [ { name: "CPU", value: win.cpuUsage },
                        { name: "MEM", value: win.memUsage } ]
                delegate: Column {
                    width: parent.width
                    spacing: 3
                    Row {
                        width: parent.width
                        Text {
                            text: modelData.name
                            color: Local.Colors.foreground
                            font { pixelSize: 11; letterSpacing: 2; family: Local.Colors.fontFamily }
                            width: parent.width - percent.width
                        }
                        Text {
                            id: percent
                            text: Math.round(modelData.value * 100) + "%"
                            color: Local.Colors.accent2
                            font { pixelSize: 11; family: Local.Colors.fontFamily }
                        }
                    }
                    Rectangle {
                        width: parent.width; height: 6; radius: 3
                        color: Qt.rgba(1, 1, 1, 0.08)
                        Rectangle {
                            width: parent.width * Math.max(0.02, Math.min(1, modelData.value))
                            height: parent.height; radius: 3
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Local.Colors.accent }
                                GradientStop { position: 1.0; color: Local.Colors.accent2 }
                            }
                            Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }
        }
    }
}
