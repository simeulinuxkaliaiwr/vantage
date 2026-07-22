import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import "." as Local

// Bottom-right desktop clock, translucent card + a progress bar
// under it that fills up with the current minute's seconds.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        property var modelData
        screen: modelData

        anchors { bottom: true; right: true }
        margins { bottom: 60; right: 20 }

        implicitWidth: content.implicitWidth + 4
        implicitHeight: content.implicitHeight

        color: "transparent"
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}
        visible: Local.AppState.showDesktopWidgets

        property string hoursMinutes: ""
        property string seconds: ""
        property string dateStr: ""

        function updateClock() {
            const now = new Date();
            win.hoursMinutes = Qt.formatDateTime(now, "hh:mm");
            win.seconds = Qt.formatDateTime(now, "ss");
            win.dateStr = Qt.formatDateTime(now, "ddd, dd MMM yyyy");
        }

        Component.onCompleted: updateClock()

        Timer { interval: 1000; running: true; repeat: true; onTriggered: win.updateClock() }

        Rectangle {
            id: content
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            implicitWidth: col.implicitWidth + 48
            implicitHeight: col.implicitHeight + 32
            radius: 18
            color: Qt.rgba(Local.Colors.background.r, Local.Colors.background.g,
                           Local.Colors.background.b, 0.55)
            border.color: Local.Colors.accent
            border.width: 1

            Column {
                id: col
                anchors.centerIn: parent
                spacing: 6

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6

                    Text {
                        id: timeText
                        text: win.hoursMinutes
                        color: Local.Colors.foreground
                        font.family: Local.Colors.fontFamily
                        font.pixelSize: 56
                        font.weight: Font.Light
                    }

                    Text {
                        anchors.baseline: timeText.baseline
                        text: win.seconds
                        color: Local.Colors.accent
                        font.family: Local.Colors.fontFamily
                        font.pixelSize: 24
                        font.weight: Font.Light
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: win.dateStr
                    color: Local.Colors.muted
                    font.family: Local.Colors.fontFamily
                    font.pixelSize: 14
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: col.implicitWidth
                    height: 3
                    radius: 2
                    color: Qt.rgba(Local.Colors.muted.r, Local.Colors.muted.g, Local.Colors.muted.b, 0.3)

                    Rectangle {
                        anchors.left: parent.left
                        height: parent.height
                        radius: 2
                        width: parent.width * (parseInt(win.seconds, 10) / 59)
                        color: Local.Colors.accent

                        Behavior on width {
                            enabled: Local.Colors.animationsEnabled
                            NumberAnimation { duration: 300 }
                        }
                    }
                }
            }
        }
    }
}
