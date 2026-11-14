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
        color: Theme.popupFill
        border.width: 1; border.color: Theme.hairline
        opacity: osd.open ? 1 : 0
        scale: osd.open ? 1 : 0.9
        transformOrigin: Item.Bottom
        Behavior on opacity { NumberAnimation { duration: Theme.dur(140) } }
        Behavior on scale { NumberAnimation { duration: Theme.dur(osd.open ? 320 : 160); easing.type: osd.open ? Easing.OutBack : Easing.InCubic } }
        onOpacityChanged: if (opacity === 0) osd.hidden()

        Icon {
            id: ic
            x: 20; anchors.verticalCenter: parent.verticalCenter; size: 26
            name: osd.kind === "volume" ? Icons.volumeIcon(SystemStatus.volume, SystemStatus.muted) : Icons.sun
            Behavior on y { NumberAnimation { duration: 120 } }
        }
        Rectangle {
            x: 64; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 64 - 24; height: 8; radius: 4
            color: Qt.rgba(1, 1, 1, 0.14)
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, osd.value)); height: parent.height; radius: 4
                gradient: Gradient { orientation: Gradient.Horizontal
                                     GradientStop { position: 0; color: Qt.lighter(Theme.accent, 1.25) } GradientStop { position: 1; color: Theme.accent } }
                Behavior on width { NumberAnimation { duration: Theme.dur(140); easing.type: Easing.OutCubic } }
            }
        }
    }
}
