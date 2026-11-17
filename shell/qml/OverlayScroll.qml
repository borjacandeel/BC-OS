import QtQuick

// Barra de desplazamiento superpuesta de macOS: invisible en reposo, aparece al desplazar, se ensancha con el
// puntero encima y se puede arrastrar. Uso: OverlayScroll { flick: miLista } dentro del mismo padre que la vista.
Item {
    id: sb
    property Flickable flick
    readonly property bool needed: flick && flick.contentHeight > flick.height + 1
    property bool hovered: area.containsMouse || area.pressed
    property bool active: false
    x: flick ? flick.x + flick.width - width - 2 : 0
    y: flick ? flick.y + 3 : 0
    width: hovered ? 11 : 7
    height: flick ? flick.height - 6 : 0
    z: 50
    visible: needed
    opacity: (active || hovered) ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: (sb.active || sb.hovered) ? 120 : 420; easing.type: Easing.OutCubic } }
    Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    // Declarada dentro de la vista: pasa a ser hermana suya (si no, se desplazaría con el contenido)
    Component.onCompleted: if (flick && parent !== flick.parent) parent = flick.parent

    Timer { id: hide; interval: 900; onTriggered: sb.active = false }
    Connections {
        target: sb.flick
        function onContentYChanged() { sb.active = true; hide.restart() }
        function onMovingChanged() { if (sb.flick.moving) { sb.active = true; hide.restart() } }
    }

    // Carril: solo se ve con el puntero encima (como macOS)
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.dark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)
        opacity: sb.hovered ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 140 } }
    }
    Rectangle {
        id: thumb
        readonly property real ratio: sb.flick ? Math.min(1, sb.flick.height / Math.max(1, sb.flick.contentHeight)) : 1
        readonly property real range: Math.max(1, sb.flick ? sb.flick.contentHeight - sb.flick.height : 1)
        readonly property real pos: sb.flick ? (sb.flick.contentY - sb.flick.originY) / range : 0
        // Rebote elástico: la barra encoge al estirarse más allá de los extremos
        readonly property real over: sb.flick ? Math.max(0, -pos * sb.height) + Math.max(0, (pos - 1) * sb.height) : 0
        x: 2; width: parent.width - 4
        height: Math.max(18, ratio * sb.height - over)
        y: Math.max(0, Math.min(sb.height - height, Math.max(0, Math.min(1, pos)) * (sb.height - height)))
        radius: width / 2
        color: Theme.dark ? Qt.rgba(1, 1, 1, sb.hovered ? 0.55 : 0.42) : Qt.rgba(0, 0, 0, sb.hovered ? 0.5 : 0.36)
    }
    MouseArea {
        id: area
        anchors.fill: parent
        anchors.leftMargin: -4
        hoverEnabled: true
        preventStealing: true
        property real grab: -1
        function moveTo(my) {
            const f = sb.flick, free = sb.height - thumb.height
            if (free <= 0) return
            const p = Math.max(0, Math.min(1, (my - grab) / free))
            f.contentY = f.originY + p * (f.contentHeight - f.height)
        }
        onPressed: (m) => {
            if (m.y >= thumb.y && m.y <= thumb.y + thumb.height) grab = m.y - thumb.y
            else { grab = thumb.height / 2; moveTo(m.y) }
            sb.active = true
        }
        onPositionChanged: (m) => { if (pressed) { moveTo(m.y); hide.restart() } }
        onReleased: hide.restart()
        onContainsMouseChanged: if (containsMouse) { sb.active = true; hide.stop() } else hide.restart()
    }
}
