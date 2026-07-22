import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "." as Local

// auto/dark/light popup — re-runs pywal against the current wallpaper
// with the -l flag and repropagates colors everywhere.
Item {
    id: root

    property bool visible_: false
    property int selectedIndex: 0

    readonly property var schemes: [
        { id: "auto",  icon: "◐", label: "AUTO",  desc: "Detect from wallpaper luminance" },
        { id: "dark",  icon: "●", label: "DARK",  desc: "Always dark" },
        { id: "light", icon: "○", label: "LIGHT", desc: "Always light" }
    ]

    function currentSchemeIndex() {
        for (let i = 0; i < schemes.length; ++i) if (schemes[i].id === Local.AppState.colorScheme) return i;
        return 0;
    }

    onVisible_Changed: { if (visible_) selectedIndex = currentSchemeIndex(); }

    function applyScheme(index) {
        Local.AppState.applyColorScheme(schemes[index].id);
        root.visible_ = false;
    }

    IpcHandler {
        target: "colorScheme"
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

                MouseArea { anchors.fill: parent; onClicked: (m) => m.accepted = true }

                ColumnLayout {
                    id: column
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "COLOR SCHEME"
                            color: Local.Colors.foreground
                            font.family: Local.Colors.fontFamily
                            font.pixelSize: 14
                            font.bold: true
                            font.letterSpacing: 2
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "Esc cancels"
                            color: Local.Colors.muted
                            font.family: Local.Colors.fontFamily
                            font.pixelSize: 10
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Local.Colors.muted }

                    Repeater {
                        model: root.schemes

                        Rectangle {
                            id: cell
                            Layout.fillWidth: true
                            height: 54
                            radius: Local.Colors.radius

                            property bool isSelected: index === root.selectedIndex
                            property bool isActive: modelData.id === Local.AppState.colorScheme

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
                                    color: cell.isSelected ? Local.Colors.background : Local.Colors.accent
                                    font.family: Local.Colors.fontFamily
                                    font.pixelSize: 22
                                    font.bold: true
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: modelData.label
                                        color: cell.isSelected ? Local.Colors.background : Local.Colors.foreground
                                        font.family: Local.Colors.fontFamily
                                        font.pixelSize: 13
                                        font.bold: true
                                    }

                                    Text {
                                        text: modelData.desc
                                        color: cell.isSelected ? Local.Colors.background : Local.Colors.muted
                                        font.family: Local.Colors.fontFamily
                                        font.pixelSize: 10
                                    }
                                }

                                Text {
                                    visible: cell.isActive
                                    text: "●"
                                    color: cell.isSelected ? Local.Colors.background : Local.Colors.accent
                                    font.family: Local.Colors.fontFamily
                                    font.pixelSize: 10
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: root.selectedIndex = index
                                onClicked: root.applyScheme(index)
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "↑↓ / k·j navigate   Enter confirm   1·2·3 shortcut"
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
                            root.selectedIndex = Math.min(root.schemes.length - 1, root.selectedIndex + 1); event.accepted = true; break;
                        case Qt.Key_Return: case Qt.Key_Enter:
                            root.applyScheme(root.selectedIndex); event.accepted = true; break;
                        case Qt.Key_Escape: case Qt.Key_Q:
                            root.visible_ = false; event.accepted = true; break;
                        case Qt.Key_1: root.applyScheme(0); event.accepted = true; break;
                        case Qt.Key_2: root.applyScheme(1); event.accepted = true; break;
                        case Qt.Key_3: root.applyScheme(2); event.accepted = true; break;
                    }
                }
            }
        }
    }
}
