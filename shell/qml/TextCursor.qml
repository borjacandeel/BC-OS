import QtQuick

// Punto de inserción como macOS: barra fina del color de acento que parpadea con fundido suave (no a golpes) y se
// queda fija mientras se escribe o se mueve el cursor. Sin animación continua: un temporizador cada 530 ms y solo
// 140 ms de fundido, así no mantiene el dibujo a 60 fps mientras un campo tiene el foco.
// Uso: TextInput { cursorDelegate: TextCursor {} }
Rectangle {
    id: c
    width: 2
    radius: 1
    color: Theme.accent
    antialiasing: true
    property bool on: true
    opacity: on ? 1 : 0
    Behavior on opacity { enabled: !Theme.reduced; NumberAnimation { duration: 140; easing.type: Easing.InOutQuad } }
    function wake() { on = true; blink.restart() }
    Timer {
        id: blink
        interval: 530; repeat: true
        running: c.visible && Qt.application.state === Qt.ApplicationActive
        onRunningChanged: c.on = true
        onTriggered: c.on = !c.on
    }
    // Escribir o mover el cursor lo deja encendido (como macOS)
    Connections {
        target: c.parent
        ignoreUnknownSignals: true
        function onCursorPositionChanged() { c.wake() }
        function onTextChanged() { c.wake() }
    }
}
