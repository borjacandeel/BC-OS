import QtQuick
import BCShell

// Menú desplegable (barra, menús de app y contextuales) con material Liquid Glass.
// Golden Gate: pocos iconos, columna de marca (✓) a la izquierda, atajos con símbolos a la derecha
// y submenús que se abren al pasar el puntero.
Item {
    id: card
    property var items: []
    property bool sub: false
    signal activated(string cmd)
    readonly property real s: Theme.s
    readonly property int itemH: Math.round(Theme.menuItemH * s)
    readonly property int pad: Math.round(Theme.menuPad * s)
    property int openSub: -1
    width: Math.max(Math.round(230 * s), measure.width)
    height: col.height + pad * 2
    transformOrigin: Item.TopLeft

    // Atajos como en macOS: Ctrl→⌃, Mayús→⇧, Alt→⌥, Súper→⌘
    function glyphs(k) {
        if (!k) return ""
        // Orden de macOS: ⌃ ⌥ ⇧ ⌘ y la tecla
        const parts = k.split("+"), key = parts.pop(), mods = parts.join("+")
        const order = [["Ctrl", "⌃"], ["Alt", "⌥"], ["Mayús", "⇧"], ["Súper", "⌘"]]
        let out = ""
        for (const m of order) if (mods.indexOf(m[0]) >= 0) out += m[1]
        return out + key.replace("Espacio", "␣").replace("Intro", "↩").replace("Supr", "⌦").replace("Tab", "⇥").replace("Retroceso", "⌫").replace("Esc", "⎋")
    }
    // Ancho según el elemento más largo
    Row {
        id: measure; visible: false
        Repeater { model: card.items
                   Text { text: (modelData.label || "") + "        " + card.glyphs(modelData.key); font.family: Theme.font; font.pixelSize: Math.round(13 * card.s) } }
        width: { let w = 0; for (let i = 0; i < children.length; ++i) w = Math.max(w, children[i].implicitWidth || 0); return w + Math.round(56 * card.s) }
    }

    Glass { anchors.fill: parent; radius: Math.round(Theme.menuRadius * card.s); tintBoost: 0.55 }

    Column {
        id: col
        x: card.pad; y: card.pad
        width: parent.width - card.pad * 2
        Repeater {
            model: card.items
            Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool hasSub: modelData.items !== undefined
                width: col.width
                height: modelData.sep ? Math.round(11 * card.s) : card.itemH
                Rectangle {
                    visible: row.modelData.sep === true
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.round(12 * card.s); width: parent.width - Math.round(24 * card.s); height: 1; color: Theme.separator
                }
                Rectangle {
                    visible: !row.modelData.sep
                    anchors.fill: parent
                    radius: Math.round(8 * card.s)
                    color: (ia.containsMouse || card.openSub === row.index) && !row.modelData.disabled ? Theme.selection : "transparent"
                    readonly property color ink: (ia.containsMouse || card.openSub === row.index) && !row.modelData.disabled ? "#FFFFFF" : Theme.label
                    opacity: row.modelData.disabled ? 0.38 : 1
                    Text { x: Math.round(7 * card.s); anchors.verticalCenter: parent.verticalCenter; text: row.modelData.checked ? "✓" : ""
                           color: parent.ink; font.family: Theme.font; font.pixelSize: Math.round(12 * card.s); font.weight: Font.DemiBold }
                    Text { x: Math.round(22 * card.s); anchors.verticalCenter: parent.verticalCenter; text: row.modelData.label || ""
                           color: parent.ink; font.family: Theme.font; font.pixelSize: Math.round(13 * card.s); font.letterSpacing: Theme.letterSpacing }
                    Text { anchors.right: parent.right; anchors.rightMargin: Math.round(9 * card.s); anchors.verticalCenter: parent.verticalCenter
                           text: row.hasSub ? "›" : card.glyphs(row.modelData.key)
                           color: row.hasSub ? parent.ink : Qt.rgba(parent.ink.r, parent.ink.g, parent.ink.b, 0.5)
                           font.family: Theme.font; font.pixelSize: Math.round((row.hasSub ? 16 : 13) * card.s) }
                    MouseArea {
                        id: ia
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !row.modelData.disabled
                        onContainsMouseChanged: if (containsMouse) card.openSub = row.hasSub ? row.index : -1
                        onClicked: { if (row.hasSub) card.openSub = row.index; else if (row.modelData.cmd) card.activated(row.modelData.cmd) }
                    }
                }
                Loader {
                    active: row.hasSub && card.openSub === row.index
                    x: row.width + card.pad - Math.round(2 * card.s); y: -card.pad
                    z: 10
                    source: "MenuPopup.qml"     // submenú (Loader por URL: un componente no puede instanciarse a sí mismo)
                    onLoaded: { item.sub = true; item.items = row.modelData.items; item.activated.connect((c) => card.activated(c)) }
                }
            }
        }
    }
}
