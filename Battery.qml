import Quickshell
import Quickshell.Io
import QtQuick
import "." as Local

// Minimal battery readout: just "N%" plus a bolt icon when charging.
// Reads straight from /sys/class/power_supply, no upower/acpi dependency.
Item {
    id: root

    // adjust if your battery has a different name (ls /sys/class/power_supply/)
    property string batteryName: "BAT1"

    property int percentage: 0
    property bool charging: false
    property bool available: true

    readonly property string sysPath: "/sys/class/power_supply/" + batteryName

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: 3
        anchors.verticalCenter: parent.verticalCenter

        Text {
            visible: root.charging
            text: "⚡"
            color: Local.Colors.accent
            font.family: Local.Colors.fontFamily
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.available
            text: root.percentage + "%"
            color: Local.Colors.foreground
            font.family: Local.Colors.fontFamily
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Process {
        id: capacityProc
        command: ["cat", root.sysPath + "/capacity"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseInt(this.text.trim(), 10);
                if (!isNaN(n)) { root.percentage = n; root.available = true; }
            }
        }
        onExited: (exitCode) => { if (exitCode !== 0) root.available = false; }
    }

    Process {
        id: statusProc
        command: ["cat", root.sysPath + "/status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.charging = this.text.trim() === "Charging"
        }
    }

    Timer {
        interval: 30000
        running: root.available
        repeat: true
        onTriggered: { capacityProc.running = true; statusProc.running = true; }
    }
}
