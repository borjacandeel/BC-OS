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
                { label: qsTr("Nueva carpeta"), cmd: "bc:desktopNewFolder" },
                { label: qsTr("Pegar"), cmd: "bc:desktopPaste" }, { sep: true },
                { label: qsTr("Ordenar por nombre"), cmd: "bc:desktopSort" },
                { label: qsTr("Editar widgets…"), cmd: "bc:widgetGallery" },
                { label: qsTr("Volver a colocar los widgets"), cmd: "bc:widgetsReset" }, { sep: true },
                { label: qsTr("Cambiar fondo de pantalla…"), cmd: "sway:exec bc-shell --app settings" },
                { label: Settings.widgets ? qsTr("Ocultar widgets") : qsTr("Mostrar widgets"), cmd: "bc:toggleWidgets" }
            ], Qt.point(m.x, m.y))
        }
    }
    property int renaming: -1
    onRenamingChanged: if (renaming < 0) UiState.desktopKeyboard = false
    property var info: null
    Timer { id: pasteReload; interval: 900; onTriggered: fm.reload() }
    // Panel «Obtener información» (como el del Finder): vidrio con nombre, tipo, tamaño, fechas y ubicación
    Item {
        visible: desk.info !== null && desk.info.name !== undefined
        z: 50; width: px(300); height: infoCol.height + px(28)
        x: (desk.width - width) / 2; y: (desk.height - height) / 3
        Glass { anchors.fill: parent; radius: px(14); tintBoost: 0.45 }
        Column {
            id: infoCol; x: px(16); y: px(14); width: parent.width - px(32); spacing: px(6)
            Text { text: desk.info ? desk.info.name : ""; color: Theme.label; font.family: Theme.font; font.pixelSize: px(15); font.weight: Font.Bold; width: parent.width; elide: Text.ElideMiddle }
            Text { text: desk.info ? desk.info.kind + " · " + desk.info.size : ""; color: Theme.labelSecondary; font.family: Theme.font; font.pixelSize: px(12) }
            Rectangle { width: parent.width; height: 1; color: Theme.separator }
            Repeater {
                model: desk.info ? [[qsTr("Ubicación"), desk.info.path], [qsTr("Creado"), desk.info.created], [qsTr("Modificado"), desk.info.modified]] : []
                Row { required property var modelData; spacing: px(8)
                      Text { width: px(80); text: modelData[0]; color: Theme.labelSecondary; font.family: Theme.font; font.pixelSize: px(12); horizontalAlignment: Text.AlignRight }
                      Text { width: infoCol.width - px(88); text: modelData[1]; color: Theme.label; font.family: Theme.font; font.pixelSize: px(12); wrapMode: Text.WrapAnywhere } }
            }
        }
        Rectangle { x: parent.width - px(30); y: px(10); width: px(20); height: width; radius: width / 2; color: Theme.fill
                    Text { anchors.centerIn: parent; text: "×"; color: Theme.label; font.pixelSize: px(13) }
                    MouseArea { anchors.fill: parent; anchors.margins: -px(4); onClicked: desk.info = null } }
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
                width: Math.min(parent.width, lbl.implicitWidth + px(12)); height: lbl.height + px(3); radius: height / 2   // óvalo azul de macOS
                color: desk.isSel(ic.name) ? Theme.selection : "transparent"
                TextInput {
                    id: ren; visible: desk.renaming === ic.index; anchors.centerIn: parent; width: desk.cellW - px(8)
                    horizontalAlignment: Text.AlignHCenter; color: "white"; selectionColor: Theme.textSelection; selectByMouse: true
                    font.family: Theme.font; font.pixelSize: px(12); font.weight: Font.Medium; clip: true
                    onVisibleChanged: if (visible) { text = ic.name; forceActiveFocus(); const d = text.lastIndexOf("."); select(0, d > 0 ? d : text.length) }
                    onAccepted: { if (text !== "" && text !== ic.name) fm.renameAt(ic.index, text); desk.renaming = -1; fm.reload() }
                    Keys.onEscapePressed: desk.renaming = -1
                    onActiveFocusChanged: if (!activeFocus && visible) accepted()
                }
                Text { id: lbl; visible: desk.renaming !== ic.index; anchors.centerIn: parent; width: Math.min(implicitWidth, desk.cellW - px(10)); text: ic.name; color: "white"
                       horizontalAlignment: Text.AlignHCenter; elide: Text.ElideMiddle; maximumLineCount: 2; wrapMode: Text.Wrap
                       font.family: Theme.font; font.pixelSize: px(12); font.weight: Font.Medium; style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.45) }
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                drag.target: ic; drag.threshold: px(6)
                onPressed: (m) => { if (!desk.isSel(ic.name) || (m.modifiers & Qt.ControlModifier)) desk.select(ic.name, m.modifiers & Qt.ControlModifier) }
                // Soltar sobre la Papelera del Dock: a la papelera (como macOS); si no, se guarda la nueva posición
                function overTrash() { const p = ic.mapToItem(null, ic.width / 2, ic.height / 2); const r = UiState.trashRect
                                       return r.width > 0 && p.x > r.x - 10 && p.x < r.x + r.width + 10 && p.y > r.y - 20 }
                onPositionChanged: if (drag.active) UiState.trashHover = overTrash()
                onReleased: {
                    if (!drag.active) return
                    const t = overTrash(); UiState.trashHover = false
                    if (t) { if (fm.trashAt(ic.index)) Sounds.play("trash"); fm.reload() }
                    else desk.savePos(ic.name, ic.x, ic.y)
                }
                onDoubleClicked: Quick.open(ic.filePath)
                onClicked: (m) => {
                    if (m.button !== Qt.RightButton) return
                    UiState.openContextMenu([
                        { label: qsTr("Abrir"), cmd: "bc:open:" + ic.filePath },
                        { label: qsTr("Mover a la papelera"), cmd: "bc:desktopTrash:" + ic.index }, { sep: true },
                        { label: qsTr("Obtener información"), cmd: "bc:desktopInfo:" + ic.filePath },
                        { label: qsTr("Renombrar"), cmd: "bc:desktopRename:" + ic.index },
                        { label: qsTr("Copiar «%1»").arg(ic.name), cmd: "bc:desktopCopy:" + ic.filePath },
                        { label: qsTr("Pegar"), cmd: "bc:desktopPaste" }, { sep: true },
                        { label: qsTr("Mostrar en Archivos"), cmd: "sway:exec bc-shell --app files" }
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
            else if (arg.indexOf("desktopCopy:") === 0) Quick.copyFiles([arg.substring(12)])
            else if (arg === "desktopPaste") { Quick.pasteFilesInto(fm.path); pasteReload.restart() }
            else if (arg.indexOf("desktopRename:") === 0) { desk.renaming = parseInt(arg.substring(14)); UiState.desktopKeyboard = true }
            else if (arg.indexOf("desktopInfo:") === 0) { desk.info = Quick.fileInfo(arg.substring(12)) }
            else if (arg === "toggleWidgets") Settings.widgets = !Settings.widgets
        }
    }
}
