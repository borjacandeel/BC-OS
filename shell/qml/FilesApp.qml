import QtQuick
import BCShell

// BC Archivos: sidebar, ruta, búsqueda y cuadrícula (aplicación independiente).
AppWindow {
    id: win
    width: 995
    height: 520
    titlebarHeight: 60
    title: qsTr("Archivos")
    property int current: -1
    readonly property var places: [
        { key: "home", name: qsTr("Inicio"), icon: Icons.home },
        { key: "desktop", name: qsTr("Escritorio"), icon: Icons.desktop },
        { key: "documents", name: qsTr("Documentos"), icon: Icons.document },
        { key: "downloads", name: qsTr("Descargas"), icon: Icons.download },
        { key: "pictures", name: qsTr("Imágenes"), icon: Icons.image },
        { key: "music", name: qsTr("Música"), icon: Icons.music }
    ]
    Connections { target: Files; function onPathChanged() { win.current = -1 } }
    Component.onCompleted: { if (AppConfig.openArg === "trash") Files.openTrash(); else if (AppConfig.openArg !== "") Files.open(AppConfig.openArg) }

    titlebarContent: [
        Row {
            x: 92; anchors.verticalCenter: parent.verticalCenter; spacing: 5
            Repeater {
                model: [
                    { name: Icons.chevronLeft, on: Files.canBack, act: 0 },
                    { name: Icons.chevronRight, on: Files.canForward, act: 1 },
                    { name: Icons.chevronUp, on: Files.canUp, act: 2 }
                ]
                Rectangle {
                    width: 39; height: 37; radius: 10
                    color: modelData.on ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05)
                    Icon { anchors.centerIn: parent; name: modelData.name; size: 22;
                           color: modelData.on ? Theme.textPrimary : Theme.textSecondary; opacity: modelData.on ? 1 : 0.5 }
                    MouseArea {
                        anchors.fill: parent; enabled: modelData.on
                        onClicked: modelData.act === 0 ? Files.back() : (modelData.act === 1 ? Files.forward() : Files.up())
                    }
                }
            }
        },
        Item {
            id: crumbBox
            x: 242; width: 380; height: parent.height; clip: true
            Row {
                id: crumbRow
                x: Math.min(0, crumbBox.width - width)
                anchors.verticalCenter: parent.verticalCenter; spacing: 6
                Repeater {
                    model: Files.crumbs
                    delegate: Row {
                        spacing: 6
                        anchors.verticalCenter: parent.verticalCenter
                        Icon { visible: index > 0; name: Icons.chevronRight; size: 16;
                               anchors.verticalCenter: parent.verticalCenter; color: Theme.textSecondary }
                        Item {
                            width: crumbLabel.width + (modelData.home ? 30 : 0); height: 30
                            anchors.verticalCenter: parent.verticalCenter
                            Icon { visible: modelData.home; name: Icons.home; size: 22;
                                   anchors.verticalCenter: parent.verticalCenter }
                            Text {
                                id: crumbLabel
                                x: modelData.home ? 30 : 0
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.home ? "" : modelData.name
                                color: index === Files.crumbs.length - 1 ? Theme.textPrimary : Theme.textSecondary
                                font.family: Theme.fontFamily; font.pixelSize: 16
                                font.weight: index === Files.crumbs.length - 1 ? Font.DemiBold : Font.Normal
                            }
                            MouseArea { anchors.fill: parent; onClicked: Files.open(modelData.path) }
                        }
                    }
                }
            }
        },
        Rectangle {
            x: 640; width: 339; height: 38; radius: 19
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(1, 1, 1, 0.10)
            Icon { x: 15; anchors.verticalCenter: parent.verticalCenter; name: Icons.search; size: 24; }
            TextInput {
                id: search
                x: 49; width: parent.width - 49 - 36; anchors.verticalCenter: parent.verticalCenter
                text: Files.filter
                onTextEdited: Files.filter = text
                color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 16
                selectionColor: Theme.accent; clip: true
                Keys.onEscapePressed: { Files.filter = ""; focus = false }
                Text { visible: !search.text && !search.activeFocus; text: qsTr("Buscar")
                       color: Theme.textSecondary; font: search.font }
            }
            Item {
                visible: search.text !== ""
                x: parent.width - 34; width: 28; height: 28; anchors.verticalCenter: parent.verticalCenter
                Icon { anchors.centerIn: parent; name: Icons.closeX; size: 14; }
                MouseArea { anchors.fill: parent; onClicked: Files.filter = "" }
            }
        }
    ]

    Item {
        id: fx
        anchors.fill: parent
        focus: true
    // Barra lateral
    Rectangle {
        y: 0
        width: 239
        height: parent.height
        color: Theme.sidebarFill
        Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.hairline }

        Repeater {
            model: win.places
            delegate: Rectangle {
                x: 12; y: 14 + index * 46.5
                width: 213; height: 46; radius: Theme.radiusControl
                color: Files.path === Files.placePath(modelData.key) ? Theme.accentSelected : (hov.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                Icon { x: 16; anchors.verticalCenter: parent.verticalCenter; name: modelData.icon; size: 24;
                       filled: Files.path === Files.placePath(modelData.key) }
                Text { x: 59; anchors.verticalCenter: parent.verticalCenter; text: modelData.name
                       color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 16 }
                MouseArea { id: hov; anchors.fill: parent; hoverEnabled: true; onClicked: Files.place(modelData.key) }
            }
        }
        Rectangle { x: 12; y: 313; width: 213; height: 1; color: Theme.hairline }
        Rectangle {
            x: 12; y: 332; width: 213; height: 46; radius: Theme.radiusControl
            color: Files.inTrash ? Theme.accentSelected : (trashHov.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
            Icon { x: 16; anchors.verticalCenter: parent.verticalCenter; name: Icons.trash; size: 24; filled: Files.inTrash }
            Text { x: 59; anchors.verticalCenter: parent.verticalCenter; text: qsTr("Papelera")
                   color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 16 }
            MouseArea { id: trashHov; anchors.fill: parent; hoverEnabled: true; onClicked: Files.openTrash() }
        }
    }

    // Cuadrícula de archivos (directorio real)
    Item {
        x: 239; y: 0
        width: parent.width - 239; height: parent.height
        GridView {
            id: grid
            anchors.fill: parent
            anchors.margins: 12
            clip: true
            cellWidth: Math.floor(width / 4)
            cellHeight: 136
            model: Files
            boundsBehavior: Flickable.StopAtBounds
            delegate: Item {
                id: cell
                required property int index
                required property string name
                required property string kind
                width: grid.cellWidth; height: grid.cellHeight
                Rectangle {
                    anchors.fill: parent; anchors.margins: 4; radius: Theme.radiusControl
                    color: win.current === cell.index ? Theme.accentSelected : (ma.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                }
                FileGlyph { kind: cell.kind; anchors.horizontalCenter: parent.horizontalCenter; y: 6 }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 88; width: parent.width - 16
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideMiddle
                    text: cell.name
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                }
                MouseArea {
                    id: ma
                    anchors.fill: parent; hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (m) => {
                        win.current = cell.index
                        fx.forceActiveFocus()
                        if (m.button === Qt.RightButton) { const p = mapToItem(fx, m.x, m.y); fx.showMenu(p.x, p.y, true) }
                    }
                    onDoubleClicked: Files.activate(cell.index)
                }
            }
        }
        Column {
            visible: Files.count === 0
            anchors.centerIn: parent; spacing: 8
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: !Files.available ? qsTr("La carpeta no existe o no se puede leer")
                      : (Files.filter !== "" ? qsTr("Sin resultados") : qsTr("Carpeta vacía"))
                color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 17; font.weight: Font.DemiBold
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: Files.available && Files.filter !== ""
                text: qsTr("Ningún nombre contiene «%1»").arg(Files.filter)
                color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 14
            }
        }
    }

    // ---- Operaciones: menú contextual, nombre y teclado ----
    property bool ctxOnItem: false
    property string nameMode: ""   // "new" | "rename"
    Connections {
        target: AppActions
        function onActionInvoked(a) {
            if (a === "newFolder") fx.openName("new")
            else if (a === "open") Files.activate(win.current)
            else if (a === "rename" && win.current >= 0 && !Files.inTrash) fx.openName("rename")
            else if (a === "trash" && win.current >= 0 && !Files.inTrash) Files.trashAt(win.current)
            else if (a === "emptyTrash") Files.emptyTrash()
            else if (a.indexOf("go-") === 0) { const k = a.substring(3); k === "trash" ? Files.openTrash() : Files.place(k) }
        }
    }
    Shortcut { sequence: "Ctrl+Shift+N"; onActivated: fx.openName("new") }
    Keys.onDeletePressed: if (win.current >= 0 && !Files.inTrash) Files.trashAt(win.current)
    Keys.onPressed: (e) => { if (e.key === Qt.Key_F2 && win.current >= 0 && !Files.inTrash) { openName("rename"); e.accepted = true } }
    Connections { target: Files; function onOperationFailed(m) { Notifications.push(qsTr("Archivos"), qsTr("No se pudo completar la operación"), m, "", 4000) } }

    function showMenu(x, y, onItem) {
        ctxOnItem = onItem
        ctx.x = Math.min(x, fx.width - ctx.width - 6)
        ctx.y = Math.min(y, fx.height - ctx.height - 6)
        ctx.open = true
    }
    function openName(mode) {
        nameMode = mode
        nameInput.text = mode === "rename" ? Files.nameAt(win.current) : qsTr("Carpeta sin título")
        nameDialog.open = true
        nameInput.forceActiveFocus()
        nameInput.selectAll()
    }
    function acceptName() {
        if (nameMode === "new") Files.newFolder(nameInput.text)
        else Files.renameAt(current, nameInput.text)
        nameDialog.open = false
        fx.forceActiveFocus()
    }

    MouseArea {
        z: -1
        x: 239; y: 0; width: parent.width - 239; height: parent.height
        acceptedButtons: Qt.RightButton | Qt.LeftButton
        onClicked: (m) => { win.current = -1; if (m.button === Qt.RightButton) fx.showMenu(m.x + 239, m.y, false) }
    }

    Item {
        id: ctx
        property bool open: false
        z: 50
        width: 220
        height: ctxCol.height + 12
        visible: opacity > 0
        opacity: open ? 1 : 0
        scale: open ? 1 : 0.95
        transformOrigin: Item.TopLeft
        Behavior on opacity { NumberAnimation { duration: Theme.dur(120) } }
        Behavior on scale { NumberAnimation { duration: Theme.dur(140); easing.type: Theme.easing } }
        Rectangle { anchors.fill: parent; radius: 12; color: Theme.popupFill; border.width: 1; border.color: Theme.hairline }
        Column {
            id: ctxCol
            x: 6; y: 6; width: parent.width - 12
            Repeater {
                model: {
                    if (Files.inTrash) return fx.ctxOnItem
                        ? [{ id: "restore", t: qsTr("Restaurar") }, { id: "delete", t: qsTr("Eliminar definitivamente") }, { id: "empty", t: qsTr("Vaciar papelera") }]
                        : [{ id: "empty", t: qsTr("Vaciar papelera") }]
                    return fx.ctxOnItem
                        ? [{ id: "open", t: qsTr("Abrir") }, { id: "rename", t: qsTr("Renombrar…") }, { id: "trash", t: qsTr("Mover a la papelera") }, { id: "new", t: qsTr("Nueva carpeta…") }]
                        : [{ id: "new", t: qsTr("Nueva carpeta…") }]
                }
                Rectangle {
                    width: ctxCol.width; height: 32; radius: 8
                    color: cm.containsMouse ? Theme.accentSelected : "transparent"
                    Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: modelData.t; color: Theme.white
                           font.family: Theme.fontFamily; font.pixelSize: 15 }
                    MouseArea {
                        id: cm; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            ctx.open = false
                            const a = modelData.id
                            if (a === "open") Files.activate(win.current)
                            else if (a === "rename") fx.openName("rename")
                            else if (a === "trash") Files.trashAt(win.current)
                            else if (a === "new") fx.openName("new")
                            else if (a === "restore") Files.restoreAt(win.current)
                            else if (a === "delete") Files.deleteAt(win.current)
                            else if (a === "empty") Files.emptyTrash()
                        }
                    }
                }
            }
        }
    }
    MouseArea { anchors.fill: parent; z: 40; enabled: ctx.open; onClicked: ctx.open = false }

    Item {
        id: nameDialog
        property bool open: false
        anchors.fill: parent
        z: 60
        visible: opacity > 0
        opacity: open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur(140) } }
        Rectangle { anchors.fill: parent; color: Theme.scrim }
        MouseArea { anchors.fill: parent; onClicked: { nameDialog.open = false; fx.forceActiveFocus() } }
        Rectangle {
            width: 380; height: 160; radius: 18; anchors.centerIn: parent
            color: Qt.rgba(0.10, 0.15, 0.30, 0.98); border.width: 1; border.color: Theme.hairline
            MouseArea { anchors.fill: parent }
            Text { x: 22; y: 18; text: fx.nameMode === "new" ? qsTr("Nueva carpeta") : qsTr("Cambiar nombre")
                   color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 17; font.weight: Font.DemiBold }
            Rectangle {
                x: 22; y: 56; width: parent.width - 44; height: 38; radius: 10; color: Qt.rgba(1, 1, 1, 0.12)
                border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.3)
                TextInput {
                    id: nameInput
                    anchors.fill: parent; anchors.margins: 10
                    color: Theme.white; selectionColor: Theme.accent
                    font.family: Theme.fontFamily; font.pixelSize: 16
                    onAccepted: fx.acceptName()
                    Keys.onEscapePressed: { nameDialog.open = false; fx.forceActiveFocus() }
                }
            }
            Row {
                anchors.right: parent.right; anchors.rightMargin: 22; anchors.bottom: parent.bottom; anchors.bottomMargin: 18; spacing: 10
                Rectangle { width: 100; height: 34; radius: 10; color: Qt.rgba(1, 1, 1, 0.14)
                    Text { anchors.centerIn: parent; text: qsTr("Cancelar"); color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 15 }
                    MouseArea { anchors.fill: parent; onClicked: { nameDialog.open = false; fx.forceActiveFocus() } } }
                Rectangle { width: 100; height: 34; radius: 10; color: Theme.accent
                    Text { anchors.centerIn: parent; text: qsTr("Aceptar"); color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 15; font.weight: Font.DemiBold }
                    MouseArea { anchors.fill: parent; onClicked: fx.acceptName() } }
            }
        }
    }
    }
}
