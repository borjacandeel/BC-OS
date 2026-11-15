import QtQuick
import BCShell

// Aplicaciones (segundo icono del Dock / F4): rejilla a pantalla completa sobre el fondo desenfocado,
// con búsqueda arriba y páginas de 7×5 que se pasan con la rueda, flechas o arrastrando.
Item {
    id: lp
    anchors.fill: parent
    readonly property real s: Theme.s
    function px(v) { return Math.round(v * s) }
    property var all: []
    property string cat: ""
    readonly property var apps: cat === "" ? all : all.filter(a => a.category === cat)
    readonly property int cols: 7
    readonly property int rows: 5
    readonly property int perPage: cols * rows
    readonly property int pages: Math.max(1, Math.ceil(apps.length / perPage))
    property int page: 0
    signal launch(string id, string name)
    signal done()
    function reset() { field.text = ""; cat = ""; all = Apps.search(""); page = 0; field.forceActiveFocus() }

    // Fondo: el escritorio desenfocado y oscurecido
    Glass { anchors.fill: parent; radius: 0; shadow: false; rim: false; tintBoost: 0.25 }
    MouseArea { anchors.fill: parent; onClicked: lp.done()
                onWheel: (w) => { if (w.angleDelta.y < 0 || w.angleDelta.x < 0) lp.page = Math.min(lp.pages - 1, lp.page + 1); else lp.page = Math.max(0, lp.page - 1) } }

    Item {
        id: search
        anchors.horizontalCenter: parent.horizontalCenter; y: px(48)
        width: px(420); height: px(36)
        Glass { anchors.fill: parent; radius: height / 2; tintBoost: 0.3; shadow: false }
        Icon { x: px(10); anchors.verticalCenter: parent.verticalCenter; name: Icons.search; size: px(14); color: Qt.rgba(1, 1, 1, 0.7) }
        TextInput {
            id: field; x: px(30); width: parent.width - px(40); anchors.verticalCenter: parent.verticalCenter
            color: "white"; font.family: Theme.font; font.pixelSize: px(13); focus: true
            onTextChanged: { lp.all = Apps.search(text); lp.page = 0 }
            Keys.onEscapePressed: lp.done()
            Keys.onReturnPressed: if (lp.apps.length) lp.launch(lp.apps[0].id, lp.apps[0].name)
            Keys.onRightPressed: lp.page = Math.min(lp.pages - 1, lp.page + 1)
            Keys.onLeftPressed: lp.page = Math.max(0, lp.page - 1)
            Text { visible: !parent.text; text: qsTr("Buscar"); color: Qt.rgba(1, 1, 1, 0.55); font: parent.font }
        }
    }

    // Entrada: la rejilla se acerca desde un poco más grande (el fondo no se escala)
    property real zoom: 1
    onVisibleChanged: if (visible) { zoomOut.stop(); zoom = 1.08; zoomIn.restart() }
    NumberAnimation { id: zoomIn; target: lp; property: "zoom"; to: 1; duration: Theme.d(Theme.durLaunchpad); easing.type: Theme.easeEmphasized }
    // Salida: la rejilla vuelve a agrandarse mientras se desvanece (como al cerrar Launchpad)
    function leave() { zoomIn.stop(); zoomOut.restart() }
    NumberAnimation { id: zoomOut; target: lp; property: "zoom"; to: 1.06; duration: Theme.d(220); easing.type: Easing.InCubic }
    // Categorías (vista Aplicaciones de Tahoe/Golden Gate)
    Row {
        id: chips
        anchors.horizontalCenter: parent.horizontalCenter; y: px(98); spacing: px(8)
        Repeater {
            model: [ { k: "", t: qsTr("Todas") }, { k: "productividad", t: qsTr("Productividad") }, { k: "creatividad", t: qsTr("Creatividad") },
                     { k: "internet", t: qsTr("Internet") }, { k: "utilidades", t: qsTr("Utilidades") }, { k: "desarrollo", t: qsTr("Desarrollo") },
                     { k: "juegos", t: qsTr("Juegos") }, { k: "sistema", t: qsTr("Sistema") } ]
            Rectangle {
                required property var modelData
                visible: modelData.k === "" || lp.all.some(a => a.category === modelData.k)
                width: ct.implicitWidth + px(24); height: px(28); radius: height / 2
                color: lp.cat === modelData.k ? Qt.rgba(1, 1, 1, 0.92) : Qt.rgba(1, 1, 1, cm.containsMouse ? 0.22 : 0.12)
                Text { id: ct; anchors.centerIn: parent; text: modelData.t; color: lp.cat === modelData.k ? "#1D1D1F" : "white"
                       font.family: Theme.font; font.pixelSize: px(12); font.weight: Font.DemiBold }
                MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; onClicked: { lp.cat = modelData.k; lp.page = 0 } }
            }
        }
    }
    Item {
        id: viewport
        scale: lp.zoom
        x: px(160); y: px(150); width: parent.width - px(320); height: parent.height - px(280)
        clip: true
        Row {
            id: strip
            x: -lp.page * viewport.width + dragOffset
            property real dragOffset: 0
            Behavior on x { enabled: !dragMa.pressed; NumberAnimation { duration: Theme.d(Theme.durSpaceSwitch); easing.type: Theme.easeEmphasized } }
            Repeater {
                model: lp.pages
                delegate: Grid {
                    required property int index
                    readonly property int pg: index
                    width: viewport.width; height: viewport.height
                    columns: lp.cols
                    Repeater {
                        model: lp.apps.slice(pg * lp.perPage, (pg + 1) * lp.perPage)
                        delegate: Item {
                            required property var modelData
                            width: viewport.width / lp.cols; height: viewport.height / lp.rows
                            Image {
                                id: ic; anchors.horizontalCenter: parent.horizontalCenter; y: (parent.height - height - px(26)) / 2
                                width: px(84); height: width; sourceSize: Qt.size(168, 168); smooth: true; asynchronous: true
                                source: modelData.iconPath ? "file://" + modelData.iconPath : "qrc:/BCShell/apps/system-file-manager.svg"
                                scale: am.pressed ? 0.9 : 1
                                Behavior on scale { NumberAnimation { duration: 90 } }
                            }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.top: ic.bottom; anchors.topMargin: px(8); width: parent.width - px(12)
                                   horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: modelData.name; color: "white"
                                   font.family: Theme.font; font.pixelSize: px(12); style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.35) }
                            MouseArea { id: am; anchors.fill: parent; onClicked: lp.launch(modelData.id, modelData.name) }
                        }
                    }
                }
            }
        }
        MouseArea {
            id: dragMa; anchors.fill: parent; z: -1
            property real sx: 0
            onPressed: (m) => sx = m.x
            onPositionChanged: (m) => strip.dragOffset = m.x - sx
            onReleased: { if (strip.dragOffset < -px(80)) lp.page = Math.min(lp.pages - 1, lp.page + 1); else if (strip.dragOffset > px(80)) lp.page = Math.max(0, lp.page - 1); strip.dragOffset = 0 }
            onClicked: if (Math.abs(strip.dragOffset) < 4) lp.done()
        }
    }
    // Puntos de página
    Row {
        anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: px(110); spacing: px(10)
        visible: lp.pages > 1
        Repeater { model: lp.pages
                   Rectangle { required property int index; width: px(7); height: width; radius: width / 2; color: "white"; opacity: index === lp.page ? 0.95 : 0.35
                               MouseArea { anchors.fill: parent; anchors.margins: -px(4); onClicked: lp.page = index } } }
    }
}
