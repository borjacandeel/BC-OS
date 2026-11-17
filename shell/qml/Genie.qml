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
    // Franjas de ~3 px: bordes del embudo suaves (sin escalones), como el genio de macOS
    property int strips: 40
    onFromChanged: strips = Math.max(40, Math.min(Quick.softwareRender ? 200 : 300, Math.round(from.height / 3)))
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
    // Antes de empezar, la captura se muestra quieta encima de la ventana unos milisegundos (lo que tarda la capa en
    // aparecer); entonces se avisa (began) para ocultar la ventana real: así no hay parpadeo entre ventana y genio
    signal began()
    SequentialAnimation {
        id: anim
        property alias from: na.from
        property alias to: na.to
        property alias duration: na.duration
        PauseAnimation { duration: 70 }
        ScriptAction { script: g.began() }
        NumberAnimation { id: na; target: g; property: "p"; easing.type: Easing.InOutQuad }
        onFinished: { g.source = ""; g.finished() }
    }

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
    // Cada franja es un recorte (clip) de la MISMA imagen: se decodifica una sola vez (antes, una por franja) y el
    // primer fotograma sale al instante; luego solo cambian posiciones y tamaños (barato también por software)
    Repeater {
        model: g.source !== "" ? g.strips : 0
        delegate: Item {
            required property int index
            readonly property real tt: g.rowT(index / g.strips)
            readonly property real tb: g.rowT((index + 1) / g.strips)
            readonly property real tm: (tt + tb) / 2
            readonly property real bandH: g.from.height / g.strips
            readonly property real k: height / Math.max(0.01, bandH)          // compresión vertical de la franja
            visible: tt < 0.999
            clip: true
            width: 2 * g.halfW(tm)
            height: Math.max(0.5, (tb - tt) * g.dist) + 0.6
            x: g.centerX(tm) - width / 2
            y: g.y0 + tt * g.dist
            opacity: g.p > 0.96 && !g.reverse ? (1 - g.p) * 25 : 1
            Image {
                source: g.source
                cache: true; smooth: true; asynchronous: false
                width: parent.width
                height: g.from.height * parent.k
                y: -parent.index * parent.bandH * parent.k
            }
        }
    }
}
