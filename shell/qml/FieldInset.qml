import QtQuick
import BCShell

// Campo de texto como macOS: leve sombra interior arriba (el campo parece hundido) y anillo de foco del color de
// acento que aparece encogiéndose hasta su sitio. Sin efectos ni capas: dos rectángulos.
// Uso (dentro del fondo redondeado del campo): FieldInset { radius: parent.radius; focused: entrada.activeFocus }
Item {
    id: f
    anchors.fill: parent
    property real radius: 8
    property bool focused: false
    z: -0.5
    // Sombra interior: degradado de 3–4 px que se funde, recortado por el mismo radio
    Rectangle {
        anchors.fill: parent; radius: f.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.lightUi ? Qt.rgba(0, 0, 0, 0.07) : Qt.rgba(0, 0, 0, 0.22) }
            GradientStop { position: Math.min(0.5, 4 / Math.max(1, f.height)); color: "transparent" }
        }
    }
    // Anillo de foco: entra desde algo más grande y transparente (como el de macOS)
    Rectangle {
        anchors.centerIn: parent
        width: parent.width + 6; height: parent.height + 6; radius: f.radius + 3
        color: "transparent"; border.width: 3
        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45)
        opacity: f.focused ? 1 : 0
        scale: f.focused ? 1 : 1.08
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.d(180); easing.type: Easing.OutQuad } }
        Behavior on scale { NumberAnimation { duration: Theme.d(220); easing.type: Easing.OutCubic } }
    }
}
