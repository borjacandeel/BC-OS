import QtQuick
import QtQuick.Window
import BCShell

// Ventana del panel como superficie wlr-layer-shell (o ventana normal si no hay soporte, p. ej. en las pruebas).
Window {
    id: w
    property string layer: "top"
    property var edges: []
    property int exclusive: 0
    property var margins: [0, 0, 0, 0]
    property string keyboard: "none"
    property string scope: "bc-shell"
    property bool shown: true
    property bool passthrough: false
    property bool absolute: false      // márgenes respecto a la pantalla entera (ignora las zonas reservadas por las barras)
    color: "transparent"
    flags: Qt.FramelessWindowHint | (passthrough ? Qt.WindowTransparentForInput : 0)
    visible: false

    readonly property bool fullscreenSurface: edges.length === 4
    // Posición de la superficie en la pantalla (para recortar el cristal del fondo)
    readonly property bool _l: edges.indexOf("left") >= 0
    readonly property bool _r: edges.indexOf("right") >= 0
    readonly property bool _t: edges.indexOf("top") >= 0
    readonly property bool _b: edges.indexOf("bottom") >= 0
    // Tamaño de SU pantalla (multimonitor: cada superficie recorta el fondo de la pantalla en la que está)
    screen: UiState.scr
    // Qt, al crear la ventana, vuelve a elegir pantalla según su posición (la de 0,0 es la primera): se coloca
    // dentro de SU pantalla para que la superficie layer-shell salga en el monitor correcto
    x: screen ? screen.virtualX : 0
    y: screen ? screen.virtualY : 0
    readonly property bool _other: screen && Qt.application.screens.length > 1 && screen !== UiState.scr
    readonly property real scrW: _other ? screen.width : UiState.sw
    readonly property real scrH: _other ? screen.height : UiState.sh
    readonly property real originX: _l ? margins[3] : (_r ? scrW - width - margins[1] : (scrW - width) / 2)
    readonly property real originY: _t ? margins[0] : (_b ? scrH - height - margins[2] : (scrH - height) / 2)
    function apply() {
        Layer.configure(w, { layer: layer, anchors: edges, exclusive: (fullscreenSurface || absolute) ? -1 : exclusive, margins: margins, keyboard: keyboard,
                             scope: scope, width: edges.indexOf("left") >= 0 && edges.indexOf("right") >= 0 ? 0 : width,
                             height: edges.indexOf("top") >= 0 && edges.indexOf("bottom") >= 0 ? 0 : height })
    }
    property rect inputRect: Qt.rect(0, 0, 0, 0)   // zona que recibe el puntero (vacía = toda)
    onInputRectChanged: Layer.setInputRect(w, inputRect)
    property bool ready: false
    onKeyboardChanged: if (ready) apply()
    onMarginsChanged: if (ready) apply()
    onExclusiveChanged: if (ready) apply()
    // Si cambia su pantalla (monitor conectado tarde), se vuelve a crear la superficie en la pantalla correcta
    onScreenChanged: if (ready) { const v = visible; visible = false; apply(); visible = Qt.binding(() => w.shown) }
    Component.onCompleted: {
        apply()
        ready = true
        visible = Qt.binding(() => w.shown)
    }
}
