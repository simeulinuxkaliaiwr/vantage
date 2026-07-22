import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "." as Local

Item {
    id: root

    IpcHandler {
        target: "notifications"
        function notify(summary: string, body: string, urgency: string) { Local.AppState.addNotification(summary, body, urgency); }
        function clear() { Local.AppState.clearNotifications(); }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData

            anchors { top: true; right: true }
            margins { top: 56; right: 18 }

            implicitWidth: 360
            implicitHeight: stack.implicitHeight
            color: "transparent"
            visible: Local.AppState.notifications.length > 0

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-notifications"
            exclusionMode: ExclusionMode.Ignore

            Column {
                id: stack
                width: parent.width
                spacing: 8

                Repeater {
                    model: Local.AppState.notifications.slice(0, 3)

                    delegate: Rectangle {
                        width: stack.width
                        height: 68
                        radius: 16
                        color: Qt.rgba(Local.Colors.background.r, Local.Colors.background.g, Local.Colors.background.b, .90)
                        border.width: 1
                        border.color: modelData.urgency === "critical" ? "#ff5555" : Local.Colors.accent

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10

                            Text {
                                width: parent.width
                                text: modelData.summary
                                color: Local.Colors.foreground
                                font.bold: true
                                elide: Text.ElideRight
                                font.family: Local.Colors.fontFamily
                            }

                            Text {
                                width: parent.width
                                text: modelData.body
                                color: Local.Colors.muted
                                elide: Text.ElideRight
                                visible: text.length > 0
                                font.family: Local.Colors.fontFamily
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: Local.AppState.dismissNotification(modelData.id)
                        }
                    }
                }
            }
        }
    }
}
