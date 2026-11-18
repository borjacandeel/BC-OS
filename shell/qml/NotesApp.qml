import QtQuick
import BCShell

// Notas (como la app de macOS): barra lateral con carpetas (Notas, Eliminadas recientemente), lista de notas con título,
// fecha y fragmento, y editor a la derecha. Guarda solo, al escribir, en ~/.local/share/bc/notas.
AppWindow {
    id: win
    sidebarWidth: 220
    width: 980
    height: 620
    titlebarHeight: 52
    title: qsTr("Notas")
    property string folder: "notas"           // notas | eliminadas
    property string current: ""
    property string query: ""
    readonly property var list: (folder === "notas" ? Notes.notes : Notes.deleted).filter(n => query === "" || (n.title + " " + n.snippet).toLowerCase().indexOf(query.toLowerCase()) >= 0)
    readonly property color amber: "#E5B000"

    // La primera línea se muestra como título (negrita grande), como en Notas de macOS
    function esc(s) { return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;") }
    function toRich(t) {
        const lines = t.split("\n")
        let h = "<p style='font-size:22px; font-weight:700; margin-bottom:6px'>" + esc(lines[0] || "") + "</p>"
        for (let i = 1; i < lines.length; ++i) h += "<p>" + (esc(lines[i]) || "&nbsp;") + "</p>"
        return h
    }
    function open(id) { saveNow(); current = id; loading = true; editor.text = id !== "" ? toRich(Notes.text(id)) : ""; loading = false; editor.cursorPosition = editor.length }
    property bool loading: false
    function saveNow() { if (current !== "" && folder === "notas" && dirty) { Notes.save(current, editor.getText(0, editor.length).replace(/\u2029/g, "\n").replace(/\u00a0/g, "")); dirty = false } }
    property bool dirty: false
    function newNote() { folder = "notas"; open(Notes.create()); editor.forceActiveFocus() }
    Timer { id: autosave; interval: 700; onTriggered: win.saveNow() }
    Component.onCompleted: { if (Notes.notes.length) open(Notes.notes[0].id); if (AppConfig.demo === "buscar") { find.open = true; findIn.text = "macOS" } }
    Component.onDestruction: saveNow()

    titlebarContent: [
        Row {
            x: 230; anchors.verticalCenter: parent.verticalCenter; spacing: 6
            Rectangle {
                width: 30; height: 26; radius: 7; color: dm.containsMouse ? Theme.tileFill : "transparent"; opacity: win.current !== "" ? 1 : 0.35
                Icon { anchors.centerIn: parent; name: "user-trash-symbolic"; size: 16; color: Theme.textSecondary }
                MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; enabled: win.current !== ""
                            onClicked: { const id = win.current; win.current = ""; editor.text = ""; Notes.remove(id); if (win.list.length) win.open(win.list[0].id) } }
            }
        },
        Row {
            x: notesList.x + notesList.width + 16; anchors.verticalCenter: parent.verticalCenter; spacing: 6
            Rectangle {
                width: 30; height: 26; radius: 7; color: nm.containsMouse ? Theme.tileFill : "transparent"
                Icon { anchors.centerIn: parent; name: "document-edit-symbolic"; size: 16; color: Theme.textSecondary }
                MouseArea { id: nm; anchors.fill: parent; hoverEnabled: true; onClicked: win.newNote() }
            }
        },
        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
            width: 200; height: 26; radius: 7; color: Theme.tileFill
            Icon { x: 7; anchors.verticalCenter: parent.verticalCenter; name: Icons.search; size: 13; color: Theme.textSecondary }
            TextInput { x: 26; width: parent.width - 32; anchors.verticalCenter: parent.verticalCenter; color: Theme.textPrimary
                        font.family: Theme.fontFamily; font.pixelSize: 12; clip: true; onTextChanged: win.query = text
                        Text { visible: !parent.text; text: qsTr("Buscar"); color: Theme.textSecondary; font: parent.font } }
        }
    ]

    // ---- Barra lateral: carpetas --------------------------------------------------------------
    Rectangle {
        id: side
        y: -win.titlebarHeight; width: 220; height: parent.height + win.titlebarHeight
        color: Theme.gg ? "transparent" : Theme.sidebarFill
        SidebarGlass { anchors.fill: parent; active: win.active; z: -1 }
        Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.hairline }
        Column {
            y: win.titlebarHeight + 8; x: 10; width: parent.width - 20; spacing: 2
            Text { leftPadding: 8; bottomPadding: 4; text: qsTr("En este equipo"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold }
            Repeater {
                model: [ { k: "notas", t: qsTr("Notas"), i: "folder-symbolic", n: Notes.notes.length },
                         { k: "eliminadas", t: qsTr("Eliminadas recientemente"), i: "user-trash-symbolic", n: Notes.deleted.length } ]
                Rectangle {
                    required property var modelData
                    width: parent.width; height: 30; radius: 7
                    color: win.folder === modelData.k ? Theme.tileFill : (fm.containsMouse ? Qt.rgba(0.5, 0.5, 0.5, 0.08) : "transparent")
                    Icon { x: 9; anchors.verticalCenter: parent.verticalCenter; name: modelData.i; size: 16; color: win.active ? win.amber : Theme.textSecondary }
                    Text { x: 34; anchors.verticalCenter: parent.verticalCenter; text: modelData.t; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13; width: parent.width - 58; elide: Text.ElideRight }
                    Text { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: modelData.n; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                    MouseArea { id: fm; anchors.fill: parent; hoverEnabled: true; onClicked: { win.saveNow(); win.folder = modelData.k; win.current = ""; editor.text = ""; if (win.list.length) win.open(win.list[0].id) } }
                }
            }
        }
        Rectangle {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 12; x: 12; width: nf.implicitWidth + 30; height: 26; radius: 7
            color: nfm.containsMouse ? Theme.tileFill : "transparent"
            Text { id: nf; anchors.centerIn: parent; text: "⊕  " + qsTr("Nota nueva"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
            MouseArea { id: nfm; anchors.fill: parent; hoverEnabled: true; onClicked: win.newNote() }
        }
    }

    // ---- Lista de notas -----------------------------------------------------------------------
    Rectangle {
        id: notesList
        x: side.width; width: 260; height: parent.height; color: "transparent"
        Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.hairline }
        ListView {
            anchors.fill: parent; anchors.margins: 8; clip: true; spacing: 2
            model: win.list
            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width; height: 62; radius: 8
                color: modelData.id === win.current ? (win.active ? win.amber : Theme.tileFill) : "transparent"
                readonly property color ink: modelData.id === win.current && win.active ? "#1D1D1F" : Theme.textPrimary
                Column {
                    x: 12; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 24; spacing: 2
                    Text { text: modelData.title; color: parent.parent.ink; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Bold; width: parent.width; elide: Text.ElideRight }
                    Row {
                        spacing: 8; width: parent.width
                        Text { text: modelData.date; color: parent.parent.parent.ink; opacity: 0.8; font.family: Theme.fontFamily; font.pixelSize: 12 }
                        Text { text: modelData.snippet || qsTr("Sin texto adicional"); color: parent.parent.parent.ink; opacity: 0.6; font.family: Theme.fontFamily; font.pixelSize: 12; width: parent.width - 70; elide: Text.ElideRight }
                    }
                }
                MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (m) => { if (m.button === Qt.RightButton && win.folder === "eliminadas") Notes.restore(modelData.id); else win.open(modelData.id) } }
            }
            Text { visible: win.list.length === 0; anchors.centerIn: parent; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 13
                   text: win.folder === "notas" ? qsTr("No hay notas") : qsTr("No hay notas eliminadas") }
        }
    }

    // ---- Editor -------------------------------------------------------------------------------
    Flickable {
        id: flick
        OverlayScroll { flick: flick }
        x: notesList.x + notesList.width + 1; width: parent.width - x; height: parent.height
        contentHeight: editor.height + 60; clip: true; boundsBehavior: Flickable.DragAndOvershootBounds
        Text { visible: win.current !== ""; anchors.horizontalCenter: parent.horizontalCenter; y: 10; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11
               text: { const n = win.list.find(x => x.id === win.current); return n ? n.modified.toLocaleString(Qt.locale(AppConfig.language), "d 'de' MMMM 'de' yyyy, H:mm") : "" } }
        TextEdit {
            id: editor
            x: 28; y: 34; width: flick.width - 56
            visible: win.current !== ""
            readOnly: win.folder !== "notas"
            wrapMode: TextEdit.Wrap; selectByMouse: true
            color: Theme.textPrimary; selectionColor: Qt.rgba(0.9, 0.7, 0, 0.45); selectedTextColor: Theme.textPrimary
            font.family: Theme.fontFamily; font.pixelSize: 14
            textFormat: TextEdit.RichText
            onTextChanged: if (!win.loading && activeFocus) { win.dirty = true; autosave.restart() }
        }
        Text { visible: win.current === ""; anchors.centerIn: parent; text: qsTr("Ninguna nota seleccionada"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 14 }
        // Resaltado amarillo de las coincidencias de la búsqueda (como macOS); la actual da un pequeño salto
        Repeater {
            model: find.matches
            Rectangle {
                required property var modelData
                required property int index
                readonly property rect a: { find.matches; editor.width; editor.contentHeight; editor.text; return editor.positionToRectangle(modelData) }
                readonly property rect b: { find.matches; editor.width; editor.contentHeight; editor.text; return editor.positionToRectangle(modelData + find.query.length) }
                x: editor.x + a.x - 2; y: editor.y + a.y - 1
                width: (b.y === a.y ? b.x - a.x : editor.width - a.x) + 4; height: a.height + 2; radius: 4
                z: -1
                color: index === find.cur ? "#FFD60A" : Qt.rgba(1, 0.84, 0.04, 0.38)
                scale: 1
                SequentialAnimation on scale {
                    running: index === find.cur
                    NumberAnimation { to: 1.35; duration: Theme.d(90); easing.type: Easing.OutQuad }
                    NumberAnimation { to: 1.0; duration: Theme.d(160); easing.type: Easing.OutBack }
                }
            }
        }
    }

    // ---- Buscar en la nota (Ctrl+F) ---------------------------------------------------------------
    Rectangle {
        id: find
        property bool open: false
        property string query: ""
        property var matches: []
        property int cur: 0
        function update() {
            const out = []
            if (query.length > 0) {
                // Posiciones del documento (no del texto plano: los saltos de párrafo del texto enriquecido no coinciden)
                const q = query.toLowerCase(), n = q.length, L = editor.length
                for (let i = 0; i + n <= L && out.length < 500; ++i)
                    if (editor.getText(i, i + n).toLowerCase() === q) { out.push(i); i += n - 1 }
            }
            matches = out; cur = 0; reveal()
        }
        function reveal() {
            if (!matches.length) return
            const r = editor.positionToRectangle(matches[cur])
            flick.contentY = Math.max(0, Math.min(flick.contentHeight - flick.height, editor.y + r.y - flick.height / 3))
        }
        function step(d) { if (!matches.length) return; cur = (cur + d + matches.length) % matches.length; reveal() }
        visible: open && win.current !== ""
        x: flick.x + flick.width - width - 14; y: 10; z: 20
        width: 250; height: 30; radius: height / 2
        color: Theme.dark ? Qt.rgba(0.17, 0.17, 0.19, 0.96) : Qt.rgba(1, 1, 1, 0.96)
        border.width: 1; border.color: findIn.activeFocus ? Theme.accent : Theme.separator
        TextInput {
            id: findIn
            x: 12; width: parent.width - 80; anchors.verticalCenter: parent.verticalCenter
            color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13; clip: true
            selectionColor: Theme.accent; selectByMouse: true
            onTextChanged: { find.query = text; find.update() }
            Keys.onReturnPressed: (e) => find.step((e.modifiers & Qt.ShiftModifier) ? -1 : 1)
            Keys.onEscapePressed: { find.open = false; find.query = ""; find.matches = []; editor.forceActiveFocus() }
            Text { visible: !findIn.text; anchors.verticalCenter: parent.verticalCenter; text: qsTr("Buscar en la nota")
                   color: Theme.textSecondary; font: findIn.font }
        }
        Text { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
               visible: find.query.length > 0; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11
               text: find.matches.length ? (find.cur + 1) + " / " + find.matches.length : qsTr("0 resultados") }
    }
    Shortcut { sequence: "Ctrl+F"; onActivated: { find.open = true; findIn.forceActiveFocus(); findIn.selectAll() } }

    Shortcut { sequence: "Ctrl+N"; onActivated: win.newNote() }
    Connections {
        target: AppActions
        function onActionInvoked(a) {
            if (a === "close") win.closeRequested()
            else if (a === "newNote") win.newNote()
            else if (a === "selectAll") editor.selectAll()
            else if (a === "copy") editor.copy()
            else if (a === "paste") editor.paste()
            else if (a === "cut") editor.cut()
        }
    }
}
