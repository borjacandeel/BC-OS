import QtQuick
import BCShell

// Efecto «genio» de macOS al minimizar al Dock (y su inverso al restaurar), sin shaders: la captura de la ventana
// (grim) se corta en franjas horizontales y cada franja se estrecha y cae hacia el icono del Dock con su propio
// avance (las de abajo van primero), lo que dibuja el embudo característico.
Item {
    id: g
    anchors.fill: parent
    property string source: ""
    property rect from: Qt.rect(0, 0, 0, 0)
    property point target: Qt.point(0, 0)
    property real iconSize: 46
    property real p: 0                  // 0 = ventana, 1 = dentro del Dock
    property bool reverse: false
    readonly property int strips: Quick.softwareRender ? 12 : 28   // menos franjas por software (CPU)
    signal finished()

    function run(src, rect, dockPoint, icon, back) {
        source = ""; source = src
        from = rect; target = dockPoint; iconSize = icon; reverse = back
        p = back ? 1 : 0
        anim.from = back ? 1 : 0; anim.to = back ? 0 : 1
        anim.duration = Theme.d(back ? Theme.durRestore : Theme.durMinimize)
        anim.restart()
    }
    NumberAnimation { id: anim; target: g; property: "p"; easing.type: Easing.InOutSine; onFinished: { g.source = ""; g.finished() } }

    function clamp(x) { return Math.max(0, Math.min(1, x)) }
    function ease(x) { return x < 0.5 ? 2 * x * x : 1 - Math.pow(-2 * x + 2, 2) / 2 }

    Repeater {
        model: g.source !== "" ? g.strips : 0
        delegate: Image {
            required property int index
            readonly property real v: index / g.strips                         // posición de la franja (0 arriba, 1 abajo)
            readonly property real lp: g.clamp(g.p * 1.7 - (1 - v) * 0.7)       // las franjas inferiores avanzan antes
            readonly property real e: g.ease(lp)
            readonly property real bandH: g.from.height / g.strips
            source: g.source
            cache: true; smooth: true; asynchronous: false
            sourceClipRect: Qt.rect(0, index * bandH, g.from.width, Math.ceil(bandH) + 1)
            // Ancho: del de la ventana al del icono; centro: del de la ventana al del icono
            width: g.from.width + (g.iconSize - g.from.width) * e
            height: Math.max(0.5, bandH + (g.iconSize / g.strips - bandH) * e) + 1
            x: (g.from.x + g.from.width / 2) + (g.target.x - g.from.x - g.from.width / 2) * e - width / 2
            y: (g.from.y + index * bandH) + ((g.target.y - g.iconSize / 2 + index * g.iconSize / g.strips) - (g.from.y + index * bandH)) * Math.pow(lp, 1.6)
            opacity: g.p > 0.97 && !g.reverse ? (1 - g.p) * 30 : 1
        }
    }
}
