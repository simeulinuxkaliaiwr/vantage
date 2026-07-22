import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "." as Local

// Full-screen wallpaper grid + big preview, vim keybinds. Separate
// from the compact picker inside BarMorph — this one is meant for a
// dedicated hotkey when you want to actually browse instead of a
// quick swap.
//
// wallpapers holds { path, thumb, isVideo } objects: video thumbs are
// extracted PNG frames (scripts/wallpaper-thumbnail.sh), cached in
// ~/.cache/quickshell-rice/wallpaper-thumbs/.
Item {
    id: selectorRoot

    property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property int cellSize: 220
    property int gap: 4
    property int columns: 4

    property var wallpapers: []
    property int selectedIndex: 0
    property bool visible_: false

    function clampIndex(i) {
        if (wallpapers.length === 0) return 0;
        if (i < 0) return 0;
        if (i >= wallpapers.length) return wallpapers.length - 1;
        return i;
    }

    function moveSelection(dx, dy, cols) {
        if (wallpapers.length === 0) return;
        let idx = selectedIndex;

        if (dy !== 0) idx = clampIndex(idx + dy * cols);
        if (dx !== 0) {
            const row = Math.floor(idx / cols);
            const col = idx % cols;
            const newCol = col + dx;
            if (newCol >= 0 && newCol < cols) idx = clampIndex(row * cols + newCol);
        }
        selectedIndex = idx;
    }

    function isVideo(path) {
        return /\.(mp4|mkv|webm|mov)$/i.test(path);
    }

    function refreshWallpaperList() { lister.running = true; }

    Process {
        id: lister
        command: ["bash", "-c",
            "THUMB='" + Quickshell.env("HOME") + "/.config/quickshell/rice/scripts/wallpaper-thumbnail.sh'; " +
            "find '" + selectorRoot.wallpaperDir + "' -maxdepth 1 -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' " +
            "-o -iname '*.mp4' -o -iname '*.mov' -o -iname '*.webm' -o -iname '*.mkv' \\) " +
            "| sort | while IFS= read -r f; do " +
            "case \"${f,,}\" in " +
            "*.mp4|*.mkv|*.webm|*.mov) t=\"$(bash \"$THUMB\" \"$f\" 2>/dev/null || true)\"; printf '%s\\t%s\\n' \"$f\" \"$t\" ;; " +
            "*) printf '%s\\t%s\\n' \"$f\" \"$f\" ;; " +
            "esac; done"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                for (const line of this.text.split("\n")) {
                    if (line.length === 0) continue;
                    const parts = line.split("\t");
                    const p = parts[0];
                    list.push({
                        path: p,
                        thumb: (parts[1] && parts[1].length > 0) ? parts[1] : p,
                        isVideo: selectorRoot.isVideo(p)
                    });
                }
                selectorRoot.wallpapers = list;
                selectorRoot.selectedIndex = selectorRoot.clampIndex(selectorRoot.selectedIndex);
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: selectorRoot.refreshWallpaperList()
    }

    onVisible_Changed: { if (visible_) refreshWallpaperList(); }

    function applyWallpaper(path) {
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/quickshell/rice/scripts/apply-wallpaper.sh", path]);
    }

    IpcHandler {
        target: "wallpaperSelector"
        function toggle(): void { Local.AppState.requestMorph("wallpaper"); }
        function open(): void { Local.AppState.requestMorph("wallpaper"); }
        function close(): void { selectorRoot.visible_ = false; }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            property var modelData
            screen: modelData

            anchors { top: true; bottom: true; left: true; right: true }
            visible: selectorRoot.visible_

            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore

            readonly property var selectedEntry:
                selectorRoot.wallpapers.length > 0
                    ? selectorRoot.wallpapers[selectorRoot.selectedIndex] || null
                    : null

            readonly property string selectedPath: selectedEntry ? selectedEntry.path : ""
            readonly property string selectedThumb: selectedEntry ? selectedEntry.thumb : ""
            readonly property bool selectedIsVideo: selectedEntry ? selectedEntry.isVideo : false

            readonly property string selectedName: {
                if (!selectedEntry) return "";
                const base = selectedEntry.path.split("/").pop();
                return base.replace(/\.[^/.]+$/, "");
            }

            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: Local.Colors.overlayOpacity

                MouseArea {
                    anchors.fill: parent
                    onClicked: selectorRoot.visible_ = false
                }
            }

            Rectangle {
                id: panel
                anchors.centerIn: parent
                width: Math.min(parent.width * 0.88, 1100)
                height: Math.min(parent.height * 0.82, 680)

                color: Local.Colors.background
                border.color: Local.Colors.accent
                border.width: Local.Colors.borderWidth
                radius: Local.Colors.radius

                MouseArea { anchors.fill: parent; onClicked: (m) => m.accepted = true }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "WALLPAPER"
                            color: Local.Colors.accent
                            font.family: Local.Colors.fontFamily
                            font.pixelSize: 13
                            font.bold: true
                            font.letterSpacing: 3
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            visible: selectorRoot.wallpapers.length > 0
                            text: (selectorRoot.selectedIndex + 1) + " / " + selectorRoot.wallpapers.length
                            color: Local.Colors.muted
                            font.family: Local.Colors.fontFamily
                            font.pixelSize: 12
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Local.Colors.accent; opacity: 0.4 }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 14

                        GridView {
                            id: grid
                            Layout.preferredWidth: panel.width * 0.42
                            Layout.fillHeight: true
                            clip: true

                            readonly property int cellSz: 130
                            readonly property int cellGap: 4
                            cellWidth: cellSz + cellGap
                            cellHeight: cellSz + cellGap

                            property int realColumns: Math.max(1, Math.floor(width / cellWidth))

                            currentIndex: selectorRoot.selectedIndex
                            highlightFollowsCurrentItem: true
                            model: selectorRoot.wallpapers

                            delegate: Item {
                                id: delegateRoot
                                width: grid.cellWidth
                                height: grid.cellHeight

                                property bool isSelected: index === selectorRoot.selectedIndex
                                property bool isHovered: thumbMouse.containsMouse

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: grid.cellGap / 2
                                    color: "#0a0a0a"
                                    radius: 18
                                    clip: true

                                    border.color: delegateRoot.isSelected
                                                  ? Local.Colors.accent
                                                  : (delegateRoot.isHovered ? Local.Colors.muted : "transparent")
                                    border.width: delegateRoot.isSelected ? Local.Colors.borderWidth : 1

                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 1
                                        source: "file://" + modelData.thumb
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: true
                                        smooth: true
                                        sourceSize.width: grid.cellSz * 2
                                        opacity: delegateRoot.isSelected ? 1.0
                                                 : (delegateRoot.isHovered ? 0.85 : 0.55)

                                        Behavior on opacity { NumberAnimation { duration: Local.Colors.animDuration } }
                                    }

                                    Rectangle {
                                        visible: modelData.isVideo
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.margins: 4
                                        width: badgeText.implicitWidth + 8
                                        height: badgeText.implicitHeight + 4
                                        color: "#000000"
                                        opacity: 0.85

                                        Text {
                                            id: badgeText
                                            anchors.centerIn: parent
                                            text: "VIDEO"
                                            color: Local.Colors.accent
                                            font.family: Local.Colors.fontFamily
                                            font.pixelSize: 8
                                            font.bold: true
                                            font.letterSpacing: 1
                                        }
                                    }

                                    Text {
                                        visible: delegateRoot.isHovered && !delegateRoot.isSelected
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        anchors.margins: 4
                                        text: index + 1
                                        color: "#ffffff"
                                        font.family: Local.Colors.fontFamily
                                        font.pixelSize: 9
                                        style: Text.Outline
                                        styleColor: "#000000"
                                    }

                                    MouseArea {
                                        id: thumbMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onEntered: selectorRoot.selectedIndex = index
                                        onClicked: {
                                            selectorRoot.applyWallpaper(modelData.path);
                                            selectorRoot.visible_ = false;
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle { Layout.fillHeight: true; width: 1; color: Local.Colors.accent; opacity: 0.3 }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 12

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "#0a0a0a"
                                border.color: Local.Colors.muted
                                border.width: 1
                                radius: Local.Colors.radius

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    source: win.selectedPath.length > 0
                                            ? "file://" + (win.selectedIsVideo ? win.selectedThumb : win.selectedPath)
                                            : ""
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    cache: false
                                    smooth: true
                                }

                                Rectangle {
                                    visible: win.selectedIsVideo
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.margins: 8
                                    width: previewBadge.implicitWidth + 12
                                    height: previewBadge.implicitHeight + 6
                                    color: "#000000"
                                    opacity: 0.85

                                    Text {
                                        id: previewBadge
                                        anchors.centerIn: parent
                                        text: "VIDEO WALLPAPER"
                                        color: Local.Colors.accent
                                        font.family: Local.Colors.fontFamily
                                        font.pixelSize: 9
                                        font.bold: true
                                        font.letterSpacing: 1
                                    }
                                }

                                Text {
                                    visible: win.selectedPath.length === 0
                                    anchors.centerIn: parent
                                    text: "no wallpaper"
                                    color: Local.Colors.muted
                                    font.family: Local.Colors.fontFamily
                                    font.pixelSize: 12
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: win.selectedName || ""
                                color: Local.Colors.foreground
                                font.family: Local.Colors.fontFamily
                                font.pixelSize: 13
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 36
                                color: Local.Colors.accent
                                radius: Local.Colors.radius

                                Text {
                                    anchors.centerIn: parent
                                    text: "APPLY  [ Enter ]"
                                    color: Local.Colors.background
                                    font.family: Local.Colors.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                    font.letterSpacing: 1
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (win.selectedPath.length > 0) {
                                            selectorRoot.applyWallpaper(win.selectedPath);
                                            selectorRoot.visible_ = false;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: "hjkl / arrows navigate   Enter apply   gg top   G bottom   q close"
                        color: Local.Colors.muted
                        font.family: Local.Colors.fontFamily
                        font.pixelSize: 10
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            Item {
                id: keyHandler
                anchors.fill: parent
                focus: selectorRoot.visible_

                Keys.onPressed: (event) => {
                    const cols = grid.realColumns;

                    switch (event.key) {
                        case Qt.Key_H: case Qt.Key_Left:
                            selectorRoot.moveSelection(-1, 0, cols); event.accepted = true; break;
                        case Qt.Key_L: case Qt.Key_Right:
                            selectorRoot.moveSelection(1, 0, cols); event.accepted = true; break;
                        case Qt.Key_K: case Qt.Key_Up:
                            selectorRoot.moveSelection(0, -1, cols); event.accepted = true; break;
                        case Qt.Key_J: case Qt.Key_Down:
                            selectorRoot.moveSelection(0, 1, cols); event.accepted = true; break;
                        case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space:
                            if (selectorRoot.wallpapers.length > 0) {
                                selectorRoot.applyWallpaper(win.selectedPath);
                                selectorRoot.visible_ = false;
                            }
                            event.accepted = true;
                            break;
                        case Qt.Key_Escape: case Qt.Key_Q:
                            selectorRoot.visible_ = false; event.accepted = true; break;
                        case Qt.Key_G:
                            if (event.modifiers & Qt.ShiftModifier)
                                selectorRoot.selectedIndex = selectorRoot.clampIndex(selectorRoot.wallpapers.length - 1);
                            else
                                selectorRoot.selectedIndex = 0;
                            event.accepted = true;
                            break;
                    }
                }
            }

            Connections {
                target: selectorRoot
                function onSelectedIndexChanged() {
                    grid.positionViewAtIndex(selectorRoot.selectedIndex, GridView.Contain);
                }
            }
        }
    }
}
