import QtQuick
import BCShell

// Escritorio (como el de macOS): los elementos de ~/Escritorio en columnas desde arriba a la derecha.
// Clic selecciona (Ctrl: varios), arrastrar en vacío dibuja el rectángulo de selección, arrastrar un icono lo
// recoloca (posición guardada), doble clic abre y clic derecho muestra el menú contextual del escritorio o del ítem.
Item {
    id: desk
    anchors.fill: parent
    readonly property real s: Theme.s
    function px(v) { return Math.round(v * s) }
    readonly property real cellW: px(100)
    readonly property real cellH: px(96)
    property var selected: ({})
    function isSel(n) { return selected[n] === true }
    function select(n, add) { const m = add ? Object.assign({}, selected) : {}; if (add && m[n]) delete m[n]; else m[n] = true; selected = m }

    FileModel { id: fm; Component.onCompleted: place("desktop") }
    Timer { interval: 4000; running: desk.visible; repeat: true; onTriggered: fm.reload() }

    property var layout: { try { return JSON.parse(Settings.widgetLayout || "{}") } catch (e) { return {} } }
    function defaultPos(i) {
        const rows = Math.max(1, Math.floor((height - UiState.topInset - px(120)) / cellH))
        const col = Math.floor(i / rows), row = i % rows
        return Qt.point(width - px(16) - (col + 1) * cellW, UiState.topInset + px(12) + row * cellH)
    }
    function savePos(name, x, y) {
        const l = Object.assign({}, layout); l["icono:" + name] = [Math.round(x / s), Math.round(y / s)]
        Settings.widgetLayout = JSON.stringify(l)
    }

    // Vacío: deseleccionar, rectángulo de selección y menú contextual del escritorio
    MouseArea {
        id: bg
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        property point a
        property bool banding: false
        onPressed: (m) => { a = Qt.point(m.x, m.y); banding = m.button === Qt.LeftButton; if (!(m.modifiers & Qt.ControlModifier)) desk.selected = ({}) }
        onPositionChanged: (m) => {
            if (!banding) return
            band.x = Math.min(a.x, m.x); band.y = Math.min(a.y, m.y); band.width = Math.abs(m.x - a.x); band.height = Math.abs(m.y - a.y)
            const sel = {}
            for (let i = 0; i < icons.count; ++i) {
                const it = icons.itemAt(i)
                if (it && it.x + it.width > band.x && it.x < band.x + band.width && it.y + it.height > band.y && it.y < band.y + band.height) sel[it.name] = true
            }
            desk.selected = sel
        }
        onReleased: { banding = false; band.width = 0; band.height = 0 }
        onClicked: (m) => {
            UiState.closePopups()
            if (m.button === Qt.RightButton) UiState.openContextMenu([
                { label: qsTr("Nueva carpeta"), cmd: "bc:desktopNewFolder" }, { sep: true },
                { label: qsTr("Ordenar por nombre"), cmd: "bc:desktopSort" },
                { label: qsTr("Editar widgets…"), cmd: "bc:widgetGallery" },
                { label: qsTr("Volver a colocar los widgets"), cmd: "bc:widgetsReset" }, { sep: true },
                { label: qsTr("Cambiar fondo de pantalla…"), cmd: "sway:exec bc-shell --app settings" },
                { label: Settings.widgets ? qsTr("Ocultar widgets") : qsTr("Mostrar widgets"), cmd: "bc:toggleWidgets" }
            ], Qt.point(m.x, m.y))
        }
    }
    Rectangle { id: band; color: Qt.rgba(1, 1, 1, 0.12); border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.5); radius: 2 }

    Repeater {
        id: icons
        model: fm
        delegate: Item {
            id: ic
            required property int index
            required property string name
            required property string filePath
            required property string kind
            readonly property var saved: desk.layout["icono:" + name]
            x: saved ? saved[0] * desk.s : desk.defaultPos(index).x
            y: saved ? saved[1] * desk.s : desk.defaultPos(index).y
            width: desk.cellW; height: desk.cellH
            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: px(2); width: px(68); height: px(62); radius: px(6)
                        color: desk.isSel(ic.name) ? Qt.rgba(1, 1, 1, 0.16) : "transparent"; border.width: desk.isSel(ic.name) ? 1 : 0; border.color: Qt.rgba(1, 1, 1, 0.3) }
            FileGlyph { visible: ic.kind !== "imagen" || dthumb.status !== Image.Ready; anchors.horizontalCenter: parent.horizontalCenter; y: px(6); kind: ic.kind; path: ic.filePath; width: px(64); height: px(54) }
            Rectangle { visible: dthumb.status === Image.Ready; anchors.centerIn: dthumb; width: dthumb.paintedWidth + px(4); height: dthumb.paintedHeight + px(4); color: "white"; radius: px(2) }
            Image { id: dthumb; visible: status === Image.Ready; anchors.horizontalCenter: parent.horizontalCenter; y: px(8); width: px(60); height: px(52)
                    fillMode: Image.PreserveAspectFit; asynchronous: true; sourceSize: Qt.size(120, 104); source: ic.kind === "imagen" ? "file://" + ic.filePath : "" }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter; y: px(68)
                width: Math.min(parent.width, lbl.implicitWidth + px(10)); height: lbl.height + px(2); radius: px(4)
                color: desk.isSel(ic.name) ? Theme.selection : "transparent"
                Text { id: lbl; anchors.centerIn: parent; width: Math.min(implicitWidth, desk.cellW - px(10)); text: ic.name; color: "white"
                       horizontalAlignment: Text.AlignHCenter; elide: Text.ElideMiddle; maximumLineCount: 2; wrapMode: Text.Wrap
                       font.family: Theme.font; font.pixelSize: px(12); font.weight: Font.Medium; style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.45) }
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                drag.target: ic; drag.threshold: px(6)
                onPressed: (m) => { if (!desk.isSel(ic.name) || (m.modifiers & Qt.ControlModifier)) desk.select(ic.name, m.modifiers & Qt.ControlModifier) }
                onReleased: if (drag.active) desk.savePos(ic.name, ic.x, ic.y)
                onDoubleClicked: Quick.open(ic.filePath)
                onClicked: (m) => {
                    if (m.button !== Qt.RightButton) return
                    UiState.openContextMenu([
                        { label: qsTr("Abrir"), cmd: "bc:open:" + ic.filePath },
                        { label: qsTr("Mostrar en Archivos"), cmd: "sway:exec bc-shell --app files" }, { sep: true },
                        { label: qsTr("Mover a la papelera"), cmd: "bc:desktopTrash:" + ic.index }
                    ], ic.mapToItem(null, m.x, m.y))
                }
            }
        }
    }
    Connections {
        target: UiState
        function onCommand(kind, arg) {
            if (kind !== "bc") return
            if (arg === "desktopNewFolder") { let n = qsTr("carpeta sin título"), i = 2; while (!fm.newFolder(n) && i < 50) n = qsTr("carpeta sin título %1").arg(i++); fm.reload() }
            else if (arg === "desktopSort") { const l = Object.assign({}, desk.layout); for (const k in l) if (k.indexOf("icono:") === 0) delete l[k]; Settings.widgetLayout = JSON.stringify(l) }
            else if (arg.indexOf("desktopTrash:") === 0) { if (fm.trashAt(parseInt(arg.substring(13)))) Sounds.play("trash"); fm.reload() }
            else if (arg.indexOf("open:") === 0) Quick.open(arg.substring(5))
            else if (arg === "toggleWidgets") Settings.widgets = !Settings.widgets
        }
    }
}
