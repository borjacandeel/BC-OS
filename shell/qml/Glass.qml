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
    onXChanged: sync(); onYChanged: sync()
    // Sin GPU (máquinas virtuales) nunca se calcula la lente: cuesta CPU que el compositor necesita para dibujar
    // Cambiando de tamaño (Dock que se amplía, paneles que crecen): recortes rápidos sin lente mientras dura; la lente
    // solo al asentarse. Así la animación no satura la CPU recalculando la refracción cada 70 ms (iba a golpes en VM)
    property bool resizing: false
    onWidthChanged: { sync(); resizing = true; still.restart() }
    onHeightChanged: { sync(); resizing = true; still.restart() }
    Component.onCompleted: { sync(); bufA.asynchronous = false; bufA.source = want; asked = want; bufA.asynchronous = true }
    // Los padres pueden moverse o escalarse (animaciones de entrada): se vuelve a calcular al aparecer y al asentarse
    onVisibleChanged: if (visible) { sync(); settle.restart() }
    Timer { id: settle; interval: 450; onTriggered: g.sync() }
    property int version: 0
    // Solo al cambiar el fondo de pantalla (antes con cualquier ajuste: recalculaba todo el cristal y daba tirones)
    readonly property string wallpaperNow: Settings.wallpaper
    onWallpaperNowChanged: g.version++

    // Sombra difusa (dos capas suaves en lugar de un desenfoque costoso)
    Rectangle {
        visible: g.shadow && Render.shadows > 0; anchors.fill: parent; anchors.margins: -1; anchors.topMargin: 3; anchors.bottomMargin: -6
        radius: g.radius + 2; color: Theme.shadow; opacity: 0.35
    }
    Rectangle {
        visible: g.shadow && Render.shadows > 1; anchors.fill: parent; anchors.margins: -6; anchors.topMargin: 2; anchors.bottomMargin: -14
        radius: g.radius + 8; color: Theme.shadow; opacity: 0.12
    }
    // En movimiento (arrastrar la ventana): recortes rápidos sin lente (con sus esquinas redondeadas) cada fotograma
    // posible; al detenerse, el recorte completo con lente y luz en el borde.
    property bool moving: false
    function _moved() { sync(); if (win && win.titlebarHeight !== undefined) { moving = true; still.restart() } }
    onOriginXChanged: _moved()
    onOriginYChanged: _moved()
    Timer { id: still; interval: 180; onTriggered: { g.moving = false; g.resizing = false } }
    // Fondo desenfocado recortado (GlassProvider). Doble búfer con carga en segundo plano: el recorte nuevo se
    // calcula en otro hilo y solo se muestra cuando está listo, así las animaciones (paneles que aparecen, Dock que se
    // amplía, ventanas que se mueven) no se frenan esperando al recorte. Como mucho uno cada 70 ms (16 ms moviendo).
    readonly property string want: !Quick.realBlur && g.width > 2 && g.height > 2
        ? "image://glass/" + [g.gp.x, g.gp.y, Math.round(g.width), Math.round(g.height), Math.round(g.radius), Math.round(g.scrW), Math.round(g.scrH), g.version].join("_") + (g.leftOnly ? "_L" : "_R") + (g.moving || g.resizing || !Render.lens ? "_M" : "")
        : ""
    property int front: 0
    property string asked: ""
    function request(u) {
        if (u === asked) return
        asked = u
        const back = front === 0 ? bufB : bufA
        if (back.source == u && back.status === Image.Ready) { front = 1 - front; return }
        back.source = u
    }
    onWantChanged: { if (!throttle.running) { request(want); throttle.restart() } else throttle.pending = true }
    Timer { id: throttle; interval: g.moving ? 16 : 70; property bool pending: false
            onTriggered: if (pending) { pending = false; g.request(g.want); restart() } }
    Image {
        id: bufA
        visible: !Quick.realBlur && g.front === 0
        anchors.fill: parent
        cache: false; asynchronous: true; smooth: false
        onStatusChanged: if (status === Image.Ready && source == g.asked) g.front = 0
    }
    Image {
        id: bufB
        visible: !Quick.realBlur && g.front === 1
        anchors.fill: parent
        cache: false; asynchronous: true; smooth: false
        onStatusChanged: if (status === Image.Ready && source == g.asked) g.front = 1
    }
    // Tinte (deslizador ultratransparente ↔ tintado)
    // Con desenfoque real (Hyprland) el tinte es algo más ligero para que se vea lo de detrás, como Liquid Glass
    // Barras laterales (leftOnly): esquinas derechas rectas recortando un rectángulo más ancho
    Item {
        anchors.fill: parent; clip: g.leftOnly
    Rectangle { width: parent.width + (g.leftOnly ? g.radius : 0); height: parent.height; radius: g.radius; color: g.tintColor
                opacity: Settings.reduceTransparency ? 0.97 : Math.min(0.97, Quick.realBlur ? Math.max(Theme.dark ? 0.40 : 0.5, 0.75 * (Theme.glassOpacity + g.tintBoost)) : Theme.glassOpacity + g.tintBoost) }
    // Reflejo superior: refracción uniforme de Golden Gate
    Rectangle {
        width: parent.width + (g.leftOnly ? g.radius : 0); height: parent.height; radius: g.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, Theme.glassSpecular) }
            GradientStop { position: 0.35; color: Qt.rgba(1, 1, 1, 0) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, Theme.glassSpecular * 0.35) }
        }
    }
    }
    // Borde fino luminoso: más claro arriba (luz) que abajo
    Rectangle {
        visible: g.rim; anchors.fill: parent; radius: g.radius; color: "transparent"
        border.width: Settings.increaseContrast ? 2 : 1; border.color: Settings.increaseContrast ? (Theme.dark ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(0, 0, 0, 0.55)) : Theme.glassRim
    }
    Rectangle {
        visible: g.rim; anchors.fill: parent; anchors.margins: 1; radius: Math.max(0, g.radius - 1); color: "transparent"
        border.width: 1; border.color: Theme.glassRimLow
    }
}
