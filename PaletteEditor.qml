import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "." as Local

// Visual palette editor. Shows the 16 colors, clicking one opens
// H/S/L sliders. Changes propagate live through the Colors singleton.
// "Apply" writes colors.json and re-triggers hyprctl/foot/zsh.
// "Reset" reverts to what pywal originally generated.
Item {
    id: root

    property bool visible_: false
    property var editedPalette: []
    property var originalPalette: []
    property int selectedColorIndex: 0

    function hexToHsl(hex) {
        const r = parseInt(hex.slice(1, 3), 16) / 255;
        const g = parseInt(hex.slice(3, 5), 16) / 255;
        const b = parseInt(hex.slice(5, 7), 16) / 255;
        const max = Math.max(r, g, b), min = Math.min(r, g, b);
        let h, s, l = (max + min) / 2;
        if (max === min) { h = s = 0; }
        else {
            const d = max - min;
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
            switch (max) {
                case r: h = ((g - b) / d + (g < b ? 6 : 0)) / 6; break;
                case g: h = ((b - r) / d + 2) / 6; break;
                case b: h = ((r - g) / d + 4) / 6; break;
            }
        }
        return { h, s, l };
    }

    function hslToHex(h, s, l) {
        let r, g, b;
        if (s === 0) { r = g = b = l; }
        else {
            const hue2rgb = (p, q, t) => {
                if (t < 0) t += 1;
                if (t > 1) t -= 1;
                if (t < 1/6) return p + (q - p) * 6 * t;
                if (t < 1/2) return q;
                if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
                return p;
            };
            const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
            const p = 2 * l - q;
            r = hue2rgb(p, q, h + 1/3);
            g = hue2rgb(p, q, h);
            b = hue2rgb(p, q, h - 1/3);
        }
        const toHex = (x) => Math.round(x * 255).toString(16).padStart(2, '0');
        return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
    }

    function initPalette() {
        const pal = [];
        for (let i = 0; i < 16; ++i) pal.push(hexToHsl(Local.Colors.palette[i]));
        editedPalette = pal;
        originalPalette = JSON.parse(JSON.stringify(pal));
        selectedColorIndex = 0;
    }

    function editedPaletteAsHex() {
        return editedPalette.map(c => hslToHex(c.h, c.s, c.l));
    }

    function updateChannel(index, channel, value) {
        const newPal = editedPalette.map((c, i) => {
            if (i !== index) return c;
            const updated = { h: c.h, s: c.s, l: c.l };
            updated[channel] = value;
            return updated;
        });
        editedPalette = newPal;
        // write to walPalette (the mutable raw property), not the
        // computed "palette" getter
        Local.Colors.walPalette = editedPaletteAsHex();
    }

    function applyPalette() {
        saveProc.paletteHex = editedPaletteAsHex();
        saveProc.running = true;
    }

    function resetPalette() {
        editedPalette = JSON.parse(JSON.stringify(originalPalette));
        Local.Colors.walPalette = originalPalette.map(c => hslToHex(c.h, c.s, c.l));
    }

    onVisible_Changed: { if (visible_) initPalette(); }

    Process {
        id: saveProc
        property var paletteHex: []
        running: false

        command: {
            if (!running || paletteHex.length < 16) return [];
            const colorsJson = Quickshell.env("HOME") + "/.cache/wal/colors.json";
            const hexStr = paletteHex.join(",");
            return ["python3", "-c", `
import json, sys
path = '${colorsJson}'
with open(path) as f:
    data = json.load(f)
colors_list = '${hexStr}'.split(',')
for i, c in enumerate(colors_list):
    data['colors']['color' + str(i)] = c
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
print('Palette saved to', path)
`];
        }

        stdout: StdioCollector {
            onStreamFinished: {
                console.log("PaletteEditor:", this.text.trim());
                reapplyProc.running = true;
            }
        }
    }

    Process {
        id: reapplyProc
        running: false
        command: ["bash", "-c",
            Quickshell.env("HOME") + "/.config/quickshell/rice/scripts/apply-wallpaper-colors-only.sh"]
    }

    IpcHandler {
        target: "paletteEditor"
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
                opacity: 0.85
                MouseArea { anchors.fill: parent; onClicked: root.visible_ = false }
            }

            Rectangle {
                id: panel
                anchors.centerIn: parent
                width: 520
                height: mainCol.implicitHeight + 32
                color: Local.Colors.background
                border.color: Local.Colors.accent
                border.width: Local.Colors.borderWidth
                radius: Local.Colors.radius

                MouseArea { anchors.fill: parent; onClicked: (m) => m.accepted = true }

                ColumnLayout {
                    id: mainCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "PALETTE EDITOR"
                            color: Local.Colors.foreground
                            font.family: Local.Colors.fontFamily
                            font.pixelSize: 14
                            font.bold: true
                            font.letterSpacing: 2
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "Esc closes"
                            color: Local.Colors.muted
                            font.family: Local.Colors.fontFamily
                            font.pixelSize: 10
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Local.Colors.muted }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Repeater {
                            model: 16

                            Rectangle {
                                Layout.fillWidth: true
                                height: 48
                                radius: Local.Colors.radius

                                color: root.editedPalette.length > index
                                       ? root.hslToHex(root.editedPalette[index].h,
                                                        root.editedPalette[index].s,
                                                        root.editedPalette[index].l)
                                       : Local.Colors.palette[index] || "#000000"

                                border.color: index === root.selectedColorIndex ? "#ffffff" : "transparent"
                                border.width: 3

                                Text {
                                    anchors.centerIn: parent
                                    text: index
                                    color: "white"
                                    font.family: Local.Colors.fontFamily
                                    font.pixelSize: 9
                                    style: Text.Outline
                                    styleColor: "#000000"
                                }

                                MouseArea { anchors.fill: parent; onClicked: root.selectedColorIndex = index }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: editorCol.implicitHeight + 20
                        color: "#111111"
                        border.color: Local.Colors.muted
                        border.width: 1
                        radius: Local.Colors.radius
                        visible: root.editedPalette.length > 0

                        ColumnLayout {
                            id: editorCol
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                Rectangle {
                                    width: 48; height: 48
                                    radius: Local.Colors.radius
                                    color: root.editedPalette.length > root.selectedColorIndex
                                           ? root.hslToHex(
                                               root.editedPalette[root.selectedColorIndex].h,
                                               root.editedPalette[root.selectedColorIndex].s,
                                               root.editedPalette[root.selectedColorIndex].l)
                                           : "#000000"
                                    border.color: Local.Colors.muted
                                    border.width: 1
                                }

                                ColumnLayout {
                                    spacing: 2
                                    Text {
                                        text: "color" + root.selectedColorIndex
                                        color: Local.Colors.accent
                                        font.family: Local.Colors.fontFamily
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                    Text {
                                        text: root.editedPalette.length > root.selectedColorIndex
                                              ? root.hslToHex(
                                                  root.editedPalette[root.selectedColorIndex].h,
                                                  root.editedPalette[root.selectedColorIndex].s,
                                                  root.editedPalette[root.selectedColorIndex].l)
                                              : ""
                                        color: Local.Colors.muted
                                        font.family: Local.Colors.fontFamily
                                        font.pixelSize: 11
                                    }
                                }
                            }

                            Repeater {
                                model: [
                                    { label: "H", channel: "h" },
                                    { label: "S", channel: "s" },
                                    { label: "L", channel: "l" }
                                ]

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Text {
                                        text: modelData.label
                                        color: Local.Colors.accent
                                        font.family: Local.Colors.fontFamily
                                        font.pixelSize: 12
                                        font.bold: true
                                        Layout.preferredWidth: 14
                                    }

                                    Rectangle {
                                        id: sliderTrack
                                        Layout.fillWidth: true
                                        height: 16
                                        color: "#222222"
                                        border.color: Local.Colors.muted
                                        border.width: 1
                                        radius: Local.Colors.radius

                                        readonly property real currentVal:
                                            root.editedPalette.length > root.selectedColorIndex
                                            ? root.editedPalette[root.selectedColorIndex][modelData.channel]
                                            : 0

                                        Rectangle {
                                            width: parent.currentVal * parent.width
                                            height: parent.height
                                            color: Local.Colors.accent
                                            opacity: 0.7
                                            radius: Local.Colors.radius
                                        }

                                        Rectangle {
                                            x: parent.currentVal * (parent.width - width)
                                            width: 4
                                            height: parent.height
                                            color: "#ffffff"
                                            radius: Local.Colors.radius
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            preventStealing: true

                                            function updateFromMouse(mouseX) {
                                                const val = Math.max(0, Math.min(1, mouseX / sliderTrack.width));
                                                root.updateChannel(root.selectedColorIndex, modelData.channel, val);
                                            }

                                            onPressed: (mouse) => updateFromMouse(mouse.x)
                                            onPositionChanged: (mouse) => { if (pressed) updateFromMouse(mouse.x); }
                                        }
                                    }

                                    Text {
                                        text: root.editedPalette.length > root.selectedColorIndex
                                              ? Math.round(root.editedPalette[root.selectedColorIndex][modelData.channel] * 359).toString()
                                              : "0"
                                        color: Local.Colors.foreground
                                        font.family: Local.Colors.fontFamily
                                        font.pixelSize: 11
                                        Layout.preferredWidth: 30
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle {
                            Layout.fillWidth: true
                            height: 34
                            color: "transparent"
                            border.color: Local.Colors.muted
                            border.width: 1
                            radius: Local.Colors.radius

                            Text {
                                anchors.centerIn: parent
                                text: "RESET"
                                color: Local.Colors.muted
                                font.family: Local.Colors.fontFamily
                                font.pixelSize: 12
                            }

                            MouseArea { anchors.fill: parent; onClicked: root.resetPalette() }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 34
                            color: Local.Colors.accent
                            radius: Local.Colors.radius

                            Text {
                                anchors.centerIn: parent
                                text: "APPLY"
                                color: Local.Colors.background
                                font.family: Local.Colors.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                            }

                            MouseArea { anchors.fill: parent; onClicked: root.applyPalette() }
                        }
                    }
                }
            }

            Item {
                anchors.fill: parent
                focus: root.visible_

                Keys.onPressed: (event) => {
                    switch (event.key) {
                        case Qt.Key_Escape: case Qt.Key_Q: root.visible_ = false; event.accepted = true; break;
                        case Qt.Key_H: case Qt.Key_Left:
                            root.selectedColorIndex = Math.max(0, root.selectedColorIndex - 1); event.accepted = true; break;
                        case Qt.Key_L: case Qt.Key_Right:
                            root.selectedColorIndex = Math.min(15, root.selectedColorIndex + 1); event.accepted = true; break;
                        case Qt.Key_Return: case Qt.Key_Enter: root.applyPalette(); event.accepted = true; break;
                        case Qt.Key_R: root.resetPalette(); event.accepted = true; break;
                    }
                }
            }
        }
    }
}
