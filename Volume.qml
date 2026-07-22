import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import "." as Local

// Minimal volume readout: icon + percentage. Scroll to adjust, click
// to mute. Uses the native Pipewire service instead of polling an
// external process, so it reacts instantly to changes made anywhere.
Item {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: !!(sink && sink.ready && sink.audio)
    readonly property bool muted: ready ? sink.audio.muted : false
    readonly property real volume: ready ? sink.audio.volume : 0

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    function setVolume(v) {
        if (!ready) return;
        const clamped = Math.max(0, Math.min(1.5, v));
        sink.audio.muted = false;
        sink.audio.volume = clamped;
    }

    function toggleMute() {
        if (!ready) return;
        sink.audio.muted = !sink.audio.muted;
    }

    function adjustVolume(delta) { setVolume(volume + delta); }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: 3
        anchors.verticalCenter: parent.verticalCenter

        Text {
            text: root.muted ? "MUT" : "VOL"
            color: root.muted ? Local.Colors.muted : Local.Colors.foreground
            font.family: Local.Colors.fontFamily
            font.pixelSize: 11
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.ready
            text: root.muted ? "--" : Math.round(root.volume * 100) + "%"
            color: root.muted ? Local.Colors.muted : Local.Colors.foreground
            font.family: Local.Colors.fontFamily
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: root.toggleMute()

        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) root.adjustVolume(0.05);
            else if (wheel.angleDelta.y < 0) root.adjustVolume(-0.05);
        }
    }
}
