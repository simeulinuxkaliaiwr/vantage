import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "." as Local

// Panel that grows out of a tiny point where the bar pill was,
// rather than just popping open on top of it. Sequence:
//   1. Bar.qml shrinks the pill down to a 6x6 dot (scale animation)
//   2. this panel is born at that same dot and grows to full size
// Closing reverses the sequence. Two separate surfaces, but the
// transition reads as one continuous shape.
//
// Shares the "quickshell-bar" namespace with Bar.qml so it reuses
// the same blur layer_rule from hyprland.lua.
//
// Status: power, volume, wallpaper, colorscheme, launcher and
// clipboard are fully wired up. bluetooth/notifications/quicksettings
// are still stubs (layout only, no backend yet).
//
// The "lock" action in the power menu assumes hyprlock is installed —
// swap the command string in powerContent if you use something else.

Item {
    id: root

    function targetSize(name, screenWidth) {
        switch (name) {
            case "power":       return { w: 300, h: 100 };
            case "wallpaper":   return { w: Math.min(screenWidth * 0.5, 720), h: 118 };
            case "volume":      return { w: 300, h: 96 };
            case "colorscheme": return { w: Math.min(screenWidth * 0.52, 760), h: 132 };
            case "launcher":    return { w: 600, h: 380 };
            case "clipboard":   return { w: 560, h: 380 };
            default:            return { w: 280, h: 90 };
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            property var modelData
            screen: modelData

            readonly property bool onThisScreen: Local.AppState.morphScreenName === (modelData ? modelData.name : "")
            readonly property bool active: Local.AppState.barMorph !== "" && onThisScreen
            readonly property var target: root.targetSize(Local.AppState.barMorph, modelData ? modelData.width : 1920)

            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-bar"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: (win.active && (Local.AppState.barMorph === "launcher"
                                          || Local.AppState.barMorph === "clipboard"
                                          || Local.AppState.barMorph === "wallpaper"))
                                         ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            visible: win.active || closeAnim.running

            property real panelX: Local.AppState.morphOriginX
            property real panelY: Local.AppState.morphOriginY
            property real panelW: Local.AppState.morphOriginWidth
            property real panelH: Local.AppState.morphOriginHeight
            property string displayedMorph: ""
            onActiveChanged: {
                if (active) {
                    displayedMorph = Local.AppState.barMorph;
                    panelX = Local.AppState.morphOriginX;
                    panelY = Local.AppState.morphOriginY;
                    panelW = Local.AppState.morphOriginWidth;
                    panelH = Local.AppState.morphOriginHeight;
                    closeAnim.stop();
                    growAnim.stop();
                    growAnim.start();
                } else {
                    growAnim.stop();
                    closeAnim.start();
                }
            }

            ParallelAnimation {
                id: growAnim
                NumberAnimation {
                    target: win; property: "panelX"
                    to: Local.AppState.morphOriginX - (win.target.w - Local.AppState.morphOriginWidth) / 2
                    duration: 320; easing.type: Easing.OutQuint
                }
                NumberAnimation { target: win; property: "panelW"; to: win.target.w; duration: 320; easing.type: Easing.OutQuint }
                NumberAnimation { target: win; property: "panelH"; to: win.target.h; duration: 320; easing.type: Easing.OutQuint }
            }

            SequentialAnimation {
                id: closeAnim
                ParallelAnimation {
                    NumberAnimation { target: win; property: "panelX"; to: Local.AppState.morphOriginX; duration: 620; easing.type: Easing.InOutCubic }
                    NumberAnimation { target: win; property: "panelW"; to: Local.AppState.morphOriginWidth; duration: 620; easing.type: Easing.InOutCubic }
                    NumberAnimation { target: win; property: "panelH"; to: Local.AppState.morphOriginHeight; duration: 620; easing.type: Easing.InOutCubic }
                }
                ScriptAction { script: Local.AppState.morphClosed(Local.AppState.morphScreenName) }
            }

            MouseArea {
                anchors.fill: parent
                enabled: win.active
                onClicked: Local.AppState.closeMorph()
            }

            Rectangle {
                id: panel
                x: win.panelX
                y: win.panelY
                width: Math.max(4, win.panelW)
                height: Math.max(4, win.panelH)
                radius: Math.min(height / 2, 20)
                clip: true

                color: Qt.rgba(Local.Colors.background.r, Local.Colors.background.g,
                               Local.Colors.background.b, 0.22)
                border.color: Local.Colors.accent
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    onClicked: (mouse) => mouse.accepted = true
                }

                readonly property real growFrac: {
                    const originW = Local.AppState.morphOriginWidth;
                    const span = win.target.w - originW;
                    if (span <= 0) return 1;
                    return Math.max(0, Math.min(1, (win.panelW - originW) / span));
                }

                Loader {
                    id: contentLoader
                    anchors.fill: parent
                    anchors.margins: 12
                    active: win.active || closeAnim.running
                    opacity: Math.max(0, Math.min(1, (panel.growFrac - 0.35) / 0.65))
                    sourceComponent: {
                        switch (win.displayedMorph) {
                            case "power":     return powerContent;
                            case "wallpaper": return wallpaperContent;
                            case "volume":    return volumeContent;
                            case "colorscheme": return colorschemeContent;
                            case "launcher":    return launcherContent;
                            case "clipboard":   return clipboardContent;
                            case "notifications": return notificationContent;
                            default: return stubContent;
                        }
                    }
                }
            }

            Component {
                id: colorschemeContent
                Column {
                    id: csRoot
                    anchors.fill: parent
                    spacing: 8

                    readonly property var schemes: [
                        { name: "auto",             colors: [] },
                        { name: "gruvbox",          colors: ["#282828","#cc241d","#98971a","#d79921","#458588","#b16286","#689d6a","#ebdbb2"] },
                        { name: "catppuccin mocha", colors: ["#1e1e2e","#f38ba8","#a6e3a1","#f9e2af","#89b4fa","#cba6f7","#94e2d5","#cdd6f4"] },
                        { name: "rose pine",        colors: ["#191724","#eb6f92","#31748f","#f6c177","#9ccfd8","#c4a7e7","#ebbcba","#e0def4"] },
                        { name: "nord",             colors: ["#2e3440","#bf616a","#a3be8c","#ebcb8b","#81a1c1","#b48ead","#88c0d0","#e5e9f0"] },
                        { name: "tokyo night",      colors: ["#1a1b26","#f7768e","#9ece6a","#e0af68","#7aa2f7","#bb9af7","#7dcfff","#c0caf5"] },
                        { name: "dracula",          colors: ["#282a36","#ff5555","#50fa7b","#f1fa8c","#bd93f9","#ff79c6","#8be9fd","#f8f8f2"] }
                    ]

                    Text {
                        text: "Color scheme"
                        color: Local.Colors.foreground
                        font.family: Local.Colors.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Flickable {
                        width: parent.width
                        height: parent.height - 24
                        contentWidth: csRow.implicitWidth
                        contentHeight: height
                        flickableDirection: Flickable.HorizontalFlick
                        clip: true

                        Row {
                            id: csRow
                            spacing: 10
                            height: parent.height

                            Repeater {
                                model: csRoot.schemes
                                Column {
                                    readonly property var scheme: modelData
                                    spacing: 3
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        width: 116; height: 56
                                        radius: 26
                                        clip: true
                                        color: "transparent"
                                        border.width: csMouse.containsMouse ? 2 : 1
                                        border.color: csMouse.containsMouse ? Local.Colors.accent : Local.Colors.muted
                                        Behavior on border.color { ColorAnimation { duration: 120 } }

                                        Row {
                                            id: stripeRow
                                            anchors.fill: parent
                                            anchors.margins: 2
                                            readonly property var stripes: scheme.colors.length > 0
                                                ? scheme.colors
                                                : [Local.Colors.palette[0], Local.Colors.palette[1],
                                                   Local.Colors.palette[2], Local.Colors.palette[3],
                                                   Local.Colors.palette[4], Local.Colors.palette[5],
                                                   Local.Colors.palette[6], Local.Colors.palette[7]]
                                            Repeater {
                                                model: stripeRow.stripes
                                                Rectangle {
                                                    width: stripeRow.width / stripeRow.stripes.length
                                                    height: stripeRow.height
                                                    color: modelData
                                                }
                                            }
                                        }

                                        Rectangle {
                                            visible: scheme.name === "auto"
                                            anchors.centerIn: parent
                                            width: autoTxt.implicitWidth + 12
                                            height: autoTxt.implicitHeight + 4
                                            radius: height / 2
                                            color: Qt.rgba(0, 0, 0, 0.55)
                                            Text {
                                                id: autoTxt
                                                anchors.centerIn: parent
                                                text: "wallpaper"
                                                color: "#ffffff"
                                                font.family: Local.Colors.fontFamily
                                                font.pixelSize: 9
                                            }
                                        }

                                        MouseArea {
                                            id: csMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                Local.AppState.closeMorph();
                                                Quickshell.execDetached(["bash",
                                                    Quickshell.env("HOME") + "/.config/quickshell/rice/scripts/apply-colorscheme-preset.sh",
                                                    scheme.name]);
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: scheme.name
                                        color: Local.Colors.muted
                                        font.family: Local.Colors.fontFamily
                                        font.pixelSize: 9
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Component {
                id: launcherContent
                Item {
                    id: laRoot
                    anchors.fill: parent
                    property string query: ""
                    property int selIndex: 0

                    readonly property var apps: {
                        const all = [...DesktopEntries.applications.values].filter(d => d.name);
                        all.sort((a, b) => a.name.localeCompare(b.name));
                        const q = query.trim().toLowerCase();
                        if (q === "") return all;
                        return all.filter(d => (d.name || "").toLowerCase().includes(q)
                                            || (d.comment || "").toLowerCase().includes(q));
                    }
                    onQueryChanged: selIndex = 0

                    Column {
                        anchors.fill: parent
                        spacing: 8

                        Rectangle {
                            width: parent.width
                            height: 34
                            radius: height / 2
                            color: Qt.rgba(1, 1, 1, 0.08)
                            border.color: Local.Colors.accent
                            border.width: 1

                            TextInput {
                                id: laInput
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                verticalAlignment: TextInput.AlignVCenter
                                color: Local.Colors.foreground
                                font.family: Local.Colors.fontFamily
                                font.pixelSize: 13
                                clip: true
                                onTextChanged: laRoot.query = text
                                Component.onCompleted: forceActiveFocus()

                                Keys.onPressed: (event) => {
                                    if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                                        laRoot.selIndex = Math.min(laRoot.selIndex + 1, laRoot.apps.length - 1);
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                                        laRoot.selIndex = Math.max(0, laRoot.selIndex - 1);
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        const raw = laRoot.query.trim();
                                        if (raw.startsWith(">")) {
                                            Quickshell.execDetached(["sh", "-c", raw.slice(1).trim()]);
                                            Local.AppState.closeMorph();
                                        } else if (laRoot.apps.length > 0) {
                                            laRoot.apps[laRoot.selIndex].execute();
                                            Local.AppState.closeMorph();
                                        }
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Escape) {
                                        Local.AppState.closeMorph();
                                        event.accepted = true;
                                    }
                                }
                            }
                        }

                        ListView {
                            id: laList
                            width: parent.width
                            height: parent.height - 42
                            clip: true
                            model: laRoot.apps
                            currentIndex: laRoot.selIndex
                            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                            delegate: Rectangle {
                                width: laList.width
                                height: 34
                                radius: height / 2
                                color: index === laRoot.selIndex
                                       ? Qt.rgba(Local.Colors.accent.r, Local.Colors.accent.g,
                                                 Local.Colors.accent.b, 0.30)
                                       : "transparent"
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: 12
                                    spacing: 10
                                    Image {
                                        width: 20; height: 20
                                        anchors.verticalCenter: parent.verticalCenter
                                        source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                                        asynchronous: true
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.name
                                        color: Local.Colors.foreground
                                        font.family: Local.Colors.fontFamily
                                        font.pixelSize: 13
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: laRoot.selIndex = index
                                    onClicked: {
                                        modelData.execute();
                                        Local.AppState.closeMorph();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Component {
                id: clipboardContent
                Item {
                    id: chRoot
                    anchors.fill: parent
                    property var items: []
                    focus: true
                    Keys.onEscapePressed: Local.AppState.closeMorph()

                    Process {
                        id: chLister
                        command: ["cliphist", "list"]
                        running: true
                        stdout: StdioCollector {
                            onStreamFinished: {
                                chRoot.items = this.text.split("\n")
                                    .filter(l => l.trim().length > 0).slice(0, 60);
                            }
                        }
                    }

                    Column {
                        anchors.fill: parent
                        spacing: 8

                        Text {
                            text: "Clipboard"
                            color: Local.Colors.foreground
                            font.family: Local.Colors.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                        }

                        ListView {
                            id: chList
                            width: parent.width
                            height: parent.height - 24
                            clip: true
                            spacing: 4
                            model: chRoot.items

                            delegate: Rectangle {
                                width: chList.width
                                height: 30
                                radius: height / 2
                                color: chMouse.containsMouse
                                       ? Qt.rgba(Local.Colors.accent.r, Local.Colors.accent.g,
                                                 Local.Colors.accent.b, 0.25)
                                       : Qt.rgba(1, 1, 1, 0.05)
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: 14
                                    width: parent.width - 28
                                    elide: Text.ElideRight
                                    text: modelData.split("\t").slice(1).join(" ")
                                    color: Local.Colors.foreground
                                    font.family: Local.Colors.fontFamily
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    id: chMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        Quickshell.execDetached(["bash",
                                            Quickshell.env("HOME") + "/.config/quickshell/rice/scripts/cliphist-restore.sh",
                                            modelData]);
                                        Local.AppState.closeMorph();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Component {
                id: powerContent
                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    Repeater {
                        model: [
                            { glyph: "\uf023", label: "Lock",     action: "lock",     destructive: false },
                            { glyph: "\uf186", label: "Sleep",    action: "sleep",    destructive: false },
                            { glyph: "\uf2f1", label: "Reboot",   action: "reboot",   destructive: true },
                            { glyph: "\uf011", label: "Shutdown", action: "shutdown", destructive: true }
                        ]

                        delegate: Rectangle {
                            id: powerBtn
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 10
                            property bool armed: false

                            color: armed ? Qt.rgba(0.8, 0.2, 0.2, 0.35)
                                 : hoverArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                            border.width: armed ? 1 : 0
                            border.color: "#ff5555"

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Timer {
                                id: disarmTimer
                                interval: 2500
                                onTriggered: powerBtn.armed = false
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.glyph
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 18
                                    color: Local.Colors.foreground
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: powerBtn.armed ? "confirm?" : modelData.label
                                    font.family: Local.Colors.fontFamily
                                    font.pixelSize: 10
                                    color: powerBtn.armed ? "#ff8888" : Local.Colors.muted
                                }
                            }

                            MouseArea {
                                id: hoverArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    // destructive actions need a second click within
                                    // 2.5s to confirm, so a misclick can't nuke the session
                                    if (modelData.destructive && !powerBtn.armed) {
                                        powerBtn.armed = true;
                                        disarmTimer.restart();
                                        return;
                                    }
                                    Local.AppState.closeMorph();
                                    let cmd = "true";
                                    if (modelData.action === "lock") cmd = "hyprlock";
                                    else if (modelData.action === "sleep") cmd = "systemctl suspend";
                                    else if (modelData.action === "reboot") cmd = "systemctl reboot";
                                    else if (modelData.action === "shutdown") cmd = "systemctl poweroff";
                                    Quickshell.execDetached(["bash", "-c", cmd]);
                                }
                            }
                        }
                    }
                }
            }

            Component {
                id: volumeContent
                ColumnLayout {
                    id: volCol
                    anchors.fill: parent
                    spacing: 10

                    readonly property var sink: Pipewire.defaultAudioSink
                    readonly property bool ready: !!(sink && sink.ready && sink.audio)
                    readonly property real vol: ready ? sink.audio.volume : 0

                    PwObjectTracker { objects: volCol.sink ? [volCol.sink] : [] }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: (volCol.ready && volCol.sink.audio.muted) ? "\uf026" : "\uf028"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 16
                            color: Local.Colors.foreground

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                onClicked: { if (volCol.ready) volCol.sink.audio.muted = !volCol.sink.audio.muted; }
                            }
                        }

                        Text {
                            text: volCol.ready ? Math.round(volCol.vol * 100) + "%" : "--"
                            font.family: Local.Colors.fontFamily
                            font.pixelSize: 12
                            color: Local.Colors.foreground
                        }

                        Item { Layout.fillWidth: true }
                    }

                    Rectangle {
                        id: track
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: Qt.rgba(0, 0, 0, 0.35)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * Math.max(0, Math.min(1, volCol.vol))
                            radius: 4
                            color: Local.Colors.accent
                        }

                        MouseArea {
                            anchors.fill: parent
                            function applyFromX(mx) {
                                if (!volCol.ready) return;
                                const frac = Math.max(0, Math.min(1, mx / track.width));
                                volCol.sink.audio.muted = false;
                                volCol.sink.audio.volume = frac;
                            }
                            onPressed: (mouse) => applyFromX(mouse.x)
                            onPositionChanged: (mouse) => { if (pressed) applyFromX(mouse.x); }
                        }
                    }
                }
            }

            Component {
                id: wallpaperContent
                Column {
                    id: wpRoot
                    anchors.fill: parent
                    spacing: 8
                    focus: true

                    property var items: []
                    property int selIndex: 0

                    Component.onCompleted: forceActiveFocus()

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                            selIndex = Math.min(selIndex + 1, items.length - 1);
                            wpList.positionViewAtIndex(selIndex, ListView.Center);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                            selIndex = Math.max(0, selIndex - 1);
                            wpList.positionViewAtIndex(selIndex, ListView.Center);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (items.length > 0) wpRoot.applyWallpaper(items[selIndex].path);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            Local.AppState.closeMorph();
                            event.accepted = true;
                        }
                    }

                    function applyWallpaper(path) {
                        const posX = Math.round(Local.AppState.morphOriginX
                                                 + Local.AppState.morphOriginWidth / 2);
                        const posY = Math.round(Local.AppState.morphScreenHeight
                                                 - Local.AppState.morphOriginY);
                        Local.AppState.closeMorph();
                        Local.AppState.hideBarTemporarily(1500);
                        Quickshell.execDetached(["bash",
                            Quickshell.env("HOME") + "/.config/quickshell/rice/scripts/apply-wallpaper.sh",
                            path, "grow", posX + "," + posY]);
                    }

                    Process {
                        id: wpLister
                        command: ["bash",
                            Quickshell.env("HOME") + "/.config/quickshell/rice/scripts/wallpaper-list-thumbnails.sh"]
                        running: true
                        stdout: StdioCollector {
                            onStreamFinished: {
                                wpRoot.items = this.text.split("\n")
                                    .filter(l => l.length > 0)
                                    .map(l => {
                                        const parts = l.split("\t");
                                        return { path: parts[0], thumb: parts[1] || parts[0] };
                                    });
                            }
                        }
                    }

                    Text {
                        text: "Wallpapers"
                        color: Local.Colors.foreground
                        font.family: Local.Colors.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                    }

                    ListView {
                      id: wpList
                      width: parent.width
                      height: parent.height - 24
                      orientation: ListView.Horizontal
                      spacing: 10
                      clip: true
                      cacheBuffer: 400
                      model: wpRoot.items
                      currentIndex: wpRoot.selIndex
                      highlightMoveDuration: 120
                      onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Center)

                      delegate: Item {
                        width: 122; height: 66
                        Rectangle {
                                  id: card
                                  width: 122; height: 66
                                  radius: 26
                                  color: "transparent"
                                  border.width: index === wpRoot.selIndex ? 2 : 1
                                  border.color: index === wpRoot.selIndex ? Local.Colors.accent : Local.Colors.muted

                                  Image {
                                        id: thumb
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        source: "file://" + modelData.thumb
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: false
                                        cache: true
                                        sourceSize.width: 244
                                        sourceSize.height: 132
                                        visible: false
                                    }
                                    Rectangle {
                                        id: maskShape
                                        anchors.fill: thumb
                                        radius: card.radius - 2
                                        visible: false
                                    }
                                    OpacityMask {
                                        anchors.fill: thumb
                                        source: thumb
                                        maskSource: maskShape
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: { wpRoot.selIndex = index; wpRoot.applyWallpaper(modelData.path); }
                                    }
                                }
                        }
                    }
                  }
                }

            Component {
                id: notificationContent
                Column {
                    anchors.fill: parent; spacing: 6
                    Row { Text { text: "NOTIFICATIONS"; color: Local.Colors.foreground; font.bold: true; font.family: Local.Colors.fontFamily } }
                    ListView { width: parent.width; height: parent.height - 24; clip: true; model: Local.AppState.notifications
                        delegate: Rectangle { width: parent.width; height: 38; radius: 10; color: Qt.rgba(Local.Colors.background.r,Local.Colors.background.g,Local.Colors.background.b,.6); border.width: 1; border.color: Local.Colors.accent
                            Text { anchors.fill: parent; anchors.margins: 8; verticalAlignment: Text.AlignVCenter; text: modelData.summary + (modelData.body ? " — " + modelData.body : ""); color: Local.Colors.foreground; elide: Text.ElideRight; font.family: Local.Colors.fontFamily }
                            MouseArea { anchors.fill: parent; onClicked: Local.AppState.dismissNotification(modelData.id) }
                        }
                    }
                }
            }

            Component {
                id: stubContent
                Item {
                    anchors.fill: parent
                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "\uf013"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 18
                            color: Local.Colors.muted
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "under construction"
                            font.family: Local.Colors.fontFamily
                            font.pixelSize: 11
                            color: Local.Colors.muted
                        }
                    }
                }
            }
        }
    }
}
