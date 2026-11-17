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
    readonly property int strips: Quick.softwareRender ? 24 : 48   // menos franjas por software (CPU)
    signal finished()

    function run(src, rect, dockPoint, icon, back) {
        source = ""; source = src
        from = rect; target = dockPoint; iconSize = icon; reverse = back
        p = back ? 1 : 0
        anim.from = back ? 1 : 0; anim.to = back ? 0 : 1
        // Por software, algo más corto (menos fotogramas que dibujar) y con curva suave
        anim.duration = Theme.d(back ? Theme.durRestore : Theme.durMinimize)
        anim.restart()
    }
    NumberAnimation { id: anim; target: g; property: "p"; easing.type: Easing.InOutQuad; onFinished: { g.source = ""; g.finished() } }

    function clamp(x) { return Math.max(0, Math.min(1, x)) }
    function ease(x) { return x < 0.5 ? 2 * x * x : 1 - Math.pow(-2 * x + 2, 2) / 2 }

    // Genio de macOS en dos fases, como en macOS: 1) la parte de abajo de la ventana se estrecha en un embudo curvo
    // hacia el icono (la de arriba sigue ancha); 2) la ventana entera se desliza por el embudo y se comprime dentro
    // del icono. Se dibuja con franjas horizontales (sin shaders): también fluido por software.
    readonly property bool simple: false
    readonly property real y0: from.y
    readonly property real y1: target.y - iconSize / 2               // borde superior del icono
    readonly property real dist: Math.max(1, y1 - y0)
    readonly property real bend: clamp(p / 0.42)                       // fase 1: curvatura del embudo
    readonly property real slide: Math.pow(clamp((p - 0.3) / 0.7), 1.35)  // fase 2: deslizamiento (algo solapado)
    function smooth(t) { t = clamp(t); return t * t * (3 - 2 * t) }
    // Posición de una fila (0 = arriba de la ventana) a lo largo del embudo, 0..1 (1 = dentro del icono)
    function rowT(v) { const h = from.height / dist; return Math.min(1, v * h + slide * (1 + h) * 1.0) }
    function halfW(t) { return from.width / 2 + (iconSize / 2 - from.width / 2) * bend * smooth(t) }
    function centerX(t) { const cx = from.x + from.width / 2; return cx + (target.x - cx) * bend * smooth(t) }
    Repeater {
        model: g.source !== "" ? g.strips : 0
        delegate: Image {
            required property int index
            readonly property real tt: g.rowT(index / g.strips)
            readonly property real tb: g.rowT((index + 1) / g.strips)
            readonly property real tm: (tt + tb) / 2
            readonly property real bandH: g.from.height / g.strips
            source: g.source
            cache: true; smooth: true; asynchronous: false
            sourceClipRect: Qt.rect(0, index * bandH, g.from.width, Math.ceil(bandH) + 1)
            visible: tt < 0.999
            width: 2 * g.halfW(tm)
            height: Math.max(0.5, (tb - tt) * g.dist) + 1
            x: g.centerX(tm) - width / 2
            y: g.y0 + tt * g.dist
            opacity: g.p > 0.96 && !g.reverse ? (1 - g.p) * 25 : 1
        }
    }
}
