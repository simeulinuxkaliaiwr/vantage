import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "." as Local

// Floating pill bar. Doesn't span the screen — it's centered and
// narrower than the display, with real compositor blur behind it
// (see the hyprland.lua snippet in the README, layer namespace is
// "quickshell-bar").
Variants {
    id: barRoot
    model: Quickshell.screens

    PanelWindow {
        id: win
        property var modelData
        screen: modelData

        readonly property real screenWidth: modelData ? modelData.width : 1920
        readonly property real screenHeight: modelData ? modelData.height : 1080

        // window isn't anchored left+right, so wlr-layer-shell centers
        // it for us — this offset converts local coords into real
        // screen coords for BarMorph, which lives in its own window
        readonly property real narrowOffsetX: (screenWidth - implicitWidth) / 2

        readonly property bool morphActiveHere: Local.AppState.barMorph !== ""
                                                 && Local.AppState.morphScreenName === (modelData ? modelData.name : "")

        onMorphActiveHereChanged: {
            // one surface hands off to the other in the same frame,
            // no fade — the morph panel is born at the pill's exact
            // geometry, so this is invisible to the user
            if (morphActiveHere) barBg.visible = false;
        }

        Connections {
            target: Local.AppState
            function onMorphClosed(screenName) {
                if (screenName === (win.modelData ? win.modelData.name : ""))
                    barBg.visible = true;
            }
            function onMorphRequested(name) {
                if (Quickshell.screens.length > 1) {
                    const mon = Hyprland.focusedMonitor;
                    if (mon && win.modelData && mon.name !== win.modelData.name) return;
                }
                win.triggerMorph(name);
            }
        }

        function triggerMorph(name) {
            const screenName = modelData ? modelData.name : "";
            if (Local.AppState.barMorph === name && Local.AppState.morphScreenName === screenName) {
                Local.AppState.closeMorph();
                return;
            }
            const topLeft = barBg.mapToItem(null, 0, 0);
            Local.AppState.openMorph(name,
                topLeft.x + win.narrowOffsetX, topLeft.y,
                barBg.width, barBg.height,
                screenName, win.screenHeight);
        }

        anchors { top: true }
        implicitWidth: Math.min(880, screenWidth * 0.58)
        implicitHeight: Local.Colors.barHeight + 16
        color: "transparent"
        visible: Local.AppState.showBar

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-bar"
        exclusionMode: ExclusionMode.Auto

        Rectangle {
            id: barBg
            anchors.fill: parent
            anchors.topMargin: 8
            anchors.bottomMargin: 8

            opacity: Local.AppState.barTemporarilyHidden ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.InOutQuad } }

            radius: height / 2

            // barely-there fill — the actual "glass" look comes from
            // real compositor blur, not a fake dark overlay
            color: Qt.rgba(Local.Colors.background.r, Local.Colors.background.g,
                            Local.Colors.background.b, 0.14)
            border.color: Local.Colors.accent
            border.width: 1

            RowLayout {
                id: barRow
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                spacing: 0

                // -- left: workspaces --
                Item {
                    Layout.preferredWidth: barRow.sideWidth
                    Layout.fillHeight: true

                    Item {
                        id: workspaces
                        anchors.verticalCenter: parent.verticalCenter

                        readonly property int cellWidth: 26
                        readonly property int cellHeight: 22
                        readonly property int cellSpacing: 2
                        readonly property int unit: cellWidth + cellSpacing
                        width: 9 * unit - cellSpacing
                        height: cellHeight

                        readonly property int activeIndex: (Hyprland.focusedWorkspace?.id ?? 1) - 1

                        property int previousIndex: 0
                        Component.onCompleted: previousIndex = activeIndex

                        property real blobX: activeIndex * unit
                        property real blobWidth: cellWidth

                        onActiveIndexChanged: {
                            const from = previousIndex;
                            const to = activeIndex;
                            previousIndex = to;

                            const fromX = from * unit;
                            const toX = to * unit;

                            blobTransition.spanX = Math.min(fromX, toX);
                            blobTransition.spanWidth = Math.abs(toX - fromX) + cellWidth;
                            blobTransition.settleX = toX;
                            blobTransition.stop();
                            blobTransition.start();
                        }

                        SequentialAnimation {
                            id: blobTransition
                            property real spanX: 0
                            property real spanWidth: workspaces.cellWidth
                            property real settleX: 0

                            ParallelAnimation {
                                NumberAnimation { target: workspaces; property: "blobX"; to: blobTransition.spanX; duration: 140; easing.type: Easing.OutQuad }
                                NumberAnimation { target: workspaces; property: "blobWidth"; to: blobTransition.spanWidth; duration: 140; easing.type: Easing.OutQuad }
                            }
                            ParallelAnimation {
                                NumberAnimation { target: workspaces; property: "blobX"; to: blobTransition.settleX; duration: 180; easing.type: Easing.InOutQuad }
                                NumberAnimation { target: workspaces; property: "blobWidth"; to: workspaces.cellWidth; duration: 180; easing.type: Easing.InOutQuad }
                            }
                        }

                        Rectangle {
                            x: workspaces.blobX
                            width: workspaces.blobWidth
                            height: workspaces.cellHeight
                            radius: height / 2
                            color: Qt.rgba(1, 1, 1, 0.92)
                        }

                        Row {
                            spacing: workspaces.cellSpacing

                            Repeater {
                                model: 9
                                Item {
                                    width: workspaces.cellWidth
                                    height: workspaces.cellHeight

                                    property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                                    readonly property bool isActive: index === workspaces.activeIndex

                                    Text {
                                        anchors.centerIn: parent
                                        text: index + 1
                                        font.family: Local.Colors.fontFamily
                                        font.pixelSize: 12
                                        font.bold: isActive
                                        color: isActive ? "#101018" : Local.Colors.foreground
                                        opacity: isActive ? 1.0 : (ws ? 0.85 : 0.35)
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: Hyprland.dispatch("workspace " + (index + 1))
                                    }
                                }
                            }
                        }
                    }
                }

                // -- center: clock --
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        id: clockCenter
                        anchors.centerIn: parent
                        color: Local.Colors.foreground
                        font.family: Local.Colors.fontFamily
                        font.pixelSize: 13
                        font.bold: true

                        property string currentTime: Qt.formatDateTime(new Date(), "h:mm AP")
                        text: currentTime

                        Timer {
                            interval: 1000 * 15
                            running: true
                            repeat: true
                            onTriggered: clockCenter.currentTime = Qt.formatDateTime(new Date(), "h:mm AP")
                        }

                    }
                }

                // -- right: icon cluster, each one morphs the bar --
                Item {
                    Layout.preferredWidth: barRow.sideWidth
                    Layout.fillHeight: true

                    Row {
                        id: cluster
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        spacing: 4

                        Repeater {
                            model: [
                                { glyph: "\uf078", morph: "quicksettings" },
                                { glyph: "\uf108", morph: "wallpaper" },
                                { glyph: "\uf53f", morph: "colorscheme" },
                                { glyph: "\uf028", morph: "volume" },
                                { glyph: "\uf293", morph: "bluetooth" },
                                { glyph: "\uf0f3", morph: "notifications" },
                                { glyph: "\uf011", morph: "power" }
                            ]

                            Rectangle {
                                id: clusterBtn
                                width: 30
                                height: 26
                                radius: height / 2
                                color: (Local.AppState.barMorph === modelData.morph
                                        && Local.AppState.morphScreenName === (win.modelData ? win.modelData.name : ""))
                                       ? Qt.rgba(1, 1, 1, 0.20)
                                       : hoverArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"

                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.glyph
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 13
                                    color: Local.Colors.foreground
                                }

                                MouseArea {
                                    id: hoverArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: win.triggerMorph(modelData.morph)
                                }
                            }
                        }
                    }
                }

                property real sideWidth: 220
            }
        }
    }
}
