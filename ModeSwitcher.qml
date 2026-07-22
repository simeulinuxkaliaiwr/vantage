import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "." as Local

// Popup for the rice's visual mode.
//   normal  — everything visible (bar + desktop widgets)
//   minimal — bar only
//   cinema  — wallpaper only, nothing else
Item {
    id: root

    property bool visible_: false
    property int selectedIndex: 0

    readonly property var modes: [
        { id: "normal",  icon: "▣", label: "NORMAL",  desc: "Bar + widgets" },
        { id: "minimal", icon: "▬", label: "MINIMAL", desc: "Bar only" },
        { id: "cinema",  icon: "□", label: "CINEMA",  desc: "Wallpaper only" }
    ]

    function currentModeIndex() {
        for (let i = 0; i < modes.length; ++i) if (modes[i].id === Local.AppState.mode) return i;
        return 0;
    }

    onVisible_Changed: { if (visible_) selectedIndex = currentModeIndex(); }

    function applyMode(index) {
        Local.AppState.mode = modes[index].id;
        root.visible_ = false;
    }

    IpcHandler {
        target: "modeSwitcher"
        function toggle(): void { root.visible_ = !root.visible_; }
        function open(): void { root.visible_ = true; }
        function close(): void { root.visible_ = false; }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            property var modelData
            screen: modelData

            anchors { top: true; bottom: true; left: true; right: true }
            visible: root.visible_

            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore

            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: 0.82
                MouseArea { anchors.fill: parent; onClicked: root.visible_ = false }
            }

            Rectangle {
                id: panel
                anchors.centerIn: parent
                width: 320
                height: column.implicitHeight + 32

                color: Local.Colors.background
                border.color: Local.Colors.accent
                border.width: Local.Colors.borderWidth
                radius: Local.Colors.radius

                MouseArea { anchors.fill: parent; onClicked: (mouse) => mouse.accepted = true }

                ColumnLayout {
                    id: column
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16
                    spacing: 12

                    Text {
                        text: "VISUAL MODE"
                        color: Local.Colors.foreground
                        font.family: Local.Colors.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                        font.letterSpacing: 2
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Local.Colors.muted }

                    Repeater {
                        model: root.modes

                        Rectangle {
                            id: modeCell
                            Layout.fillWidth: true
                            height: 54
                            radius: Local.Colors.radius

                            property bool isSelected: index === root.selectedIndex
                            property bool isActive: modelData.id === Local.AppState.mode

                            color: isSelected ? Local.Colors.accent : "transparent"
                            border.color: isActive && !isSelected ? Local.Colors.accent : "transparent"
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 14

                                Text {
                                    text: modelData.icon
                                    color: modeCell.isSelected ? Local.Colors.background : Local.Colors.accent
                                    font.family: Local.Colors.fontFamily
                                    font.pixelSize: 22
                                    font.bold: true
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: modelData.label
                                        color: modeCell.isSelected ? Local.Colors.background : Local.Colors.foreground
                                        font.family: Local.Colors.fontFamily
                                        font.pixelSize: 13
                                        font.bold: true
                                    }

                                    Text {
                                        text: modelData.desc
                                        color: modeCell.isSelected ? Local.Colors.background : Local.Colors.muted
                                        font.family: Local.Colors.fontFamily
                                        font.pixelSize: 10
                                    }
                                }

                                Text {
                                    visible: modeCell.isActive
                                    text: "●"
                                    color: modeCell.isSelected ? Local.Colors.background : Local.Colors.accent
                                    font.family: Local.Colors.fontFamily
                                    font.pixelSize: 10
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: root.selectedIndex = index
                                onClicked: root.applyMode(index)
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "↑↓ / k·j navigate   Enter confirm   Esc cancel"
                        color: Local.Colors.muted
                        font.family: Local.Colors.fontFamily
                        font.pixelSize: 10
                    }
                }
            }

            Item {
                anchors.fill: parent
                focus: root.visible_

                Keys.onPressed: (event) => {
                    switch (event.key) {
                        case Qt.Key_K: case Qt.Key_Up:
                            root.selectedIndex = Math.max(0, root.selectedIndex - 1); event.accepted = true; break;
                        case Qt.Key_J: case Qt.Key_Down:
                            root.selectedIndex = Math.min(root.modes.length - 1, root.selectedIndex + 1); event.accepted = true; break;
                        case Qt.Key_Return: case Qt.Key_Enter:
                            root.applyMode(root.selectedIndex); event.accepted = true; break;
                        case Qt.Key_Escape: case Qt.Key_Q:
                            root.visible_ = false; event.accepted = true; break;
                        case Qt.Key_1: root.applyMode(0); event.accepted = true; break;
                        case Qt.Key_2: root.applyMode(1); event.accepted = true; break;
                        case Qt.Key_3: root.applyMode(2); event.accepted = true; break;
                    }
                }
            }
        }
    }
}
