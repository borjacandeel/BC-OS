import QtQuick
import QtQuick.Window
import BCShell

// Material Liquid Glass de BC OS (Golden Gate): fondo desenfocado precalculado (GlassProvider), tinte
// según el deslizador de Ajustes ▸ Aspecto, reflejo especular arriba, borde fino luminoso y sombra.
// Sin shaders: funciona igual con el renderizador por software de Qt (VirtualBox) y con GPU.
//   originX/originY: posición de la superficie (ventana layer-shell) en la pantalla.
Item {
    id: g
    property real radius: Theme.widgetRadius
    readonly property var win: Window.window
    property real originX: win && win.originX !== undefined ? win.originX : 0
    property real originY: win && win.originY !== undefined ? win.originY : 0
    property real tintBoost: 0          // los menús y paneles emergentes van algo más tintados que los widgets
    property bool shadow: true
    property bool rim: true
    property color tintColor: Theme.glassTintColor
    property bool leftOnly: false
    readonly property real scrW: win && win.scrW !== undefined ? win.scrW : UiState.sw
    readonly property real scrH: win && win.scrH !== undefined ? win.scrH : UiState.sh        // redondear solo las esquinas izquierdas (barras laterales)

    // Posición global para recortar el fondo desenfocado correcto
    property point gp: Qt.point(0, 0)
    function sync() { const p = g.mapToItem(null, 0, 0); gp = Qt.point(Math.round(p.x + originX), Math.round(p.y + originY)) }
    onXChanged: sync(); onYChanged: sync(); onWidthChanged: sync(); onHeightChanged: sync()
    onOriginXChanged: sync(); onOriginYChanged: sync()
    Component.onCompleted: sync()
    // Los padres pueden moverse o escalarse (animaciones de entrada): se vuelve a calcular al aparecer y al asentarse
    onVisibleChanged: if (visible) { sync(); settle.restart() }
    Timer { id: settle; interval: 450; onTriggered: g.sync() }
    property int version: 0
    Connections { target: Settings; function onChanged() { g.version++ } }

    // Sombra difusa (dos capas suaves en lugar de un desenfoque costoso)
    Rectangle {
        visible: g.shadow; anchors.fill: parent; anchors.margins: -1; anchors.topMargin: 3; anchors.bottomMargin: -6
        radius: g.radius + 2; color: Theme.shadow; opacity: 0.35
    }
    Rectangle {
        visible: g.shadow; anchors.fill: parent; anchors.margins: -6; anchors.topMargin: 2; anchors.bottomMargin: -14
        radius: g.radius + 8; color: Theme.shadow; opacity: 0.12
    }
    Image {
        id: blur
        anchors.fill: parent
        cache: false; asynchronous: false; smooth: false
        source: g.width > 2 && g.height > 2
            ? "image://glass/" + [g.gp.x, g.gp.y, Math.round(g.width), Math.round(g.height), Math.round(g.radius), Math.round(g.scrW), Math.round(g.scrH), g.version].join("_") + (g.leftOnly ? "_L" : "")
            : ""
    }
    // Tinte (deslizador ultratransparente ↔ tintado)
    Rectangle { anchors.fill: parent; radius: g.radius; color: g.tintColor; opacity: Math.min(0.97, Theme.glassOpacity + g.tintBoost) }
    // Reflejo superior: refracción uniforme de Golden Gate
    Rectangle {
        anchors.fill: parent; radius: g.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, Theme.glassSpecular) }
            GradientStop { position: 0.35; color: Qt.rgba(1, 1, 1, 0) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, Theme.glassSpecular * 0.35) }
        }
    }
    // Borde fino luminoso: más claro arriba (luz) que abajo
    Rectangle {
        visible: g.rim; anchors.fill: parent; radius: g.radius; color: "transparent"
        border.width: 1; border.color: Theme.glassRim
    }
    Rectangle {
        visible: g.rim; anchors.fill: parent; anchors.margins: 1; radius: Math.max(0, g.radius - 1); color: "transparent"
        border.width: 1; border.color: Theme.glassRimLow
    }
}
