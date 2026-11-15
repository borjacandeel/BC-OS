import QtQuick
import BCShell

// Píldora de volumen / brillo (OSD): sube con rebote, muestra la barra y se oculta sola.
Item {
    id: osd
    width: 260; height: 64
    property string kind: "volume"      // "volume" | "brightness"
    property bool open: false
    readonly property real value: kind === "volume" ? (SystemStatus.muted ? 0 : Math.min(1, SystemStatus.volume)) : SystemStatus.brightness
    signal hidden()

    function show(k) { kind = k; open = true; hideTimer.restart() }
    Timer { id: hideTimer; interval: 1600; onTriggered: osd.open = false }

    Rectangle {
        id: pill
        anchors.fill: parent
        radius: height / 2
        color: UiState.classic ? Theme.popupFill : "transparent"
        border.width: UiState.classic ? 1 : 0; border.color: Theme.hairline
        Glass { visible: !UiState.classic; anchors.fill: parent; radius: parent.radius; tintBoost: 0.35 }
        opacity: osd.open ? 1 : 0
        scale: osd.open ? 1 : 0.9
        transformOrigin: UiState.classic ? Item.Bottom : Item.TopRight
        Behavior on opacity { NumberAnimation { duration: Theme.dur(140) } }
        Behavior on scale { NumberAnimation { duration: Theme.dur(osd.open ? 320 : 160); easing.type: osd.open ? Easing.OutBack : Easing.InCubic } }
        onOpacityChanged: if (opacity === 0) osd.hidden()

        Icon {
            id: ic
            x: 20; anchors.verticalCenter: parent.verticalCenter; size: UiState.classic ? 26 : 20; color: Theme.label
            name: osd.kind === "volume" ? Icons.volumeIcon(SystemStatus.volume, SystemStatus.muted) : Icons.sun
            Behavior on y { NumberAnimation { duration: 120 } }
        }
        Rectangle {
            x: UiState.classic ? 64 : 54; anchors.verticalCenter: parent.verticalCenter; width: parent.width - x - 24; height: UiState.classic ? 8 : 6; radius: height / 2
            color: Theme.fill
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, osd.value)); height: parent.height; radius: parent.radius
                color: UiState.classic ? Theme.accent : Theme.label
                Behavior on width { NumberAnimation { duration: Theme.dur(140); easing.type: Easing.OutCubic } }
            }
        }
    }
}
