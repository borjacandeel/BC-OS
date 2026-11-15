import QtQuick
import BCShell

// BC Archivos (equivalente a Finder, Golden Gate): barra lateral de borde a borde (Favoritos, Ubicaciones, Etiquetas),
// barra de herramientas unificada, vistas Iconos · Lista · Columnas · Galería, barra de ruta, pestañas, búsqueda
// (en la carpeta o en toda la carpeta personal), etiquetas de color y Vista rápida (Espacio).
AppWindow {
    id: win
    width: 1060
    height: 600
    titlebarHeight: 52
    title: qsTr("Archivos")
    property int current: -1
    property string view: "icons"          // icons | list | columns | gallery
    property bool pathBar: true
    property bool sidebar: true
    property var tabs: [Files.path]
    property int tab: 0
    property bool searchAll: false
    property bool recents: false
    property var recentList: []
    Connections { target: Files; function onPathChanged() { win.recents = false } }
    readonly property real sideW: sidebar ? 220 : 0
    readonly property var places: [
        { key: "home", name: qsTr("Inicio"), icon: Icons.home },
        { key: "desktop", name: qsTr("Escritorio"), icon: Icons.desktop },
        { key: "documents", name: qsTr("Documentos"), icon: Icons.document },
        { key: "downloads", name: qsTr("Descargas"), icon: Icons.download },
        { key: "pictures", name: qsTr("Imágenes"), icon: Icons.image },
        { key: "music", name: qsTr("Música"), icon: Icons.music }
    ]
    readonly property var tagColors: ({ rojo: "#FF453A", naranja: "#FF9F0A", amarillo: "#FFD60A", verde: "#30D158", azul: "#0A84FF", morado: "#BF5AF2", gris: "#8E8E93" })
    property string tagFilter: ""
    Connections { target: Files; function onPathChanged() { win.current = -1; const t = win.tabs.slice(); t[win.tab] = Files.path; win.tabs = t } }
    Component.onCompleted: { if (AppConfig.openArg === "trash") Files.openTrash(); else if (AppConfig.openArg !== "") Files.open(AppConfig.openArg) }

    function newTab() { const t = tabs.slice(); t.push(Files.path); tabs = t; tab = t.length - 1 }
    function closeTab(i) { if (tabs.length < 2) { win.closeRequested(); return } const t = tabs.slice(); t.splice(i, 1); tabs = t; tab = Math.min(tab, t.length - 1); Files.open(tabs[tab]) }
    function goTab(i) { tab = i; Files.open(tabs[i]) }
    readonly property var sel: current >= 0 ? Files.infoAt(current) : null

            component Head: Text { x: 18; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold; height: 26; verticalAlignment: Text.AlignBottom; bottomPadding: 4 }
            component Place: Rectangle {
                id: pl
                property string icon
                property string label
                property bool on: false
                property color tint: Theme.accent
                signal hit()
                x: 10; width: side.width - 20; height: 28; radius: 7
                color: on ? (win.active ? Theme.tileFill : Theme.tileFill) : (phov.containsMouse ? Qt.rgba(0.5, 0.5, 0.5, 0.08) : "transparent")
                // Golden Gate: iconos en color solo en la ventana activa
                Icon { x: 10; anchors.verticalCenter: parent.verticalCenter; name: pl.icon; size: 16; color: win.active ? pl.tint : Theme.textSecondary; filled: pl.on }
                Text { x: 34; anchors.verticalCenter: parent.verticalCenter; text: pl.label; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13 }
                MouseArea { id: phov; anchors.fill: parent; hoverEnabled: true; onClicked: pl.hit() }
            }
        // ---- Vista previa (columnas, galería y Vista rápida) ----------------------------------
        component Preview: Item {
            id: pv
            property var info: null
            property bool big: false
            Text { visible: !pv.info; anchors.centerIn: parent; text: qsTr("Selecciona un elemento"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 13 }
            Image { id: pim; visible: !!pv.info && pv.info.kind === "imagen"; anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width; height: parent.height - (pv.big ? 30 : 90); fillMode: Image.PreserveAspectFit; asynchronous: true
                    source: visible ? "file://" + pv.info.path : ""; sourceSize: Qt.size(1200, 1200) }
            Rectangle { visible: !!pv.info && (pv.info.kind === "texto" || pv.info.kind === "codigo"); width: parent.width; height: parent.height - (pv.big ? 30 : 90); radius: 8; color: Theme.tileFill; clip: true
                        Text { anchors.fill: parent; anchors.margins: 10; text: visible && pv.info ? Files.textPreview(pv.info.path, 6000) : ""; color: Theme.textPrimary
                               font.family: Theme.fontMono; font.pixelSize: 11; wrapMode: Text.WrapAnywhere } }
            FileGlyph { visible: !!pv.info && pv.info.kind !== "imagen" && pv.info.kind !== "texto" && pv.info.kind !== "codigo"; anchors.horizontalCenter: parent.horizontalCenter; y: parent.height * 0.2
                        kind: pv.info ? pv.info.kind : "archivo"; width: 128; height: 108 }
            Column {
                visible: !!pv.info && !pv.big; anchors.bottom: parent.bottom; width: parent.width; spacing: 2
                Text { text: pv.info ? pv.info.name : ""; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 14; font.weight: Font.Bold; width: parent.width; elide: Text.ElideMiddle }
                Text { text: pv.info ? pv.info.mime + " · " + pv.info.size : ""; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                Text { text: pv.info ? qsTr("Modificado: %1").arg(pv.info.modified) : ""; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
            }
        }

    // ---- Barra de herramientas unificada ----------------------------------------------------
    titlebarContent: [
        Row {
            x: win.sideW + 14; anchors.verticalCenter: parent.verticalCenter; spacing: 2
            Repeater {
                model: [ { name: Icons.chevronLeft, on: Files.canBack, act: 0 }, { name: Icons.chevronRight, on: Files.canForward, act: 1 } ]
                Rectangle {
                    width: 28; height: 28; radius: 7; color: bm.containsMouse && modelData.on ? Theme.tileFill : "transparent"
                    Icon { anchors.centerIn: parent; name: modelData.name; size: 16; color: Theme.textPrimary; opacity: modelData.on ? 1 : 0.3 }
                    MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; enabled: modelData.on; onClicked: modelData.act === 0 ? Files.back() : Files.forward() }
                }
            }
            Text { anchors.verticalCenter: parent.verticalCenter; leftPadding: 8; text: win.recents ? qsTr("Recientes") : Files.inTrash ? qsTr("Papelera") : (Files.crumbs.length ? Files.crumbs[Files.crumbs.length - 1].name || qsTr("Inicio") : "")
                   color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 15; font.weight: Font.Bold; width: 200; elide: Text.ElideRight }
        },
        Row {
            anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 10
            // Selector de vista (control segmentado)
            Rectangle {
                width: 4 * 30 + 6; height: 28; radius: 8; color: Theme.tileFill
                Row {
                    x: 3; anchors.verticalCenter: parent.verticalCenter
                    Repeater {
                        model: [ { v: "icons", i: "view-grid-symbolic" }, { v: "list", i: "view-list-symbolic" },
                                 { v: "columns", i: "view-sidebar-symbolic" }, { v: "gallery", i: "image-x-generic" } ]
                        Rectangle {
                            width: 30; height: 22; radius: 6; color: win.view === modelData.v ? (Theme.dark ? Qt.rgba(1, 1, 1, 0.18) : "white") : "transparent"
                            Icon { anchors.centerIn: parent; name: modelData.i; size: 14; color: Theme.textPrimary }
                            MouseArea { anchors.fill: parent; onClicked: win.view = modelData.v }
                        }
                    }
                }
            }
            // Etiquetar
            Rectangle {
                width: 30; height: 28; radius: 8; color: tg.containsMouse ? Theme.tileFill : "transparent"; opacity: win.current >= 0 ? 1 : 0.35
                Row { anchors.centerIn: parent; spacing: -4
                      Repeater { model: ["#FF453A", "#FFD60A", "#0A84FF"]; Rectangle { required property string modelData; width: 9; height: 9; radius: 4.5; color: modelData; border.width: 1; border.color: Theme.windowFill } } }
                MouseArea { id: tg; anchors.fill: parent; hoverEnabled: true; enabled: win.current >= 0; onClicked: tagMenu.open = !tagMenu.open }
            }
            // Búsqueda
            Rectangle {
                width: 220; height: 28; radius: 8; color: Theme.tileFill
                Icon { x: 8; anchors.verticalCenter: parent.verticalCenter; name: Icons.search; size: 14; color: Theme.textSecondary }
                TextInput {
                    id: search
                    x: 28; width: parent.width - 52; anchors.verticalCenter: parent.verticalCenter
                    text: Files.filter
                    onTextEdited: { Files.filter = text; if (win.searchAll) Quick.searchFiles(text) }
                    color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13
                    selectionColor: Theme.accent; clip: true
                    Keys.onEscapePressed: { Files.filter = ""; win.searchAll = false; focus = false }
                    Text { visible: !search.text && !search.activeFocus; text: qsTr("Buscar"); color: Theme.textSecondary; font: search.font }
                }
                Item {
                    visible: search.text !== ""
                    x: parent.width - 24; width: 20; height: 20; anchors.verticalCenter: parent.verticalCenter
                    Icon { anchors.centerIn: parent; name: Icons.closeX; size: 11; color: Theme.textSecondary }
                    MouseArea { anchors.fill: parent; onClicked: { Files.filter = ""; win.searchAll = false } }
                }
            }
        }
    ]

    Item {
        id: fx
        anchors.fill: parent
        focus: true

        // ---- Barra lateral --------------------------------------------------------------------
        Rectangle {
            id: side
            visible: win.sidebar
            y: -win.titlebarHeight; width: win.sideW; height: parent.height + win.titlebarHeight
            color: Theme.gg ? "transparent" : Theme.sidebarFill
            SidebarGlass { anchors.fill: parent; active: win.active; z: -1 }
            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.hairline }
            Column {
                y: win.titlebarHeight + 4; width: parent.width
                Head { text: qsTr("Favoritos") }
                Place { icon: "document-open-symbolic"; label: qsTr("Recientes"); on: win.recents
                        onHit: { win.recents = true; win.recentList = Quick.recentFiles() } }
                Repeater {
                    model: win.places
                    Place { icon: modelData.icon; label: modelData.name; on: Files.path === Files.placePath(modelData.key) && !Files.inTrash
                            onHit: { win.tagFilter = ""; Files.setTagFilter(""); Files.place(modelData.key) } }
                }
                Head { text: qsTr("Ubicaciones") }
                Place { icon: "computer-symbolic"; label: qsTr("Este equipo"); on: Files.path === "/"; tint: Theme.textSecondary; onHit: Files.open("/") }
                Place { icon: Icons.trash; label: qsTr("Papelera"); on: Files.inTrash; tint: Theme.textSecondary; onHit: Files.openTrash() }
                Head { text: qsTr("Etiquetas") }
                Repeater {
                    model: ["rojo", "naranja", "amarillo", "verde", "azul", "morado", "gris"]
                    Rectangle {
                        required property string modelData
                        x: 10; width: side.width - 20; height: 26; radius: 7
                        color: win.tagFilter === modelData ? Theme.tileFill : (thov.containsMouse ? Qt.rgba(0.5, 0.5, 0.5, 0.08) : "transparent")
                        Rectangle { x: 13; anchors.verticalCenter: parent.verticalCenter; width: 10; height: 10; radius: 5; color: win.tagColors[modelData] }
                        Text { x: 34; anchors.verticalCenter: parent.verticalCenter; text: modelData.charAt(0).toUpperCase() + modelData.slice(1); color: Theme.textPrimary
                               font.family: Theme.fontFamily; font.pixelSize: 13 }
                        MouseArea { id: thov; anchors.fill: parent; hoverEnabled: true
                                    onClicked: { win.tagFilter = win.tagFilter === modelData ? "" : modelData; Files.setTagFilter(win.tagFilter) } }
                    }
                }
            }
        }

        // ---- Contenido ----------------------------------------------------------------------
        Item {
            id: body
            x: win.sideW; width: parent.width - win.sideW; height: parent.height
            // Pestañas (solo con más de una, como en Finder)
            Row {
                id: tabBar
                visible: win.tabs.length > 1
                width: parent.width; height: visible ? 30 : 0
                Repeater {
                    model: win.tabs
                    Rectangle {
                        required property string modelData
                        required property int index
                        width: body.width / win.tabs.length; height: 30
                        color: index === win.tab ? "transparent" : Theme.tileFill
                        border.width: index === win.tab ? 0 : 1; border.color: Theme.hairline
                        Text { anchors.centerIn: parent; text: modelData.split("/").pop() || "/"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12; width: parent.width - 40; elide: Text.ElideMiddle; horizontalAlignment: Text.AlignHCenter }
                        Text { anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: "×"; color: Theme.textSecondary; font.pixelSize: 14; visible: tabHov.containsMouse
                               MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: win.closeTab(index) } }
                        MouseArea { id: tabHov; anchors.fill: parent; hoverEnabled: true; z: -1; onClicked: win.goTab(index) }
                    }
                }
            }
            // Ámbito de búsqueda
            Row {
                id: scope
                visible: Files.filter !== ""
                y: tabBar.height; x: 12; height: visible ? 32 : 0; spacing: 8
                Text { anchors.verticalCenter: parent.verticalCenter; text: qsTr("Buscar en:"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                Repeater {
                    model: [ { all: true, t: qsTr("Inicio") }, { all: false, t: qsTr("«%1»").arg(Files.path.split("/").pop() || "/") } ]
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: st.implicitWidth + 16; height: 22; radius: 11; color: win.searchAll === modelData.all ? Theme.accent : Theme.tileFill
                        Text { id: st; anchors.centerIn: parent; text: modelData.t; color: win.searchAll === modelData.all ? "white" : Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                        MouseArea { anchors.fill: parent; onClicked: { win.searchAll = modelData.all; if (modelData.all) Quick.searchFiles(Files.filter) } }
                    }
                }
            }
            Item {
                id: area
                y: tabBar.height + scope.height; width: parent.width; height: parent.height - y - (pathRow.visible ? pathRow.height : 0)
                clip: true

                // Iconos
                GridView {
                    id: grid
                    visible: win.view === "icons" && !win.searchAll && !win.recents
                    anchors.fill: parent; anchors.margins: 10
                    cellWidth: Math.max(104, Math.floor(width / Math.max(1, Math.floor(width / 112)))); cellHeight: 112
                    model: Files; boundsBehavior: Flickable.StopAtBounds
                    delegate: Item {
                        id: cell
                        required property int index
                        required property string name
                        required property string kind
                        required property var tags
                        required property string filePath
                        width: grid.cellWidth; height: grid.cellHeight
                        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 2; width: 74; height: 66; radius: 7
                                    color: win.current === cell.index ? Theme.tileFill : "transparent" }
                        FileGlyph { visible: cell.kind !== "imagen" || thumb.status !== Image.Ready; kind: cell.kind; anchors.horizontalCenter: parent.horizontalCenter; y: 6; width: 70; height: 58 }
                        // Miniatura de las imágenes (como Finder), con borde blanco fino y sombra
                        Rectangle { visible: thumb.status === Image.Ready; anchors.centerIn: thumb; width: thumb.paintedWidth + 4; height: thumb.paintedHeight + 4; color: "white"; radius: 2
                                    border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.15) }
                        Image { id: thumb; visible: status === Image.Ready; anchors.horizontalCenter: parent.horizontalCenter; y: 8; width: 66; height: 56
                                fillMode: Image.PreserveAspectFit; asynchronous: true; sourceSize: Qt.size(132, 112)
                                source: cell.kind === "imagen" ? "file://" + cell.filePath : "" }
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter; y: 72
                            width: Math.min(parent.width - 8, nm.implicitWidth + (cell.tags.length ? 16 : 8)); height: nm.height + 2; radius: 4
                            color: win.current === cell.index ? Theme.accent : "transparent"
                            Row { visible: cell.tags.length > 0; x: 4; anchors.verticalCenter: parent.verticalCenter; spacing: -3
                                  Repeater { model: cell.tags; Rectangle { required property string modelData; width: 8; height: 8; radius: 4; color: win.tagColors[modelData] || "gray" } } }
                            Text { id: nm; x: cell.tags.length ? 14 : 4; width: Math.min(implicitWidth, grid.cellWidth - 24); text: cell.name; elide: Text.ElideMiddle
                                   color: win.current === cell.index ? "white" : Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                        }
                        MouseArea {
                            anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (m) => { win.current = cell.index; fx.forceActiveFocus(); if (m.button === Qt.RightButton) { const p = mapToItem(fx, m.x, m.y); fx.showMenu(p.x, p.y, true) } }
                            onDoubleClicked: Files.activate(cell.index)
                        }
                    }
                }
                // Lista
                Item {
                    visible: win.view === "list" && !win.searchAll && !win.recents
                    anchors.fill: parent
                    Row {
                        id: hdr; x: 10; width: parent.width - 20; height: 26
                        Repeater {
                            model: [ { t: qsTr("Nombre"), w: 0.44 }, { t: qsTr("Fecha de modificación"), w: 0.26 }, { t: qsTr("Tamaño"), w: 0.12 }, { t: qsTr("Tipo"), w: 0.18 } ]
                            Text { required property var modelData; width: hdr.width * modelData.w; height: 26; verticalAlignment: Text.AlignVCenter; leftPadding: 8
                                   text: modelData.t; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.DemiBold }
                        }
                    }
                    Rectangle { y: 26; width: parent.width; height: 1; color: Theme.hairline }
                    ListView {
                        id: list
                        y: 28; x: 10; width: parent.width - 20; height: parent.height - 28; clip: true
                        model: Files; boundsBehavior: Flickable.StopAtBounds
                        delegate: Rectangle {
                            id: lr
                            required property int index
                            required property string name
                            required property string kind
                            required property string sizeText
                            required property string modifiedText
                            required property string mime
                            required property var tags
                            width: list.width; height: 24; radius: 5
                            color: win.current === index ? Theme.accent : (index % 2 ? Theme.tileFill : "transparent")
                            readonly property color ink: win.current === index ? "white" : Theme.textPrimary
                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                Item { width: hdr.width * 0.44; height: 24
                                       FileGlyph { x: 6; anchors.verticalCenter: parent.verticalCenter; kind: lr.kind; width: 18; height: 16 }
                                       Text { x: 30; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 50; text: lr.name; elide: Text.ElideMiddle; color: lr.ink; font.family: Theme.fontFamily; font.pixelSize: 12 }
                                       Row { anchors.right: parent.right; anchors.rightMargin: 4; anchors.verticalCenter: parent.verticalCenter; spacing: -3
                                             Repeater { model: lr.tags; Rectangle { required property string modelData; width: 8; height: 8; radius: 4; color: win.tagColors[modelData] || "gray" } } } }
                                Text { width: hdr.width * 0.26; leftPadding: 8; text: lr.modifiedText; color: win.current === lr.index ? "white" : Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12; elide: Text.ElideRight }
                                Text { width: hdr.width * 0.12; leftPadding: 8; text: lr.sizeText; color: win.current === lr.index ? "white" : Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                                Text { width: hdr.width * 0.18; leftPadding: 8; text: lr.mime; color: win.current === lr.index ? "white" : Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12; elide: Text.ElideRight }
                            }
                            MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onClicked: (m) => { win.current = lr.index; fx.forceActiveFocus(); if (m.button === Qt.RightButton) { const p = mapToItem(fx, m.x, m.y); fx.showMenu(p.x, p.y, true) } }
                                        onDoubleClicked: Files.activate(lr.index) }
                        }
                    }
                }
                // Columnas: carpetas de la ruta (hasta 3) + la actual + vista previa del elemento elegido
                Row {
                    visible: win.view === "columns" && !win.searchAll && !win.recents
                    anchors.fill: parent
                    readonly property var anc: Files.crumbs.slice(Math.max(0, Files.crumbs.length - 3), Files.crumbs.length - 1)
                    Repeater {
                        model: parent.anc
                        Rectangle {
                            id: colItem
                            required property var modelData
                            required property int index
                            width: 210; height: parent.height; color: "transparent"
                            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.hairline }
                            FileModel { id: cm; Component.onCompleted: open(colItem.modelData.path) }
                            ListView {
                                anchors.fill: parent; anchors.margins: 4; clip: true; model: cm
                                delegate: Rectangle {
                                    required property string name
                                    required property string filePath
                                    required property string kind
                                    required property bool isDir
                                    readonly property bool onPath: (Files.path + "/").indexOf(filePath + "/") === 0
                                    width: ListView.view.width; height: 22; radius: 5; color: onPath ? Theme.tileFill : "transparent"
                                    FileGlyph { x: 4; anchors.verticalCenter: parent.verticalCenter; kind: parent.kind; width: 16; height: 14 }
                                    Text { x: 26; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 44; text: parent.name; elide: Text.ElideMiddle; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                                    Text { visible: parent.isDir; anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter; text: "›"; color: Theme.textSecondary; font.pixelSize: 14 }
                                    MouseArea { anchors.fill: parent; onClicked: parent.isDir ? Files.open(parent.filePath) : Quick.open(parent.filePath) }
                                }
                            }
                        }
                    }
                    Rectangle {
                        width: 230; height: parent.height; color: "transparent"
                        Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.hairline }
                        ListView {
                            anchors.fill: parent; anchors.margins: 4; clip: true; model: Files
                            delegate: Rectangle {
                                required property int index
                                required property string name
                                required property string kind
                                required property bool isDir
                                width: ListView.view.width; height: 22; radius: 5; color: win.current === index ? Theme.accent : "transparent"
                                FileGlyph { x: 4; anchors.verticalCenter: parent.verticalCenter; kind: parent.kind; width: 16; height: 14 }
                                Text { x: 26; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 44; text: parent.name; elide: Text.ElideMiddle; color: win.current === parent.index ? "white" : Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                                Text { visible: parent.isDir; anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter; text: "›"; color: Theme.textSecondary; font.pixelSize: 14 }
                                MouseArea { anchors.fill: parent; onClicked: { win.current = parent.index; fx.forceActiveFocus() } onDoubleClicked: Files.activate(parent.index) }
                            }
                        }
                    }
                    Item {
                        width: Math.max(0, parent.width - 230 - parent.anc.length * 210); height: parent.height
                        Preview { anchors.fill: parent; anchors.margins: 16; info: win.sel }
                    }
                }
                // Galería: vista previa grande y tira de miniaturas
                Item {
                    visible: win.view === "gallery" && !win.searchAll && !win.recents
                    anchors.fill: parent
                    Preview { anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: strip.top; anchors.margins: 16; info: win.sel; big: true }
                    ListView {
                        id: strip
                        anchors.bottom: parent.bottom; anchors.bottomMargin: 8; x: 10; width: parent.width - 20; height: 84
                        orientation: ListView.Horizontal; spacing: 6; clip: true; model: Files
                        delegate: Rectangle {
                            required property int index
                            required property string kind
                            required property string filePath
                            width: 72; height: 72; radius: 8; color: win.current === index ? Theme.accent : Theme.tileFill
                            Image { anchors.fill: parent; anchors.margins: 4; visible: parent.kind === "imagen"; source: visible ? "file://" + parent.filePath : ""
                                    sourceSize: Qt.size(128, 128); fillMode: Image.PreserveAspectCrop; asynchronous: true }
                            FileGlyph { anchors.centerIn: parent; visible: parent.kind !== "imagen"; kind: parent.kind; width: 48; height: 40 }
                            MouseArea { anchors.fill: parent; onClicked: { win.current = parent.index; fx.forceActiveFocus() } onDoubleClicked: Files.activate(parent.index) }
                        }
                    }
                }
                // Resultados de búsqueda en toda la carpeta personal
                ListView {
                    visible: win.searchAll || win.recents
                    anchors.fill: parent; anchors.margins: 10; clip: true
                    model: win.recents ? win.recentList : Quick.fileResults
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: ListView.view.width; height: 28; radius: 5; color: rh.containsMouse ? Theme.tileFill : "transparent"
                        Icon { x: 8; anchors.verticalCenter: parent.verticalCenter; name: modelData.dir ? "folder-symbolic" : "document-open-symbolic"; size: 14; color: Theme.textSecondary }
                        Text { x: 30; anchors.verticalCenter: parent.verticalCenter; text: modelData.name; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12; width: parent.width * 0.5; elide: Text.ElideMiddle }
                        Text { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: modelData.parent; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11; width: parent.width * 0.4; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft }
                        MouseArea { id: rh; anchors.fill: parent; hoverEnabled: true; onDoubleClicked: modelData.dir ? Files.open(modelData.path) : Quick.open(modelData.path) }
                    }
                }
                Column {
                    visible: Files.count === 0 && !win.searchAll && !win.recents
                    anchors.centerIn: parent; spacing: 6
                    Text { anchors.horizontalCenter: parent.horizontalCenter
                           text: !Files.available ? qsTr("La carpeta no existe o no se puede leer") : (Files.filter !== "" || win.tagFilter !== "" ? qsTr("Sin resultados") : qsTr("Carpeta vacía"))
                           color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 15 }
                }
                MouseArea {
                    z: -1; anchors.fill: parent; acceptedButtons: Qt.RightButton | Qt.LeftButton
                    onClicked: (m) => { win.current = -1; fx.forceActiveFocus(); if (m.button === Qt.RightButton) { const p = mapToItem(fx, m.x, m.y); fx.showMenu(p.x, p.y, false) } }
                }
            }
            // Barra de ruta
            Rectangle {
                id: pathRow
                visible: win.pathBar
                anchors.bottom: parent.bottom; width: parent.width; height: 26; color: "transparent"
                Rectangle { width: parent.width; height: 1; color: Theme.hairline }
                Row {
                    x: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                    Repeater {
                        model: Files.crumbs
                        Row {
                            required property var modelData
                            required property int index
                            spacing: 4
                            Text { visible: index > 0; text: "›"; color: Theme.textSecondary; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                            Icon { name: "folder-symbolic"; size: 12; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: modelData.home ? qsTr("Inicio") : modelData.name; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter
                                   MouseArea { anchors.fill: parent; onClicked: Files.open(modelData.path) } }
                        }
                    }
                }
            }
        }


        // ---- Vista rápida (Espacio) -----------------------------------------------------------
        Item {
            id: ql
            property bool open: false
            anchors.fill: parent; z: 70
            visible: opacity > 0
            opacity: open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.d(Theme.durQuickLook * 0.6) } }
            Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.25) }
            MouseArea { anchors.fill: parent; onClicked: ql.open = false }
            Rectangle {
                anchors.centerIn: parent; width: parent.width * 0.72; height: parent.height * 0.82; radius: Theme.windowRadius
                color: Theme.popupFill; border.width: 1; border.color: Theme.hairline
                scale: ql.open ? 1 : 0.85
                Behavior on scale { NumberAnimation { duration: Theme.d(Theme.durQuickLook); easing.type: Theme.easeSpring } }
                MouseArea { anchors.fill: parent }
                Text { x: 16; y: 12; text: win.sel ? win.sel.name : ""; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Bold; width: parent.width - 120; elide: Text.ElideMiddle }
                Rectangle { anchors.right: parent.right; anchors.rightMargin: 12; y: 8; width: 84; height: 24; radius: 12; color: Theme.tileFill
                            Text { anchors.centerIn: parent; text: qsTr("Abrir con…"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                            MouseArea { anchors.fill: parent; onClicked: { ql.open = false; Files.activate(win.current) } } }
                Preview { x: 16; y: 44; width: parent.width - 32; height: parent.height - 60; info: ql.open ? win.sel : null; big: true }
            }
        }

        // ---- Menú de etiquetas ----------------------------------------------------------------
        Rectangle {
            id: tagMenu
            property bool open: false
            visible: open; z: 55
            x: parent.width - 330; y: 2; width: 236; height: 44; radius: 12; color: Theme.popupFill; border.width: 1; border.color: Theme.hairline
            Row {
                anchors.centerIn: parent; spacing: 8
                Repeater {
                    model: ["rojo", "naranja", "amarillo", "verde", "azul", "morado", "gris"]
                    Rectangle { required property string modelData; width: 22; height: 22; radius: 11; color: win.tagColors[modelData]
                                MouseArea { anchors.fill: parent; onClicked: { Files.setTag(win.current, modelData); tagMenu.open = false } } }
                }
            }
        }

        // ---- Operaciones: menú contextual, nombre y teclado -----------------------------------
        property bool ctxOnItem: false
        property string nameMode: ""   // "new" | "rename"
        Connections {
            target: AppActions
            function onActionInvoked(a) {
                if (a === "newFolder") fx.openName("new")
                else if (a === "open") Files.activate(win.current)
                else if (a === "rename" && win.current >= 0 && !Files.inTrash) fx.openName("rename")
                else if (a === "trash" && win.current >= 0 && !Files.inTrash) { if (Files.trashAt(win.current)) Sounds.play("trash") }
                else if (a === "emptyTrash") { if (Files.emptyTrash()) Sounds.play("trash") }
                else if (a === "newTab") win.newTab()
                else if (a === "quickLook") ql.open = win.current >= 0
                else if (a === "back") Files.back()
                else if (a === "forward") Files.forward()
                else if (a === "up") Files.up()
                else if (a === "togglePath") win.pathBar = !win.pathBar
                else if (a === "toggleSidebar") win.sidebar = !win.sidebar
                else if (a.indexOf("view-") === 0) win.view = a.substring(5)
                else if (a.indexOf("tag:") === 0) { if (win.current >= 0) Files.setTag(win.current, a.substring(4)) }
                else if (a.indexOf("go-") === 0) { const k = a.substring(3); k === "trash" ? Files.openTrash() : Files.place(k) }
            }
        }
        Shortcut { sequence: "Ctrl+Shift+N"; onActivated: fx.openName("new") }
        Shortcut { sequence: "Ctrl+T"; onActivated: win.newTab() }
        Shortcut { sequence: "Ctrl+1"; onActivated: win.view = "icons" }
        Shortcut { sequence: "Ctrl+2"; onActivated: win.view = "list" }
        Shortcut { sequence: "Ctrl+3"; onActivated: win.view = "columns" }
        Shortcut { sequence: "Ctrl+4"; onActivated: win.view = "gallery" }
        Shortcut { sequence: "Ctrl+F"; onActivated: search.forceActiveFocus() }
        Shortcut { sequence: "Ctrl+Up"; onActivated: Files.up() }
        Keys.onDeletePressed: if (win.current >= 0 && !Files.inTrash) { if (Files.trashAt(win.current)) Sounds.play("trash") }
        Keys.onSpacePressed: ql.open = !ql.open && win.current >= 0
        Keys.onEscapePressed: { ql.open = false; tagMenu.open = false }
        Keys.onReturnPressed: if (win.current >= 0) Files.activate(win.current)
        Keys.onRightPressed: win.current = Math.min(Files.count - 1, win.current + 1)
        Keys.onLeftPressed: win.current = Math.max(0, win.current - 1)
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
            nameInput.text = mode === "rename" ? Files.nameAt(win.current) : qsTr("carpeta sin título")
            nameDialog.open = true
            nameInput.forceActiveFocus()
            nameInput.selectAll()
        }
        function acceptName() {
            if (nameMode === "new") Files.newFolder(nameInput.text)
            else Files.renameAt(win.current, nameInput.text)
            nameDialog.open = false
            fx.forceActiveFocus()
        }

        Item {
            id: ctx
            property bool open: false
            z: 50
            width: 230
            height: ctxCol.height + 12
            visible: opacity > 0
            opacity: open ? 1 : 0
            scale: open ? 1 : 0.95
            transformOrigin: Item.TopLeft
            Behavior on opacity { NumberAnimation { duration: Theme.d(Theme.durMenuOpen) } }
            Behavior on scale { NumberAnimation { duration: Theme.d(Theme.durMenuOpen); easing.type: Theme.easeStandard } }
            Rectangle { anchors.fill: parent; radius: Theme.menuRadius; color: Theme.popupFill; border.width: 1; border.color: Theme.hairline }
            Column {
                id: ctxCol
                x: 5; y: 6; width: parent.width - 10
                Repeater {
                    model: {
                        if (Files.inTrash) return fx.ctxOnItem
                            ? [{ id: "restore", t: qsTr("Restaurar") }, { id: "delete", t: qsTr("Eliminar inmediatamente…") }, { sep: true }, { id: "empty", t: qsTr("Vaciar papelera") }]
                            : [{ id: "empty", t: qsTr("Vaciar papelera") }]
                        return fx.ctxOnItem
                            ? [{ id: "open", t: qsTr("Abrir") }, { id: "ql", t: qsTr("Vista rápida") }, { sep: true }, { id: "rename", t: qsTr("Renombrar") },
                               { id: "tab", t: qsTr("Abrir en una pestaña nueva") }, { sep: true }, { id: "tags", t: qsTr("Etiquetas…") }, { sep: true },
                               { id: "trash", t: qsTr("Mover a la papelera") }]
                            : [{ id: "new", t: qsTr("Nueva carpeta") }, { sep: true }, { id: "icons", t: qsTr("Como iconos") }, { id: "list", t: qsTr("Como lista") },
                               { id: "columns", t: qsTr("Como columnas") }, { id: "gallery", t: qsTr("Como galería") }]
                    }
                    Item {
                        required property var modelData
                        width: ctxCol.width; height: modelData.sep ? 9 : 24
                        Rectangle { visible: !!modelData.sep; anchors.verticalCenter: parent.verticalCenter; x: 8; width: parent.width - 16; height: 1; color: Theme.hairline }
                        Rectangle {
                            visible: !modelData.sep; anchors.fill: parent; radius: 5
                            color: cm2.containsMouse ? Theme.accent : "transparent"
                            Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: modelData.t || ""; color: cm2.containsMouse ? "white" : Theme.textPrimary
                                   font.family: Theme.fontFamily; font.pixelSize: 13 }
                            MouseArea {
                                id: cm2; anchors.fill: parent; hoverEnabled: true
                                onClicked: {
                                    ctx.open = false
                                    const a = modelData.id
                                    if (a === "open") Files.activate(win.current)
                                    else if (a === "ql") ql.open = true
                                    else if (a === "rename") fx.openName("rename")
                                    else if (a === "tab") { const i = win.sel; win.newTab(); if (i && i.isDir) Files.open(i.path) }
                                    else if (a === "tags") tagMenu.open = true
                                    else if (a === "trash") { if (Files.trashAt(win.current)) Sounds.play("trash") }
                                    else if (a === "new") fx.openName("new")
                                    else if (a === "restore") Files.restoreAt(win.current)
                                    else if (a === "delete") Files.deleteAt(win.current)
                                    else if (a === "empty") { if (Files.emptyTrash()) Sounds.play("trash") }
                                    else win.view = a
                                }
                            }
                        }
                    }
                }
            }
        }
        MouseArea { anchors.fill: parent; z: 40; enabled: ctx.open || tagMenu.open; onClicked: { ctx.open = false; tagMenu.open = false } }

        // Hoja (sheet) para el nombre: baja desde la barra de herramientas, como en macOS
        Item {
            id: nameDialog
            property bool open: false
            anchors.fill: parent
            z: 60
            visible: opacity > 0
            opacity: open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.d(Theme.durSheet * 0.6) } }
            Rectangle { anchors.fill: parent; color: Theme.scrim; opacity: 0.4 }
            MouseArea { anchors.fill: parent; onClicked: { nameDialog.open = false; fx.forceActiveFocus() } }
            Rectangle {
                width: 380; height: 150; radius: 16; anchors.horizontalCenter: parent.horizontalCenter
                y: nameDialog.open ? 20 : -40
                Behavior on y { NumberAnimation { duration: Theme.d(Theme.durSheet); easing.type: Theme.easeEmphasized } }
                color: Theme.popupFill; border.width: 1; border.color: Theme.hairline
                MouseArea { anchors.fill: parent }
                Text { x: 20; y: 16; text: fx.nameMode === "new" ? qsTr("Nueva carpeta") : qsTr("Cambiar nombre")
                       color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 14; font.weight: Font.Bold }
                Rectangle {
                    x: 20; y: 48; width: parent.width - 40; height: 30; radius: 7; color: Theme.tileFill
                    border.width: 2; border.color: Theme.accent
                    TextInput {
                        id: nameInput
                        anchors.fill: parent; anchors.margins: 7
                        color: Theme.textPrimary; selectionColor: Theme.accent
                        font.family: Theme.fontFamily; font.pixelSize: 13
                        onAccepted: fx.acceptName()
                        Keys.onEscapePressed: { nameDialog.open = false; fx.forceActiveFocus() }
                    }
                }
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 20; anchors.bottom: parent.bottom; anchors.bottomMargin: 16; spacing: 8
                    Rectangle { width: 92; height: 28; radius: 7; color: Theme.tileFill
                        Text { anchors.centerIn: parent; text: qsTr("Cancelar"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13 }
                        MouseArea { anchors.fill: parent; onClicked: { nameDialog.open = false; fx.forceActiveFocus() } } }
                    Rectangle { width: 92; height: 28; radius: 7; color: Theme.accent
                        Text { anchors.centerIn: parent; text: qsTr("Aceptar"); color: "white"; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.DemiBold }
                        MouseArea { anchors.fill: parent; onClicked: fx.acceptName() } }
                }
            }
        }
    }
}
