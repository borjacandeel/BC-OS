import QtQuick
import BCShell

// Aplicaciones (segundo icono del Dock / F4), calcado de macOS 27 Golden Gate: no ocupa la pantalla entera.
// Arriba, una barra de búsqueda en pastilla (520 pt); debajo, un panel de vidrio de 842×520 con las categorías en
// pastillas y la cuadrícula de 7 columnas (iconos de 62, nombre de 13) que se desplaza en vertical.
Item {
    id: lp
    anchors.fill: parent
    // Escala de la interfaz, reducida si la pantalla es pequeña (que el panel quepa entero sin tapar el Dock)
    readonly property real s: Math.min(Theme.s, (width - 40) / 842, (height - 190) / 618)
    function px(v) { return Math.round(v * s) }
    property var all: []
    property string cat: ""
    readonly property var apps: cat === "" ? all : all.filter(a => a.category === cat)
    readonly property int cols: 7
    signal launch(string id, string name)
    signal done()
    function reset() { field.text = ""; cat = ""; all = Apps.search(""); grid.contentY = 0; field.forceActiveFocus() }

    // Clic fuera: se cierra (el escritorio se ve detrás, sin oscurecer)
    MouseArea { anchors.fill: parent; onClicked: lp.done() }

    property real zoom: 1
    onVisibleChanged: if (visible) { zoomOut.stop(); zoom = 0.94; zoomIn.restart() }
    NumberAnimation { id: zoomIn; target: lp; property: "zoom"; to: 1; duration: Theme.d(Theme.durLaunchpad); easing.type: Theme.easeEmphasized }
    function leave() { zoomIn.stop(); zoomOut.restart() }
    NumberAnimation { id: zoomOut; target: lp; property: "zoom"; to: 0.96; duration: Theme.d(200); easing.type: Easing.InCubic }

    Item {
        id: box
        width: px(842); height: px(84) + px(14) + px(520)
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(px(40), (parent.height - height) / 2 - px(40))
        scale: lp.zoom
        MouseArea { anchors.fill: parent }   // no cerrar al pulsar dentro

        // Barra de búsqueda
        Item {
            id: search
            anchors.horizontalCenter: parent.horizontalCenter
            width: px(520); height: px(84)
            Glass { anchors.fill: parent; radius: height / 2; tintBoost: 0.55 }
            Icon { x: px(32); anchors.verticalCenter: parent.verticalCenter; name: "view-app-grid-symbolic"; size: px(24); color: Theme.labelSecondary }
            TextInput {
                cursorDelegate: TextCursor {}
                id: field; x: px(74); width: parent.width - px(110); anchors.verticalCenter: parent.verticalCenter
                color: Theme.label; font.family: Theme.font; font.pixelSize: px(22); focus: true; selectionColor: Theme.selection
                onTextChanged: { lp.all = Apps.search(text); grid.contentY = 0 }
                Keys.onEscapePressed: lp.done()
                Keys.onReturnPressed: if (lp.apps.length) lp.launch(lp.apps[0].id, lp.apps[0].name)
                Text { visible: !parent.text; text: qsTr("Aplicaciones"); color: Theme.labelSecondary; font: parent.font }
            }
        }

        // Panel con categorías y cuadrícula
        Item {
            id: panel
            y: search.height + px(14); width: parent.width; height: px(520)
            Glass { anchors.fill: parent; radius: px(40); tintBoost: 0.35 }
            Flickable {
                id: chipsFlick
                x: px(18); y: px(18); width: parent.width - px(36); height: px(32)
                contentWidth: chips.width; clip: true; boundsBehavior: Flickable.StopAtBounds
                Row {
                    id: chips; spacing: px(8)
                    Repeater {
                        model: [ { k: "", t: qsTr("Todas") }, { k: "utilidades", t: qsTr("Utilidades") }, { k: "productividad", t: qsTr("Productividad") },
                                 { k: "creatividad", t: qsTr("Creatividad") }, { k: "internet", t: qsTr("Internet") }, { k: "desarrollo", t: qsTr("Desarrollo") },
                                 { k: "juegos", t: qsTr("Juegos") }, { k: "sistema", t: qsTr("Sistema") } ]
                        Rectangle {
                            required property var modelData
                            visible: modelData.k === "" || lp.all.some(a => a.category === modelData.k)
                            width: visible ? ct.implicitWidth + px(24) : 0; height: px(30); radius: height / 2
                            color: lp.cat === modelData.k ? (Theme.dark ? Qt.rgba(1, 1, 1, 0.28) : Qt.rgba(0, 0, 0, 0.14))
                                                         : (Theme.dark ? Qt.rgba(1, 1, 1, cm.containsMouse ? 0.16 : 0.08) : Qt.rgba(0, 0, 0, cm.containsMouse ? 0.08 : 0.04))
                            Text { id: ct; anchors.centerIn: parent; text: modelData.t; color: Theme.label
                                   font.family: Theme.font; font.pixelSize: px(14); font.weight: Font.Medium }
                            MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; onClicked: { lp.cat = modelData.k; grid.contentY = 0 } }
                        }
                    }
                }
            }
            GridView {
                id: grid
                x: px(18); y: px(64); width: parent.width - px(36); height: parent.height - px(72)
                cellWidth: width / lp.cols; cellHeight: px(104)
                clip: true; boundsBehavior: Flickable.StopAtBounds
                model: lp.apps
                delegate: Item {
                    required property var modelData
                    width: grid.cellWidth; height: grid.cellHeight
                    Image {
                        id: ic; anchors.horizontalCenter: parent.horizontalCenter; y: px(6)
                        width: px(62); height: width; sourceSize: Qt.size(128, 128); smooth: true; mipmap: true; asynchronous: true
                        source: modelData.iconPath ? "file://" + modelData.iconPath : (Quick.iconPath("application-x-executable") !== "" ? "file://" + Quick.iconPath("application-x-executable") : "qrc:/BCShell/apps/text-x-script.svg")
                        scale: am.pressed ? 0.9 : (am.containsMouse ? 1.04 : 1)
                        Behavior on scale { NumberAnimation { duration: Theme.d(Theme.durHover); easing.type: Theme.easeStandard } }
                    }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.top: ic.bottom; anchors.topMargin: px(8); width: parent.width - px(8)
                           horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: modelData.name; color: Theme.label
                           font.family: Theme.font; font.pixelSize: px(13) }
                    MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; onClicked: lp.launch(modelData.id, modelData.name) }
                }
            }
            Text { visible: lp.apps.length === 0; anchors.centerIn: grid; text: qsTr("Sin resultados"); color: Theme.labelSecondary
                   font.family: Theme.font; font.pixelSize: px(15) }
        }
    }
}
