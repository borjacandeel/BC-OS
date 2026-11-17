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
    Component.onCompleted: { if (Notes.notes.length) open(Notes.notes[0].id) }
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
        x: notesList.x + notesList.width + 1; width: parent.width - x; height: parent.height
        contentHeight: editor.height + 60; clip: true; boundsBehavior: Flickable.StopAtBounds
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
    }

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
