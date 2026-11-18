import QtQuick
import BCShell

// BC Tienda: buscar, instalar y quitar software con pacman.
AppWindow {
    id: win
    sidebarWidth: 220
    width: 980
    height: 640
    titlebarHeight: 52
    title: qsTr("Tienda")
    titlebarContent: [ Item {} ]   // como App Store: sin título centrado

    property int mode: 0            // 0 buscar, 1 instaladas
    property string password: ""    // solo en memoria, mientras la ventana está abierta
    property var pending: null      // { action, name }

    function reload() { if (section !== "discover" && section !== "updates") go(section) }
    function ask(action, name) {
        pending = { action: action, name: name }
        if (Store.flathub || Store.passwordless || password !== "") run()
        else { pwDialog.open = true; pwInput.text = ""; pwInput.forceActiveFocus() }
    }
    function run() {
        const p = pending
        pending = null
        if (p.action === "install") Store.install(p.name, password)
        else if (p.action === "remove") Store.remove(p.name, password)
        else Store.updateAll(password)
    }
    Component.onCompleted: if (AppConfig.openArg === "updates") go("updates")
    // Acciones de los menús globales (Archivo ▸ Buscar, Visualización ▸ …, Tienda ▸ Actualizar)
    Connections {
        target: AppActions
        function onActionInvoked(a) {
            if (a === "search") field.forceActiveFocus()
            else if (a === "modeSearch") win.go("discover")
            else if (a === "modeInstalled") win.go("installed")
            else if (a === "update") { win.go("updates"); win.ask("update", "") }
            else if (a === "close") win.closeRequested()
        }
    }
    Connections {
        target: Store
        function onFinished(ok, action) {
            if (!ok) win.password = ""
            win.reload()
            Notifications.push(qsTr("Tienda"), ok ? qsTr("Operación completada") : qsTr("La operación ha fallado"), "", "", 3500)
        }
    }

    // ---- Interfaz tipo App Store (Golden Gate): barra lateral de borde a borde + contenido ----------
    property string section: "discover"     // discover | cat:<clave> | installed | updates | search
    property string catTitle: ""
    readonly property var featured: [
        { id: "firefox", name: "Firefox", desc: qsTr("Navegador web rápido y privado"), c: "#FF7139" },
        { id: "libreoffice-fresh", icon: "libreoffice-main", name: "LibreOffice", desc: qsTr("Documentos, hojas de cálculo y presentaciones"), c: "#18A303" },
        { id: "gimp", name: "GIMP", desc: qsTr("Edición de imágenes profesional"), c: "#5C5543" },
        { id: "inkscape", name: "Inkscape", desc: qsTr("Dibujo vectorial"), c: "#000000" },
        { id: "vlc", name: "VLC", desc: qsTr("Reproduce cualquier vídeo y música"), c: "#FF8800" },
        { id: "thunderbird", name: "Thunderbird", desc: qsTr("Correo, calendario y contactos"), c: "#0A84FF" },
        { id: "krita", name: "Krita", desc: qsTr("Pintura digital"), c: "#3BABFF" },
        { id: "kdenlive", icon: "kdenlive", name: "Kdenlive", desc: qsTr("Edición de vídeo"), c: "#1D99F3" },
        { id: "audacity", icon: "audacity", name: "Audacity", desc: qsTr("Graba y edita audio"), c: "#0000CC" }
    ]
    readonly property var categories: [
        { k: "office", t: qsTr("Productividad"), q: "office", i: "x-office-document" },
        { k: "graphics", t: qsTr("Creatividad"), q: "graphics", i: "image-x-generic" },
        { k: "dev", t: qsTr("Desarrollo"), q: "editor", i: "text-x-script" },
        { k: "games", t: qsTr("Juegos"), q: "game", i: "multimedia-photo-viewer" },
        { k: "audio", t: qsTr("Música y audio"), q: "audio player", i: "audio-x-generic" },
        { k: "utils", t: qsTr("Utilidades"), q: "utility", i: "accessories-calculator" }
    ]
    function go(s) {
        section = s
        if (s === "installed") Store.listInstalled()
        else if (s.indexOf("cat:") === 0) { const c = categories.find(x => x.k === s.substring(4)); catTitle = c.t; Store.search(c.q) }
        else if (s === "search") Store.search(field.text)
    }

    Rectangle {
        id: side
        y: -win.titlebarHeight; width: 220; height: parent.height + win.titlebarHeight
        color: Theme.gg ? "transparent" : Theme.sidebarFill
        SidebarGlass { anchors.fill: parent; active: win.active; z: -1 }
        Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.hairline }
        Column {
            y: win.titlebarHeight + 6; x: 10; width: parent.width - 20; spacing: 2
            Rectangle {
                width: parent.width; height: 28; radius: 8; color: Theme.tileFill
                Icon { x: 8; anchors.verticalCenter: parent.verticalCenter; name: Icons.search; size: 14; color: Theme.textSecondary }
                TextInput {
                    id: field; x: 28; width: parent.width - 34; anchors.verticalCenter: parent.verticalCenter
                    color: Theme.textPrimary; selectionColor: Theme.textSelection; font.family: Theme.fontFamily; font.pixelSize: 13; clip: true
                    onAccepted: if (text !== "") win.go("search")
                    Text { visible: !parent.text; text: qsTr("Buscar"); color: Theme.textSecondary; font: parent.font }
                }
            }
            Item { width: 1; height: 6 }
            component SideItem: Rectangle {
                id: si
                property string sec
                property string icon
                property string label
                property color tint: Theme.accent
                width: parent ? parent.width : 200; height: 30; radius: 7
                readonly property bool on: win.section === sec
                color: on ? Theme.tileFill : (sm.containsMouse ? Qt.rgba(0.5, 0.5, 0.5, 0.08) : "transparent")
                Icon { x: 9; anchors.verticalCenter: parent.verticalCenter; name: si.icon; size: 16; color: win.active ? si.tint : Theme.textSecondary }
                Text { x: 34; anchors.verticalCenter: parent.verticalCenter; text: si.label; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13
                       font.weight: si.on ? Font.DemiBold : Font.Normal }
                MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; onClicked: win.go(si.sec) }
            }
            SideItem { sec: "discover"; icon: "starred-fill-symbolic"; label: qsTr("Descubrir") }
            Text { leftPadding: 8; topPadding: 10; bottomPadding: 4; text: qsTr("Categorías"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold }
            Repeater {
                model: win.categories
                SideItem { required property var modelData; sec: "cat:" + modelData.k; label: modelData.t
                           // Un símbolo por categoría, como en la App Store de macOS
                           icon: ({ office: "document-edit-symbolic", graphics: "camera-photo-symbolic", dev: "input-keyboard-symbolic",
                                    games: "input-mouse-symbolic", audio: "audio-headphones-symbolic", utils: "preferences-system-symbolic" })[modelData.k] || "view-grid-symbolic" }
            }
            Item { width: 1; height: 10 }
            SideItem { sec: "installed"; icon: "folder-download-symbolic"; label: qsTr("Instaladas") }
            SideItem { sec: "updates"; icon: "view-refresh-symbolic"; label: qsTr("Actualizaciones") }
        }
        // Origen del software
        Row {
            visible: Store.flatpakAvailable
            anchors.bottom: parent.bottom; anchors.bottomMargin: 14; x: 12; spacing: 6
            Repeater {
                model: [qsTr("Arch"), qsTr("Flathub")]
                Rectangle {
                    required property var modelData
                    required property int index
                    width: srcT.implicitWidth + 20; height: 24; radius: 12
                    color: (index === 1) === Store.flathub ? Theme.accent : Theme.tileFill
                    Text { id: srcT; anchors.centerIn: parent; text: modelData; color: (index === 1) === Store.flathub ? "white" : Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                    MouseArea { anchors.fill: parent; onClicked: { Store.flathub = index === 1; win.go(win.section === "discover" ? "discover" : win.section) } }
                }
            }
        }
    }

    // Botón «Obtener» de App Store: cápsula gris con texto del color de resalte
    component GetButton: Rectangle {
        id: gb
        property string pkg
        // Instalada o no según la base de datos local (se vuelve a mirar tras cada instalación)
        property bool installed: Store.stamp >= 0 && pkg !== "" && Store.isInstalled(pkg)
        width: Math.max(72, gt.implicitWidth + 28); height: 26; radius: 13
        color: Theme.lightUi ? "#EEEEF0" : Qt.rgba(1, 1, 1, 0.12)
        opacity: Store.busy ? 0.5 : 1
        Text { id: gt; anchors.centerIn: parent; text: gb.installed ? qsTr("Quitar") : qsTr("Obtener"); color: gb.installed ? Theme.textSecondary : Theme.accent
               font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Bold }
        MouseArea { anchors.fill: parent; enabled: !Store.busy; onClicked: win.ask(gb.installed ? "remove" : "install", gb.pkg) }
    }
    component AppTile: Rectangle {
        id: at
        property string icon
        readonly property string iconFile: icon !== "" ? Quick.iconPath(icon) : ""
        property string letter
        property color tint: "#0A84FF"
        width: 56; height: 56; radius: 13
        gradient: at.iconFile !== "" ? null : grad
        Gradient { id: grad; GradientStop { position: 0; color: Qt.lighter(at.tint, 1.25) } GradientStop { position: 1; color: at.tint } }
        border.width: at.iconFile !== "" ? 0 : 1; border.color: Qt.rgba(1, 1, 1, 0.12)
        Text { visible: at.iconFile === ""; anchors.centerIn: parent; text: at.letter; color: "white"; font.family: Theme.fontFamily; font.pixelSize: 26; font.weight: Font.Bold }
        // Icono real del tema (MacOS-Like) si existe: entonces la placa de color desaparece
        color: "transparent"
        Image { visible: at.iconFile !== ""; anchors.fill: parent; anchors.margins: -2; source: at.iconFile !== "" ? "file://" + at.iconFile : ""; sourceSize: Qt.size(128, 128); smooth: true }
    }

    Item {
        id: content
        x: side.width; width: parent.width - side.width; height: parent.height
        // ---- Descubrir ----
        Flickable {
            visible: win.section === "discover"
            id: discFlick
            OverlayScroll { flick: discFlick }
            anchors.fill: parent; contentHeight: disc.height + 40; clip: true; boundsBehavior: Flickable.DragAndOvershootBounds
            Column {
                id: disc; x: 28; y: 18; width: parent.width - 56; spacing: 16
                Text { text: qsTr("Descubrir"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 26; font.weight: Font.Bold }
                // Destacado (banner)
                Rectangle {
                    width: parent.width; height: 190; radius: 14; clip: true
                    gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "#2C1F6B" } GradientStop { position: 1; color: "#0A4FA8" } }
                    Image { anchors.fill: parent; source: "qrc:/BCShell/assets/wallpaper-default.png"; fillMode: Image.PreserveAspectCrop; opacity: 0.55; sourceSize.width: 900 }
                    Column {
                        x: 24; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                        Text { text: qsTr("APP DESTACADA"); color: Qt.rgba(1, 1, 1, 0.75); font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold }
                        Text { text: "LibreOffice"; color: "white"; font.family: Theme.fontFamily; font.pixelSize: 28; font.weight: Font.Bold }
                        Text { text: qsTr("La suite ofimática libre, lista para tus documentos."); color: Qt.rgba(1, 1, 1, 0.85); font.family: Theme.fontFamily; font.pixelSize: 13 }
                        Item { width: 1; height: 4 }
                        GetButton { pkg: "libreoffice-fresh" }
                    }
                }
                Text { text: qsTr("Imprescindibles"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 18; font.weight: Font.Bold }
                Grid {
                    id: featGrid
                    // Columnas según el ancho (cada ficha necesita ~280 px para que el nombre no se corte)
                    columns: Math.max(1, Math.min(3, Math.floor((disc.width + 18) / 298))); columnSpacing: 18; rowSpacing: 4; width: parent.width
                    Repeater {
                        model: win.featured
                        Item {
                            required property var modelData
                            width: (disc.width - 18 * (featGrid.columns - 1)) / featGrid.columns; height: 76
                            AppTile { anchors.verticalCenter: parent.verticalCenter; letter: modelData.name.charAt(0); tint: modelData.c; icon: modelData.icon || modelData.id }
                            Column {
                                x: 68; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 68 - 84
                                Text { text: modelData.name; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.DemiBold; width: parent.width; elide: Text.ElideRight }
                                Text { text: modelData.desc; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11; width: parent.width; elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.Wrap }
                            }
                            GetButton { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; pkg: modelData.id }
                            Rectangle { x: 68; anchors.bottom: parent.bottom; width: parent.width - 68; height: 1; color: Theme.hairline }
                        }
                    }
                }
            }
        }
        // ---- Listas (búsqueda, categoría, instaladas) ----
        Text {
            visible: win.section !== "discover" && win.section !== "updates"
            x: 28; y: 18; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 26; font.weight: Font.Bold
            text: win.section === "installed" ? qsTr("Instaladas") : (win.section === "search" ? qsTr("Resultados de «%1»").arg(field.text) : win.catTitle)
        }
        ListView {
            id: list
            OverlayScroll { flick: list }
            visible: win.section !== "discover" && win.section !== "updates"
            x: 18; y: 64; width: parent.width - 36; height: parent.height - 64 - 12
            clip: true; model: Store; boundsBehavior: Flickable.DragAndOvershootBounds
            delegate: Item {
                width: list.width; height: 72
                AppTile { x: 10; anchors.verticalCenter: parent.verticalCenter; width: 48; height: 48; radius: 11; letter: model.name.charAt(0).toUpperCase(); icon: model.name
                          tint: Qt.hsla((model.name.charCodeAt(0) * 53 % 360) / 360, 0.55, 0.45, 1) }
                Column {
                    x: 72; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 72 - 110
                    Text { text: model.name; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.DemiBold; width: parent.width; elide: Text.ElideRight }
                    Text { text: model.desc; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12; width: parent.width; elide: Text.ElideRight }
                    Text { text: model.version + (model.repo !== "" ? " · " + model.repo : ""); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                }
                GetButton { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; pkg: model.id; installed: model.installed || (Store.stamp >= 0 && Store.isInstalled(model.id)) }
                Rectangle { x: 72; anchors.bottom: parent.bottom; width: parent.width - 72; height: 1; color: Theme.hairline }
            }
            Text { visible: Store.count === 0; anchors.centerIn: parent; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 15
                   text: Store.busy ? qsTr("Buscando…") : (win.section === "installed" ? qsTr("No hay software instalado") : qsTr("Sin resultados")) }
        }
        // ---- Actualizaciones ----
        Column {
            visible: win.section === "updates"
            x: 28; y: 18; width: parent.width - 56; spacing: 14
            Text { text: qsTr("Actualizaciones"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 26; font.weight: Font.Bold }
            Text { width: parent.width; wrapMode: Text.Wrap; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 13
                   text: qsTr("Actualiza BC OS y todas las apps instaladas desde los repositorios de Arch Linux ARM.") }
            Rectangle {
                width: ut.implicitWidth + 32; height: 30; radius: 15; color: Theme.accent; opacity: Store.busy ? 0.5 : 1
                Text { id: ut; anchors.centerIn: parent; text: qsTr("Actualizar todo"); color: "white"; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Bold }
                MouseArea { anchors.fill: parent; enabled: !Store.busy; onClicked: win.ask("update", "") }
            }
            Rectangle {
                visible: Store.log !== ""
                width: parent.width; height: 220; radius: 10; color: Theme.dark ? Qt.rgba(0, 0, 0, 0.35) : "#F2F2F4"; clip: true
                Flickable {
                    id: lf; anchors.fill: parent; anchors.margins: 10; contentHeight: logText.height; clip: true
                    onContentHeightChanged: contentY = Math.max(0, contentHeight - height)
                    Text { id: logText; width: lf.width; text: Store.log; wrapMode: Text.WrapAnywhere; color: Theme.textSecondary; font.family: Theme.fontMono; font.pixelSize: 11 }
                }
            }
        }
    }

    Item {
        id: pwDialog
        property bool open: false
        anchors.fill: parent
        z: 50
        visible: opacity > 0
        opacity: open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur(140) } }
        Rectangle { anchors.fill: parent; anchors.topMargin: -win.titlebarHeight; radius: Theme.radiusWindow; color: Theme.scrim }
        MouseArea { anchors.fill: parent; onClicked: { pwDialog.open = false; win.pending = null } }
        Rectangle {
            width: 380; height: 170; radius: 18; anchors.centerIn: parent
            color: Theme.popupFill; border.width: 1; border.color: Theme.hairline
            MouseArea { anchors.fill: parent }
            Text { x: 22; y: 18; text: qsTr("Se necesita tu contraseña"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 17; font.weight: Font.DemiBold }
            Text { x: 22; y: 44; width: parent.width - 44; wrapMode: Text.WordWrap
                   text: qsTr("Para instalar o quitar software hace falta permiso de administrador."); color: Theme.textSecondary
                   font.family: Theme.fontFamily; font.pixelSize: 13 }
            Rectangle {
                x: 22; y: 84; width: parent.width - 44; height: 36; radius: 10; color: Theme.tileFill
                TextInput {
                    id: pwInput
                    anchors.fill: parent; anchors.margins: 9
                    echoMode: TextInput.Password; passwordCharacter: "•"
                    color: Theme.textPrimary; selectionColor: Theme.textSelection
                    font.family: Theme.fontFamily; font.pixelSize: 16
                    onAccepted: { if (text !== "") { win.password = text; pwDialog.open = false; win.run() } }
                    Keys.onEscapePressed: { pwDialog.open = false; win.pending = null }
                }
            }
            Row {
                anchors.right: parent.right; anchors.rightMargin: 22; anchors.bottom: parent.bottom; anchors.bottomMargin: 14; spacing: 10
                Rectangle { width: 96; height: 32; radius: 10; color: Theme.tileFill
                    Text { anchors.centerIn: parent; text: qsTr("Cancelar"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 14 }
                    MouseArea { anchors.fill: parent; onClicked: { pwDialog.open = false; win.pending = null } } }
                Rectangle { width: 96; height: 32; radius: 10; color: Theme.accent
                    Text { anchors.centerIn: parent; text: qsTr("Aceptar"); color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 14; font.weight: Font.DemiBold }
                    MouseArea { anchors.fill: parent; onClicked: pwInput.accepted() } }
            }
        }
    }

    // Instalando o quitando: cápsula abajo con barra indeterminada de franjas animadas (como macOS)
    Rectangle {
        z: 40
        visible: opacity > 0; opacity: Store.busy ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.d(180) } }
        anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 18
        width: 300; height: 52; radius: 14
        color: Theme.popupFill; border.width: 1; border.color: Theme.hairline
        Text { x: 16; y: 8; text: qsTr("Instalando o quitando software…"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12 }
        Rectangle {
            id: stripes
            x: 16; y: 30; width: parent.width - 32; height: 8; radius: 4; clip: true
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.55)
            property real shift: 0
            NumberAnimation on shift { running: Store.busy; from: 0; to: 16; duration: 700; loops: Animation.Infinite }
            Repeater {
                model: Math.ceil(stripes.width / 16) + 3
                Rectangle { required property int index
                            x: index * 16 - 24 + stripes.shift; y: -6; width: 8; height: 20; rotation: 30
                            color: Qt.rgba(1, 1, 1, 0.35) }
            }
        }
    }
}
