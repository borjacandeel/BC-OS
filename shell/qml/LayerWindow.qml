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
    color: "transparent"
    flags: Qt.FramelessWindowHint | (passthrough ? Qt.WindowTransparentForInput : 0)
    visible: false

    Component.onCompleted: {
        Layer.configure(w, { layer: layer, anchors: edges, exclusive: exclusive, margins: margins, keyboard: keyboard,
                             scope: scope, width: edges.indexOf("left") >= 0 && edges.indexOf("right") >= 0 ? 0 : width,
                             height: edges.indexOf("top") >= 0 && edges.indexOf("bottom") >= 0 ? 0 : height })
        visible = Qt.binding(() => w.shown)
    }
}
