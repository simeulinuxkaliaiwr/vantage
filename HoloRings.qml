import Quickshell
import Quickshell.Wayland
import QtQuick
import "." as Local

// Purely decorative rotating rings widget for the top-left corner.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        property var modelData
        screen: modelData
        anchors { top: true; left: true }
        margins { top: 80; left: 60 }
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell-holorings"
        exclusionMode: ExclusionMode.Ignore
        visible: Local.AppState.showDesktopWidgets

        implicitWidth: 220
        implicitHeight: 220

        Repeater {
            model: 3
            delegate: Rectangle {
                anchors.centerIn: parent
                width: 200 - index * 52
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(Local.Colors.accent.r, Local.Colors.accent.g,
                                      Local.Colors.accent.b, 0.55 - index * 0.12)

                Rectangle {
                    width: 7; height: 7; radius: 3.5
                    color: index % 2 === 0 ? Local.Colors.accent : Local.Colors.accent2
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: -3
                }

                RotationAnimation on rotation {
                    loops: Animation.Infinite
                    from: index % 2 === 0 ? 0 : 360
                    to: index % 2 === 0 ? 360 : 0
                    duration: 9000 + index * 5000
                }
            }
        }

        Rectangle {
            id: core
            anchors.centerIn: parent
            width: 26; height: 26; radius: 13
            color: Qt.rgba(Local.Colors.accent.r, Local.Colors.accent.g, Local.Colors.accent.b, 0.30)
            border.width: 1
            border.color: Local.Colors.accent

            SequentialAnimation on scale {
                loops: Animation.Infinite
                NumberAnimation { to: 1.35; duration: 1400; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0;  duration: 1400; easing.type: Easing.InOutSine }
            }
        }

        Text {
            anchors { top: core.bottom; horizontalCenter: parent.horizontalCenter; topMargin: 66 }
            text: "// NEURAL LINK ACTIVE"
            color: Local.Colors.accent2
            font { pixelSize: 9; letterSpacing: 3; family: Local.Colors.fontFamily }
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 1600 }
                NumberAnimation { to: 1.0; duration: 1600 }
            }
        }
    }
}
