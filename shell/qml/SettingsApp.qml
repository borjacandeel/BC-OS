import QtQuick
import BCShell

// Configuración: Apariencia, Sonido, Red, Energía, Usuarios y Acerca de (datos reales).
AppWindow {
    id: win
    sidebarWidth: 230
    width: 740 + 2 * sh
    height: 690 + 2 * sh
    title: qsTr("Ajustes del Sistema")
    property int page: AppConfig.classic ? 0 : 6
    // Historial para los botones atrás/adelante de la barra de herramientas (como en macOS 27)
    property var back: []
    property var fwd: []
    property bool nav: false
    onPageChanged: { if (!nav) { back = back.concat([prevPage]).slice(-20); fwd = [] } prevPage = page }
    property int prevPage: page
    function goBack() { if (!back.length) return; nav = true; fwd = [page].concat(fwd); const p = back[back.length - 1]; back = back.slice(0, -1); page = p; nav = false }
    function goFwd() { if (!fwd.length) return; nav = true; back = back.concat([page]); const p = fwd[0]; fwd = fwd.slice(1); page = p; nav = false }
    readonly property string pageName: { const f = pages.find(x => x.idx === page); if (f) return f.name
        return ({ 1: qsTr("Sonido"), 2: qsTr("Red"), 3: qsTr("Batería y energía"), 4: qsTr("Usuarios"), 5: qsTr("Acerca de"), 0: qsTr("General") })[page] || "" }
    // Barra de herramientas: cápsula ‹ › y título de la sección, a la derecha de la barra lateral
    titlebarContent: [
        Item {
            visible: Theme.gg
            x: 252; anchors.verticalCenter: parent ? parent.verticalCenter : undefined; width: 400; height: 34
            Rectangle {
                id: navCap; width: 72; height: 34; radius: 17; color: Theme.dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)
                border.width: 1; border.color: Theme.dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.08)
                Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: "‹"; font.pixelSize: 24; font.weight: Font.Light
                       color: win.back.length ? Theme.textPrimary : Theme.textSecondary; opacity: win.back.length ? 1 : 0.4
                       MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: win.goBack() } }
                Rectangle { anchors.centerIn: parent; width: 1; height: 18; color: Theme.hairline }
                Text { x: 46; anchors.verticalCenter: parent.verticalCenter; text: "›"; font.pixelSize: 24; font.weight: Font.Light
                       color: Theme.textPrimary; opacity: win.fwd.length ? 1 : 0.35
                       MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: win.goFwd() } }
            }
            Text { x: 86; anchors.verticalCenter: parent.verticalCenter; text: win.pageName; color: Theme.textPrimary
                   font.family: Theme.fontFamily; font.pixelSize: 15; font.weight: Font.Bold }
        }
    ]
    Component.onCompleted: {
        Monitor.active = Qt.binding(() => win.visible && win.page === 5)
        const o = AppConfig.openArg
        const map = { about: 5, red: 2, sonido: 1, energia: 3, usuarios: 4, aspecto: 6, dock: 7, fondo: 8, notificaciones: 9, general: 0,
                      wifi: 10, bluetooth: 11, pantallas: 12, teclado: 13, fecha: 14 }
        if (map[o] !== undefined) win.page = map[o]
    }

    // Golden Gate: barra lateral de borde a borde con iconos en color (cuadrado redondeado + glifo blanco)
    readonly property var pages: [
        { idx: 10, name: qsTr("Wi-Fi"), icon: "network-wireless-signal-excellent-symbolic", c: "#0A84FF" },
        { idx: 11, name: qsTr("Bluetooth"), icon: "bluetooth-active-symbolic", c: "#0A84FF" },
        { idx: 2, name: qsTr("Red"), icon: "network-wired-symbolic", c: "#0A84FF" },
        { idx: 1, name: qsTr("Sonido"), icon: "audio-volume-high-symbolic", c: "#FF375F" },
        { idx: 9, name: qsTr("Notificaciones"), icon: "notification-symbolic", c: "#FF453A" },
        { idx: 3, name: qsTr("Batería y energía"), icon: "preferences-system-power-symbolic", c: "#30D158" },
        { sep: true },
        { idx: 6, name: qsTr("Aspecto"), icon: "", g: "aspecto", c: "#1C1C1E" },
        { idx: 7, name: qsTr("Escritorio y Dock"), icon: "", g: "dock", c: "#1C1C1E" },
        { idx: 8, name: qsTr("Fondo de pantalla"), icon: "", g: "fondo", c: "#32ADE6" },
        { idx: 0, name: qsTr("General"), icon: "preferences-system-symbolic", c: "#8E8E93" },
        { idx: 12, name: qsTr("Pantallas"), icon: "display-brightness-symbolic", c: "#0A84FF" },
        { idx: 13, name: qsTr("Teclado"), icon: "input-keyboard-symbolic", c: "#8E8E93" },
        { idx: 14, name: qsTr("Fecha y hora"), icon: "", g: "reloj", c: "#8E8E93" },
        { sep: true },
        { idx: 4, name: qsTr("Usuarios"), icon: "system-users-symbolic", c: "#8E8E93" },
        { idx: 5, name: qsTr("Acerca de"), icon: "dialog-information-symbolic", c: "#8E8E93" }
    ]
    property string query: ""

    component Label: Text {
        color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: Theme.gg ? 13 : 15
    }
    component Hint: Text {
        leftPadding: Theme.gg && parent && parent.objectName !== "grp" && x === 0 ? 10 : 0
        color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.gg ? 12 : 13; wrapMode: Text.WordWrap
    }
    // Grupo de filas en una tarjeta con separadores finos (como en Ajustes de macOS 27)
    component Group: Rectangle {
        default property alias content: gcol.data
        width: parent.width; height: gcol.height; radius: Theme.gg ? 12 : 12; color: Theme.tileFill
        border.width: Theme.gg && Theme.lightUi ? 0.5 : 0; border.color: Qt.rgba(0, 0, 0, 0.05)
        Column { id: gcol; width: parent.width; objectName: "grp" }
    }
    component Row2: Rectangle {
        id: r2
        property string label
        property string value
        readonly property bool grouped: !!parent && parent.objectName === "grp"
        // Separador salvo en la primera fila visible del grupo
        readonly property bool firstVis: { if (!grouped) return true; const ch = parent.children
            for (let i = 0; i < ch.length; i++) if (ch[i].visible) return ch[i] === r2; return true }
        width: parent.width; height: Theme.gg ? 38 : 44; radius: Theme.gg ? 10 : 12; color: grouped ? "transparent" : Theme.tileFill
        Rectangle { visible: r2.grouped && !r2.firstVis; x: 10; width: parent.width - 20; height: 1; color: Theme.hairline }
        Label { x: Theme.gg ? 10 : 14; anchors.verticalCenter: parent.verticalCenter; text: parent.label }
        Label { anchors.right: parent.right; anchors.rightMargin: Theme.gg ? 10 : 14; anchors.verticalCenter: parent.verticalCenter
                text: parent.value; color: Theme.textSecondary }
    }
    component Switch: Rectangle {
        id: sw
        property bool on: false
        signal toggled(bool v)
        width: Theme.gg ? 38 : 46; height: Theme.gg ? 22 : 28; radius: height / 2
        color: on ? (Theme.gg ? Theme.accent : "#34C759") : (Theme.lightUi ? Qt.rgba(0, 0, 0, 0.12) : Qt.rgba(1, 1, 1, 0.22))
        Behavior on color { ColorAnimation { duration: Theme.dur(160) } }
        Rectangle { y: 2; x: sw.on ? sw.width - width - 2 : 2; width: sw.height - 4; height: width; radius: width / 2; color: "white"
                    border.width: Theme.lightUi ? 0.5 : 0; border.color: Qt.rgba(0, 0, 0, 0.15)
                    Behavior on x { NumberAnimation { duration: Theme.dur(160); easing.type: Theme.easing } } }
        MouseArea { anchors.fill: parent; onClicked: sw.toggled(!sw.on) }
    }
    // Deslizador como el de macOS 27: pista fina y tirador en cápsula blanca con sombra
    component GSlider: Item {
        id: gs
        property real value: 0
        signal moved(real v)
        height: 22
        Rectangle { id: gtr; anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2
                    color: Theme.lightUi ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(1, 1, 1, 0.16)
            Rectangle { width: Math.max(0, Math.min(1, gs.value)) * parent.width; height: parent.height; radius: 2; color: Theme.accent } }
        Rectangle { x: Math.max(0, Math.min(1, gs.value)) * (gs.width - width); anchors.verticalCenter: parent.verticalCenter
                    width: 22; height: 16; radius: 8; color: "white"; border.width: 0.5; border.color: Qt.rgba(0, 0, 0, 0.18)
                    Rectangle { z: -1; x: 0; y: 1; width: parent.width; height: parent.height; radius: 8; color: Qt.rgba(0, 0, 0, 0.12) } }
        MouseArea { anchors.fill: parent; anchors.margins: -6
                    function upd(m) { gs.moved(Math.max(0, Math.min(1, (m.x - 6 - 11) / (gs.width - 22)))) }
                    onPressed: (m) => upd(m); onPositionChanged: (m) => { if (pressed) upd(m) } }
    }
    // Botón emergente: valor y cápsula con flechas arriba/abajo (como en macOS)
    component PopBtn: Item {
        id: pb
        property string text
        signal clicked()
        anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
        width: pbT.implicitWidth + 32; height: 24
        Text { id: pbT; anchors.verticalCenter: parent.verticalCenter; text: pb.text; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13 }
        Rectangle { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; width: 20; height: 20; radius: 10
                    color: Theme.lightUi ? Qt.rgba(0, 0, 0, 0.06) : Qt.rgba(1, 1, 1, 0.10)
            Text { anchors.horizontalCenter: parent.horizontalCenter; y: 1; text: "⌃"; color: Theme.textPrimary; font.pixelSize: 9; font.bold: true }
            Text { anchors.horizontalCenter: parent.horizontalCenter; y: 7; text: "⌄"; color: Theme.textPrimary; font.pixelSize: 9; font.bold: true } }
        MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: pb.clicked() }
    }
    component Segmented: Row {
        property var options: []
        property int current: 0
        signal picked(int i)
        spacing: 4
        Repeater {
            model: parent.options
            Rectangle {
                width: 112; height: 32; radius: 9
                color: index === parent.current ? Theme.accent : Theme.tileFill
                opacity: modelData.enabled === false ? 0.45 : 1
                Text { anchors.centerIn: parent; text: modelData.label; color: index === parent.parent.current ? "white" : Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: Theme.gg ? 13 : 14 }
                MouseArea { anchors.fill: parent; enabled: modelData.enabled !== false; onClicked: parent.parent.picked(index) }
            }
        }
    }

    // Barra lateral (de borde a borde; más oscura en la ventana activa, como en Golden Gate)
    Rectangle {
        id: side
        width: 230; height: parent.height
        color: Theme.gg ? "transparent" : Qt.rgba(0.03, 0.06, 0.16, 0.45)
        SidebarGlass { anchors.fill: parent; active: win.active; z: -1 }
        Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.hairline }
        // Búsqueda
        Rectangle {
            x: 10; y: 8; width: parent.width - 20; height: Theme.gg ? 30 : 28; radius: Theme.gg ? 15 : 8; color: Theme.tileFill
            border.width: Theme.gg ? 1 : 0; border.color: Theme.lightUi ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.10)
            Icon { x: 10; anchors.verticalCenter: parent.verticalCenter; name: Icons.search; size: 14; color: Theme.textSecondary }
            TextInput { id: q; x: 30; width: parent.width - 36; anchors.verticalCenter: parent.verticalCenter; color: Theme.textPrimary
                        font.family: Theme.fontFamily; font.pixelSize: 13; onTextChanged: win.query = text.toLowerCase()
                        Text { visible: !parent.text; text: qsTr("Buscar"); color: Theme.textSecondary; font: parent.font } }
        }
        // Tarjeta de la cuenta (como en macOS: avatar, nombre y tipo de cuenta)
        Rectangle {
            x: 10; y: 42; width: parent.width - 20; height: 52; radius: 8; color: um.containsMouse ? Theme.tileFill : "transparent"
            readonly property var me: Users.users.find(u => u.name === Sessions.currentUserName()) || Users.users[0]
            Rectangle { x: 6; anchors.verticalCenter: parent.verticalCenter; width: 38; height: 38; radius: 19
                        gradient: Gradient { GradientStop { position: 0; color: "#8E9BB2" } GradientStop { position: 1; color: "#5A6478" } }
                        Text { anchors.centerIn: parent; text: parent.parent.me ? parent.parent.me.display.charAt(0).toUpperCase() : "?"; color: "white"
                               font.family: Theme.fontFamily; font.pixelSize: 17; font.weight: Font.DemiBold } }
            Column { x: 52; anchors.verticalCenter: parent.verticalCenter
                     Label { text: parent.parent.me ? parent.parent.me.display : ""; font.pixelSize: 13; font.weight: Font.DemiBold }
                     Hint { leftPadding: 0; text: qsTr("Cuenta local de BC OS"); font.pixelSize: 11 } }
            MouseArea { id: um; anchors.fill: parent; hoverEnabled: true; onClicked: win.page = 4 }
        }
        Flickable {
            x: 10; y: 100; width: parent.width - 20; height: parent.height - 108; clip: true
            contentHeight: sideCol.height; boundsBehavior: Flickable.StopAtBounds
        Column {
            id: sideCol
            width: parent.width; spacing: 1
            Repeater {
                model: win.pages
                Item {
                    required property var modelData
                    width: parent.width
                    visible: modelData.sep ? win.query === "" : (win.query === "" || modelData.name.toLowerCase().indexOf(win.query) >= 0)
                    height: !visible ? 0 : (modelData.sep ? 14 : (Theme.gg ? 32 : 30))
                    Rectangle { visible: !!modelData.sep; anchors.centerIn: parent; width: parent.width - 16; height: 1; color: Theme.hairline }
                    Rectangle {
                        visible: !modelData.sep
                        anchors.fill: parent; radius: Theme.gg ? 8 : 7
                        color: modelData.idx === win.page ? (win.active || !Theme.gg ? Theme.accent : Theme.tileFill) : (ma.containsMouse ? Theme.tileFill : "transparent")
                        // Golden Gate: iconos en color solo en la ventana activa
                        Rectangle { x: 7; anchors.verticalCenter: parent.verticalCenter; width: Theme.gg ? 22 : 20; height: width; radius: Theme.gg ? 6 : 5
                                    color: modelData.c || "#8E8E93"   // como macOS: iconos en color también con la ventana inactiva
                                    Icon { visible: !modelData.g; anchors.centerIn: parent; name: modelData.icon || ""; size: 14; color: "white" }
                                    // Glifos dibujados como en macOS: Aspecto (círculo mitad blanco) y Escritorio y Dock (ventana con Dock)
                                    Rectangle { visible: modelData.g === "aspecto"; anchors.centerIn: parent; width: 13; height: 13; radius: 6.5; color: "white"
                                        Item { x: 1.5; y: 1.5; width: 5; height: 10; clip: true
                                            Rectangle { width: 10; height: 10; radius: 5; color: modelData.c || "#1C1C1E" } } }
                                    // Fondo de pantalla: flor de seis pétalos; Fecha y hora: reloj
                                    Item { visible: modelData.g === "fondo"; anchors.centerIn: parent; width: 14; height: 14
                                        Repeater { model: 6
                                            Rectangle { required property int index; x: 5; y: 0; width: 4; height: 7; radius: 2; color: "white"; opacity: 0.95
                                                        transformOrigin: Item.Bottom; rotation: index * 60 } } }
                                    Rectangle { visible: modelData.g === "reloj"; anchors.centerIn: parent; width: 13; height: 13; radius: 6.5
                                                color: "transparent"; border.width: 1.5; border.color: "white"
                                        Rectangle { x: 5.75; y: 2.5; width: 1.5; height: 4.5; radius: 0.75; color: "white" }
                                        Rectangle { x: 6; y: 5.75; width: 3.5; height: 1.5; radius: 0.75; color: "white" } }
                                    Rectangle { visible: modelData.g === "dock"; anchors.centerIn: parent; width: 15; height: 12; radius: 3
                                                color: "transparent"; border.width: 1.5; border.color: "white"
                                        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 2.5
                                                    width: 9; height: 2.5; radius: 1.25; color: "white" } } }
                        Label { x: 37; anchors.verticalCenter: parent.verticalCenter; text: modelData.name || ""; font.pixelSize: 13
                                color: modelData.idx === win.page && (win.active || !Theme.gg) ? "white" : Theme.textPrimary }
                        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: win.page = modelData.idx }
                    }
                }
            }
        }
        }
    }

    Flickable {
        x: 254; y: 18; width: parent.width - 254 - 24; height: parent.height - 18 - 12
        // Alto de la página visible (todas las páginas son hijas directas): así cualquier página larga se desplaza
        contentHeight: { let h = height; const ch = contentItem.children; for (let i = 0; i < ch.length; i++) if (ch[i].visible) h = Math.max(h, ch[i].y + ch[i].height + 16); return h }
        clip: true

        // 6 Aspecto (Golden Gate)
        Column {
            id: pageCol6
            visible: win.page === 6; width: parent.width; spacing: 14
            Label { visible: !Theme.gg; text: qsTr("Aspecto"); font.pixelSize: 20; font.weight: Font.Bold }
            Group {
                // Aspecto: tres miniaturas a la derecha, la elegida con borde de resalte y nombre en negrita
                Item {
                    width: parent.width; height: 86
                    Label { x: 10; y: 10; text: qsTr("Aspecto") }
                    Row {
                        anchors.right: parent.right; anchors.rightMargin: 10; y: 8; spacing: 10
                        Repeater {
                            model: [ { v: "light", t: qsTr("Claro") }, { v: "dark", t: qsTr("Oscuro") }, { v: "auto", t: qsTr("Automático") } ]
                            Column {
                                required property var modelData
                                readonly property bool sel: Settings.appearance === modelData.v
                                spacing: 4
                                Rectangle {
                                    width: 72; height: 48; radius: 9; color: "transparent"
                                    border.width: parent.sel ? 2.5 : 0; border.color: Theme.accent
                                    Rectangle {
                                        anchors.fill: parent; anchors.margins: parent.parent.sel ? 4 : 0; radius: parent.parent.sel ? 6 : 9; clip: true
                                        color: modelData.v === "dark" ? "#1C2440" : "#B9D3F2"
                                        gradient: Gradient {
                                            GradientStop { position: 0; color: modelData.v === "dark" ? "#27305A" : "#CFE3FA" }
                                            GradientStop { position: 1; color: modelData.v === "dark" ? "#141A30" : "#8DB6E6" } }
                                        Rectangle { x: 6; y: 5; width: parent.width * 0.62; height: parent.height - 10; radius: 4
                                                    color: modelData.v === "dark" ? "#2C2C31" : "#FFFFFF"; opacity: 0.95
                                            Row { x: 4; y: 4; spacing: 2; Repeater { model: [Theme.close, Theme.minimize, Theme.zoom]
                                                  Rectangle { required property color modelData; width: 4; height: 4; radius: 2; color: modelData } } } }
                                        Item { visible: modelData.v === "auto"; x: parent.width / 2; width: parent.width / 2; height: parent.height; clip: true
                                               Rectangle { x: -parent.x; width: parent.parent.width; height: parent.height
                                                           gradient: Gradient { GradientStop { position: 0; color: "#27305A" } GradientStop { position: 1; color: "#141A30" } } }
                                               Rectangle { x: 6 - parent.x; y: 5; width: parent.parent.width * 0.62; height: parent.parent.height - 10; radius: 4; color: "#2C2C31" } }
                                    }
                                    MouseArea { anchors.fill: parent; onClicked: Settings.appearance = modelData.v }
                                }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.t; font.family: Theme.fontFamily; font.pixelSize: 11
                                       font.weight: parent.sel ? Font.DemiBold : Font.Normal; color: parent.sel ? Theme.textPrimary : Theme.textSecondary }
                            }
                        }
                    }
                }
                // Liquid Glass: vista previa sobre el fondo con barra de cristal y deslizador transparente ↔ tintado
                Item {
                    width: parent.width; height: 228
                    Rectangle { x: 10; width: parent.width - 20; height: 1; color: Theme.hairline }
                    Label { x: 10; y: 12; text: qsTr("Liquid Glass") }
                    Rectangle {
                        id: lgPrev
                        anchors.right: parent.right; anchors.rightMargin: 10; y: 10; width: 268; height: 180; radius: 12; clip: true; color: "#33415C"
                        Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize: Qt.size(536, 360)
                                source: win.page !== 6 ? "" : (Settings.wallpaper !== "" ? "file://" + Settings.wallpaper : "qrc:/BCShell/assets/wallpaper-default.png") }
                        Repeater {
                            model: [ { x: 8, w: 72, t: "↗   ⋯" }, { x: 86, w: 34, t: "❐" }, { x: 126, w: 134, t: qsTr("Buscar") } ]
                            Rectangle {
                                required property var modelData
                                x: modelData.x; y: 8; width: modelData.w; height: 34; radius: 17
                                color: Qt.rgba(1, 1, 1, 0.18 + 0.62 * Settings.glassTint); border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.45)
                                Icon { visible: modelData.w > 100; x: 11; anchors.verticalCenter: parent.verticalCenter; name: Icons.search; size: 14
                                       color: Settings.glassTint > 0.5 ? "#1D1D1F" : "white" }
                                Text { anchors.verticalCenter: parent.verticalCenter; x: modelData.w > 100 ? 31 : (parent.width - width) / 2; text: modelData.t
                                       color: Settings.glassTint > 0.5 ? "#1D1D1F" : "white"; font.family: Theme.fontFamily; font.pixelSize: 13 }
                            }
                        }
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 44; color: Qt.rgba(0.96, 0.95, 0.93, 0.92)
                                    Text { x: 14; anchors.verticalCenter: parent.verticalCenter; text: qsTr("Bienvenido a BC OS"); color: "#1D1D1F"
                                           font.family: Theme.fontFamily; font.pixelSize: 15; font.weight: Font.DemiBold } }
                    }
                    GSlider { anchors.right: parent.right; anchors.rightMargin: 34; y: lgPrev.y + lgPrev.height + 12; width: 222
                              value: Settings.glassTint; onMoved: (v) => Settings.glassTint = v }
                    Rectangle { x: lgPrev.x + 2; y: lgPrev.y + lgPrev.height + 14; width: 13; height: 10; radius: 3; color: "transparent"; border.width: 1.2; border.color: Theme.textSecondary }
                    Rectangle { x: lgPrev.x + lgPrev.width - 15; y: lgPrev.y + lgPrev.height + 14; width: 13; height: 10; radius: 3; color: Theme.textSecondary }
                }
            }
            Label { text: qsTr("Tema"); font.weight: Theme.gg ? Font.Bold : Font.DemiBold; leftPadding: Theme.gg ? 10 : 0; topPadding: Theme.gg ? 10 : 0 }
            Group {
                Item {
                    width: parent.width; height: 58
                    Label { x: 10; y: 11; text: qsTr("Color") }
                    Row {
                        anchors.right: parent.right; anchors.rightMargin: 10; y: 6; spacing: 10
                        Repeater {
                            model: [ { c: "#0A84FF", n: qsTr("Azul") }, { c: "#BF5AF2", n: qsTr("Morado") }, { c: "#FF375F", n: qsTr("Rosa") },
                                     { c: "#FF453A", n: qsTr("Rojo") }, { c: "#FF9F0A", n: qsTr("Naranja") }, { c: "#FFD60A", n: qsTr("Amarillo") },
                                     { c: "#30D158", n: qsTr("Verde") }, { c: "#8E8E93", n: qsTr("Grafito") } ]
                            Item {
                                required property var modelData
                                readonly property bool sel: Settings.accent.toUpperCase() === modelData.c
                                width: 26; height: 46
                                Rectangle { y: 0; width: 26; height: 26; radius: 13; color: "transparent"; border.width: parent.sel ? 2 : 0; border.color: modelData.c
                                            Rectangle { anchors.centerIn: parent; width: parent.parent.sel ? 18 : 24; height: width; radius: width / 2; color: modelData.c
                                                        border.width: 0.5; border.color: Qt.rgba(0, 0, 0, 0.12) } }
                                Text { visible: parent.sel; anchors.horizontalCenter: parent.horizontalCenter; y: 30; text: modelData.n; color: Theme.textSecondary
                                       font.family: Theme.fontFamily; font.pixelSize: 11 }
                                MouseArea { anchors.fill: parent; onClicked: Settings.accent = modelData.c }
                            }
                        }
                    }
                }
            }
            Group {
                Row2 { label: qsTr("Reducir movimiento"); value: ""
                       Switch { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                on: Settings.reducedMotion; onToggled: (v) => Settings.reducedMotion = v } }
                Row2 { label: qsTr("Sonidos de la interfaz"); value: ""
                       Switch { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                on: Settings.sounds; onToggled: (v) => Settings.sounds = v } }
            }
        }

        // 7 Escritorio y Dock
        Column {
            id: pageCol7
            visible: win.page === 7; width: parent.width; spacing: 12
            Label { visible: !Theme.gg; text: qsTr("Escritorio y Dock"); font.pixelSize: 20; font.weight: Font.Bold }
            Label { visible: Theme.gg; text: qsTr("Dock"); font.weight: Font.Bold; leftPadding: 10 }
            Group {
                Item {
                    width: parent.width; height: 68
                    Label { x: 10; y: 10; text: qsTr("Tamaño") }
                    GSlider { x: 10; y: 30; width: parent.width - 20; value: (Settings.dockSize - 32) / 64
                              onMoved: (v) => Settings.dockSize = Math.round(32 + 64 * v) }
                    Hint { x: 10; y: 50; text: qsTr("Pequeño"); font.pixelSize: 11 }
                    Hint { anchors.right: parent.right; anchors.rightMargin: 10; y: 50; text: qsTr("Grande"); font.pixelSize: 11 }
                }
            }
            Group {
                Row2 { label: qsTr("Ampliación"); value: ""
                       Switch { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                on: Settings.dockMagnify; onToggled: (v) => Settings.dockMagnify = v } }
                Row2 { label: qsTr("Ocultar y mostrar el Dock automáticamente"); value: ""
                       Switch { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                on: Settings.dockAutohide; onToggled: (v) => Settings.dockAutohide = v } }
                Row2 { label: qsTr("Mostrar apps recientes en el Dock"); value: ""
                       Switch { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                on: Settings.dockShowRecent; onToggled: (v) => Settings.dockShowRecent = v } }
                Row2 { label: qsTr("Restablecer las apps del Dock"); value: ""
                       Rectangle { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; width: 110; height: 26; radius: 7; color: Theme.tileFill
                                   Text { anchors.centerIn: parent; text: qsTr("Restablecer"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                                   MouseArea { anchors.fill: parent; onClicked: Settings.dockApps = [] } } }
            }
            Label { text: qsTr("Widgets"); font.weight: Theme.gg ? Font.Bold : Font.DemiBold; leftPadding: Theme.gg ? 10 : 0; topPadding: Theme.gg ? 6 : 0 }
            Group {
                Row2 { label: qsTr("Mostrar widgets en el escritorio"); value: ""
                       Switch { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                on: Settings.widgets; onToggled: (v) => Settings.widgets = v } }
                Row2 { label: qsTr("Volver a colocar los widgets en su columna"); value: ""
                       Rectangle { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; width: 110; height: 26; radius: 7; color: Theme.tileFill
                                   Text { anchors.centerIn: parent; text: qsTr("Colocar"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                                   MouseArea { anchors.fill: parent; onClicked: Settings.widgetLayout = "{}" } } }
            }
            Hint { width: parent.width; text: qsTr("Otras apps pueden añadir su widget dejando un archivo JSON en ~/.local/share/bc/widgets/.") }
            Label { text: qsTr("Esquinas activas"); font.weight: Theme.gg ? Font.Bold : Font.DemiBold; leftPadding: Theme.gg ? 10 : 0; topPadding: Theme.gg ? 6 : 0 }
            Group {
                Repeater {
                    model: [qsTr("Arriba a la izquierda"), qsTr("Arriba a la derecha"), qsTr("Abajo a la izquierda"), qsTr("Abajo a la derecha")]
                    Row2 {
                        required property string modelData
                        required property int index
                        readonly property var opts: [ { v: "", t: "—" }, { v: "mission", t: qsTr("Mission Control") }, { v: "desktop", t: qsTr("Escritorio") },
                                                      { v: "launchpad", t: qsTr("Aplicaciones") }, { v: "notifications", t: qsTr("Notificaciones") },
                                                      { v: "notes", t: qsTr("Nota rápida") }, { v: "lock", t: qsTr("Bloquear pantalla") } ]
                        readonly property int cur: Math.max(0, opts.findIndex(o => o.v === (Settings.hotCorners[index] || "")))
                        label: modelData; value: ""
                        PopBtn { text: parent.opts[parent.cur].t
                                 onClicked: { const l = Settings.hotCorners.slice(); const o = parent.opts; l[index] = o[(parent.cur + 1) % o.length].v; Settings.hotCorners = l } }
                    }
                }
            }
            Label { text: qsTr("Mission Control"); font.weight: Theme.gg ? Font.Bold : Font.DemiBold; leftPadding: Theme.gg ? 10 : 0; topPadding: Theme.gg ? 6 : 0 }
            Hint { width: parent.width; text: qsTr("Ctrl+↑ o F3, o desliza tres dedos hacia arriba. Ctrl+←/→ cambia de escritorio.") }
        }

        // 8 Fondo de pantalla
        Column {
            visible: win.page === 8; width: parent.width; spacing: 12
            Label { visible: !Theme.gg; text: qsTr("Fondo de pantalla"); font.pixelSize: 20; font.weight: Font.Bold }
            Grid {
                id: wallGrid
                columns: Math.max(3, Math.floor((parent.width + 12) / 162)); spacing: 12
                readonly property real cellW: (parent.width - (columns - 1) * spacing) / columns
                Repeater {
                    model: ["bosque-niebla.jpg", "pinar-alba.jpg", "lago-claro.jpg", "nieve.jpg", "salvia.jpg",
                            "bosque-noche.jpg", "aurora-boreal.jpg", "lago-noche.jpg", "bruma-verde.jpg", "luna.jpg",
                            "ondas.jpg", "aurora.jpg", "atardecer.jpg", "rubi.jpg", "bosque.jpg", "carbon.jpg", "noche.jpg", "medianoche.jpg",
                            "amanecer.jpg", "lavanda.jpg", "menta.jpg", "niebla.jpg", "oceano.jpg", "montanas.jpg", "grafito.jpg", "plata.jpg",
                            "dunas.jpg", "dunas-noche.jpg", "esferas.jpg", "esferas-luz.jpg", "anillos.jpg", "cristal.jpg", "seda.jpg", "pliegues.jpg", "bruma.jpg", "nebulosa.jpg", "horizonte.jpg", "colinas.jpg", "arcos.jpg", "cuarzo.jpg", "orbita.jpg", "topografia.jpg", "petalos.jpg", "burbujas.jpg", "cinta.jpg", "eclipse.jpg"]
                    Rectangle {
                        required property string modelData
                        readonly property string path: "/usr/share/bc/wallpapers/" + modelData
                        width: wallGrid.cellW; height: Math.round(width * 9 / 16); radius: 10; clip: true; color: Theme.tileFill
                        border.width: (Settings.wallpaper === path || (Settings.wallpaper === "" && modelData === "ondas.jpg")) ? 3 : 0; border.color: Theme.accent
                        Image { anchors.fill: parent; anchors.margins: parent.border.width; source: win.page === 8 ? "file://" + parent.path : ""; sourceSize: Qt.size(340, 192); fillMode: Image.PreserveAspectCrop; asynchronous: true }
                        MouseArea { anchors.fill: parent; onClicked: Settings.wallpaper = (modelData === "ondas.jpg" ? "" : parent.path) }
                    }
                }
            }
        }

        // 10 Wi-Fi
        Column {
            visible: win.page === 10; width: parent.width; spacing: 12
            onVisibleChanged: if (visible) Quick.scanWifi()
            Label { visible: !Theme.gg; text: qsTr("Wi-Fi"); font.pixelSize: 20; font.weight: Font.Bold }
            Group {
                Row2 { label: qsTr("Wi-Fi"); value: ""
                       Switch { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                on: SystemStatus.wifiEnabled; onToggled: (v) => { SystemStatus.setWifi(v); if (v) Quick.scanWifi() } } }
            }
            Hint { visible: !SystemStatus.hasWifi; text: qsTr("Este equipo no tiene adaptador Wi-Fi.") }
            Label { visible: SystemStatus.hasWifi; text: qsTr("Redes conocidas y cercanas"); font.weight: Font.DemiBold }
            Rectangle {
                visible: SystemStatus.hasWifi && SystemStatus.wifiEnabled
                width: parent.width; height: Math.max(44, wl.height + 8); radius: 10; color: Theme.tileFill
                Column {
                    id: wl; x: 4; y: 4; width: parent.width - 8
                    Repeater {
                        model: Quick.networks
                        Rectangle {
                            required property var modelData
                            width: wl.width; height: 36; radius: 7; color: wm.containsMouse ? Theme.fillHover : "transparent"
                            Icon { x: 10; anchors.verticalCenter: parent.verticalCenter; size: 16; color: Theme.textPrimary
                                   name: Icons.networkIcon(true, false, SystemStatus.signalBars(modelData.signal)) }
                            Label { x: 36; anchors.verticalCenter: parent.verticalCenter; text: modelData.ssid; font.weight: modelData.active ? Font.DemiBold : Font.Normal }
                            Hint { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                   text: modelData.active ? qsTr("Conectado") : (modelData.secure ? "🔒" : "") }
                            MouseArea { id: wm; anchors.fill: parent; hoverEnabled: true
                                        onClicked: if (!modelData.active) { if (modelData.secure) { wpw.ssid = modelData.ssid; wpw.visible = true; wpwIn.forceActiveFocus() } else Quick.connectWifi(modelData.ssid) } }
                        }
                    }
                    Hint { visible: Quick.networks.length === 0; padding: 10; text: Quick.busy ? qsTr("Buscando redes…") : qsTr("No se encontraron redes") }
                }
            }
            Rectangle {
                id: wpw; visible: false; property string ssid
                width: parent.width; height: 40; radius: 10; color: Theme.tileFill; border.width: 2; border.color: Theme.accent
                TextInput { id: wpwIn; anchors.fill: parent; anchors.leftMargin: 12; verticalAlignment: TextInput.AlignVCenter; echoMode: TextInput.Password
                            color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13
                            onAccepted: { Quick.connectWifi(wpw.ssid, text); text = ""; wpw.visible = false }
                            Text { visible: !parent.text; anchors.verticalCenter: parent.verticalCenter; text: qsTr("Contraseña de «%1»").arg(wpw.ssid); color: Theme.textSecondary; font: parent.font } }
            }
        }

        // 11 Bluetooth
        Column {
            visible: win.page === 11; width: parent.width; spacing: 12
            onVisibleChanged: if (visible && SystemStatus.bluetoothOn) Quick.scanBluetooth()
            Label { visible: !Theme.gg; text: qsTr("Bluetooth"); font.pixelSize: 20; font.weight: Font.Bold }
            Group {
                Row2 { label: qsTr("Bluetooth"); value: ""
                       Switch { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                on: SystemStatus.bluetoothOn; onToggled: (v) => { SystemStatus.setBluetooth(v); if (v) Quick.scanBluetooth() } } }
            }
            Hint { visible: !SystemStatus.bluetoothAvailable; text: qsTr("Este equipo no tiene adaptador Bluetooth.") }
            Label { visible: SystemStatus.bluetoothOn; text: qsTr("Dispositivos"); font.weight: Font.DemiBold }
            Rectangle {
                visible: SystemStatus.bluetoothOn
                width: parent.width; height: Math.max(44, bl.height + 8); radius: 10; color: Theme.tileFill
                Column {
                    id: bl; x: 4; y: 4; width: parent.width - 8
                    Repeater {
                        model: Quick.btDevices
                        Rectangle {
                            required property var modelData
                            width: bl.width; height: 36; radius: 7; color: bm2.containsMouse ? Theme.fillHover : "transparent"
                            Icon { x: 10; anchors.verticalCenter: parent.verticalCenter; name: "bluetooth-active-symbolic"; size: 16; color: modelData.connected ? Theme.accent : Theme.textSecondary }
                            Label { x: 36; anchors.verticalCenter: parent.verticalCenter; text: modelData.name }
                            Rectangle { anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
                                        width: bt2.implicitWidth + 20; height: 24; radius: 6; color: Theme.fill
                                        Text { id: bt2; anchors.centerIn: parent; text: modelData.connected ? qsTr("Desconectar") : qsTr("Conectar"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                                        MouseArea { anchors.fill: parent; onClicked: Quick.toggleBluetoothDevice(modelData.mac, !modelData.connected) } }
                            MouseArea { id: bm2; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
                        }
                    }
                    Hint { visible: Quick.btDevices.length === 0; padding: 10; text: Quick.busy ? qsTr("Buscando dispositivos…") : qsTr("No hay dispositivos") }
                }
            }
        }

        // 12 Pantallas
        Column {
            visible: win.page === 12; width: parent.width; spacing: 12
            onVisibleChanged: if (visible) Quick.listDisplayModes()
            Label { visible: !Theme.gg; text: qsTr("Pantallas"); font.pixelSize: 20; font.weight: Font.Bold }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter; width: 260; height: 150; radius: 8; color: "#1C1C1E"; border.width: 3; border.color: "#3A3A3C"
                Image { anchors.fill: parent; anchors.margins: 3; source: "qrc:/BCShell/assets/wallpaper-default.png"; fillMode: Image.PreserveAspectCrop; sourceSize.width: 520 }
            }
            Label { text: qsTr("Resolución"); font.weight: Theme.gg ? Font.Bold : Font.DemiBold; leftPadding: Theme.gg ? 10 : 0; topPadding: Theme.gg ? 6 : 0 }
            Flow {
                width: parent.width; spacing: 8
                Repeater {
                    model: ["auto"].concat(Quick.displayModes.slice(0, 11))
                    Rectangle {
                        required property string modelData
                        width: rt.implicitWidth + 24; height: 30; radius: 8; color: rma.containsMouse ? Theme.fillHover : Theme.tileFill
                        Text { id: rt; anchors.centerIn: parent; text: modelData === "auto" ? qsTr("Automática") : modelData.replace("x", " × "); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                        MouseArea { id: rma; anchors.fill: parent; hoverEnabled: true; onClicked: Quick.setDisplayMode(modelData) }
                    }
                }
            }
            Hint { width: parent.width; text: qsTr("«Automática» se adapta al monitor o a la ventana de la máquina virtual.") }
        }

        // 13 Teclado
        Column {
            visible: win.page === 13; width: parent.width; spacing: 12
            property string current: Quick.keyboardLayout()
            Label { visible: !Theme.gg; text: qsTr("Teclado"); font.pixelSize: 20; font.weight: Font.Bold }
            Label { text: qsTr("Fuentes de entrada"); font.weight: Theme.gg ? Font.Bold : Font.DemiBold; leftPadding: Theme.gg ? 10 : 0; topPadding: Theme.gg ? 6 : 0 }
            Rectangle {
                width: parent.width; height: kl.height + 8; radius: 10; color: Theme.tileFill
                Column {
                    id: kl; x: 4; y: 4; width: parent.width - 8
                    Repeater {
                        model: [ { k: "es", t: qsTr("Español") }, { k: "latam", t: qsTr("Español (Latinoamérica)") }, { k: "us", t: qsTr("Inglés (EE. UU.)") },
                                 { k: "gb", t: qsTr("Inglés (Reino Unido)") }, { k: "fr", t: qsTr("Francés") }, { k: "de", t: qsTr("Alemán") },
                                 { k: "it", t: qsTr("Italiano") }, { k: "pt", t: qsTr("Portugués") } ]
                        Rectangle {
                            required property var modelData
                            width: kl.width; height: 32; radius: 7; color: km2.containsMouse ? Theme.fillHover : "transparent"
                            Label { x: 12; anchors.verticalCenter: parent.verticalCenter; text: modelData.t }
                            Text { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; visible: kl.parent.parent.current === modelData.k
                                   text: "✓"; color: Theme.accent; font.pixelSize: 14; font.weight: Font.Bold }
                            MouseArea { id: km2; anchors.fill: parent; hoverEnabled: true
                                        onClicked: if (Quick.setKeyboardLayout(modelData.k)) kl.parent.parent.current = modelData.k }
                        }
                    }
                }
            }
            Hint { width: parent.width; text: qsTr("La distribución se aplica al momento y se recuerda al iniciar sesión. Atajos: Súper+F1.") }
        }

        // 14 Fecha y hora
        Column {
            visible: win.page === 14; width: parent.width; spacing: 12
            Label { visible: !Theme.gg; text: qsTr("Fecha y hora"); font.pixelSize: 20; font.weight: Font.Bold }
            Group {
                Row2 { label: qsTr("Formato de 24 horas"); value: ""
                       Switch { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                on: Settings.clock24; onToggled: (v) => Settings.clock24 = v } }
                Row2 { label: qsTr("Hora y fecha automáticas"); value: qsTr("Activado (systemd-timesyncd)") }
            }
            Hint { width: parent.width; text: qsTr("La barra de menús muestra la fecha y la hora como en macOS («Dom 15 nov 12:19 a.m.»); con 24 horas, «Dom 15 nov 0:19».") }
        }

        // 9 Notificaciones
        Column {
            visible: win.page === 9; width: parent.width; spacing: 12
            Label { visible: !Theme.gg; text: qsTr("Notificaciones"); font.pixelSize: 20; font.weight: Font.Bold }
            Group {
                Row2 { label: qsTr("No molestar"); value: ""
                       Switch { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                on: Settings.mode === "focus"; onToggled: (v) => Settings.mode = v ? "focus" : "" } }
            }
            Hint { width: parent.width; text: qsTr("Con «No molestar» las notificaciones se guardan en el Centro de notificaciones sin mostrarse. Ábrelo pulsando la fecha y la hora.") }
        }

        // 0 Apariencia
        Column {
            visible: win.page === 0; width: parent.width; spacing: 12
            Label { visible: !Theme.gg; text: qsTr("General"); font.pixelSize: Theme.gg ? 20 : 22; font.weight: Theme.gg ? Font.Bold : Font.DemiBold }
            Group {
                Row2 { label: qsTr("Widgets en el escritorio"); value: ""
                       Switch { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                on: Settings.widgets; onToggled: (v) => Settings.widgets = v } }
            }
            Rectangle { width: 260; height: 40; radius: 12; color: Theme.accent
                        Text { anchors.centerIn: parent; text: qsTr("Abrir el asistente de bienvenida"); color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 14 }
                        MouseArea { anchors.fill: parent; onClicked: Launcher.run("bc-ctl", ["welcome"]) } }
            Label { text: qsTr("Instantáneas del sistema"); font.weight: Theme.gg ? Font.Bold : Font.DemiBold; leftPadding: Theme.gg ? 10 : 0; topPadding: Theme.gg ? 6 : 0 }
            Hint { width: parent.width; text: qsTr("Se guarda una antes de cada actualización o instalación. Restaurar vuelve a las versiones de entonces.") }
            Column {
                width: parent.width; spacing: 6
                property var list: win.page === 0 ? Quick.snapshots() : []
                Hint { visible: parent.list.length === 0; text: qsTr("Todavía no hay instantáneas.") }
                Repeater {
                    model: parent.list.slice(0, 5)
                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width; height: 40; radius: 10; color: Theme.tileFill
                        Label { x: 14; anchors.verticalCenter: parent.verticalCenter; text: modelData.fecha + "  ·  " + qsTr("%1 paquetes").arg(modelData.paquetes) }
                        Rectangle { anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
                                    width: rT.implicitWidth + 24; height: 26; radius: 13; color: Theme.accent
                                    Text { id: rT; anchors.centerIn: parent; text: qsTr("Restaurar"); color: "white"; font.family: Theme.fontFamily; font.pixelSize: 12 }
                                    MouseArea { anchors.fill: parent; onClicked: Launcher.run("pkexec", ["/usr/lib/bc/bc-paquetes", "restaurar", modelData.id]) } }
                    }
                }
            }
            Label { text: qsTr("Dónde se ejecuta BC OS"); font.weight: Theme.gg ? Font.Bold : Font.DemiBold; leftPadding: Theme.gg ? 10 : 0; topPadding: Theme.gg ? 6 : 0 }
            Row {
                id: eqRow; spacing: 12
                property string kind: Quick.machineKind()
                Repeater {
                    model: [ { k: "vm", t: qsTr("Máquina virtual"), d: qsTr("Por software, sin efectos de GPU") },
                             { k: "fisico", t: qsTr("Equipo físico"), d: Quick.hasGpu() ? qsTr("GPU: desenfoque, sombras, esquinas") : qsTr("GPU (no detectada ahora)") } ]
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool sel: eqRow.kind === modelData.k
                        width: 250; height: 66; radius: 14
                        color: sel ? Theme.accentSelected : Theme.tileFill
                        border.width: sel ? 2 : 0; border.color: Theme.accent
                        Column { anchors.centerIn: parent; spacing: 4
                                 Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.t + (Quick.detectedMachine() === modelData.k ? qsTr(" · detectado") : ""); font.weight: Font.DemiBold }
                                 Hint { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.d } }
                        MouseArea { anchors.fill: parent; onClicked: { if (Quick.setMachineKind(modelData.k)) eqRow.kind = modelData.k } }
                    }
                }
            }
            Group {
                Row2 { id: cornersRow; label: qsTr("Esquinas redondeadas en todas las ventanas (también sin GPU)"); value: ""
                       property bool on: Quick.roundedCorners()
                       Switch { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                on: cornersRow.on; onToggled: (v) => { if (Quick.setRoundedCorners(v)) cornersRow.on = v } } }
            }
            Hint { width: parent.width; text: qsTr("Se aplica al volver a iniciar sesión. Sin GPU las esquinas se dibujan por software: si notas lentitud, desactívalas.") }
            Label { text: qsTr("Entorno al iniciar sesión"); font.weight: Theme.gg ? Font.Bold : Font.DemiBold; leftPadding: Theme.gg ? 10 : 0; topPadding: Theme.gg ? 6 : 0 }
            Row {
                spacing: 12
                Repeater {
                    model: Sessions.sessions
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool sel: Sessions.runningId === modelData.id
                        width: 250; height: 66; radius: 14
                        color: sel ? Theme.accentSelected : Theme.tileFill
                        border.width: sel ? 2 : 0; border.color: Theme.accent
                        Column { anchors.centerIn: parent; spacing: 4
                                 Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.name; font.weight: Font.DemiBold }
                                 Hint { anchors.horizontalCenter: parent.horizontalCenter; width: 230; horizontalAlignment: Text.AlignHCenter; text: modelData.comment } }
                        MouseArea { anchors.fill: parent; onClicked: { if (Sessions.remember(Sessions.currentUserName(), modelData.id)) { envNote.text = qsTr("Se usará «%1» la próxima vez que inicies sesión.").arg(modelData.name) } } }
                    }
                }
            }
            Hint { id: envNote; text: qsTr("Elige el entorno y cierra sesión para cambiar: en el login también puedes escogerlo.") }
            Label { text: qsTr("Estilo de escritorio"); font.weight: Theme.gg ? Font.Bold : Font.DemiBold; leftPadding: Theme.gg ? 10 : 0; topPadding: Theme.gg ? 6 : 0 }
            Row {
                spacing: 12
                Repeater {
                    model: [{ id: "mac", name: qsTr("BC"), desc: qsTr("Barra superior y Dock") },
                            { id: "win", name: qsTr("Windows"), desc: qsTr("Barra de tareas y menú Inicio") }]
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool sel: Settings.desktopStyle === modelData.id
                        width: 160; height: 76; radius: 14
                        color: sel ? Theme.accentSelected : Theme.tileFill
                        border.width: sel ? 2 : 0; border.color: Theme.accent
                        Column { anchors.centerIn: parent; spacing: 4
                                 Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.name; font.weight: Font.DemiBold }
                                 Hint { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.desc } }
                        MouseArea { anchors.fill: parent; onClicked: Settings.desktopStyle = modelData.id }
                    }
                }
            }
            Rectangle {
                width: parent.width; height: 56; radius: 12; color: Theme.tileFill
                Label { x: 14; y: 9; text: qsTr("Reducir movimiento") }
                Hint { x: 14; y: 31; text: qsTr("Desactiva las animaciones del escritorio"); width: parent.width - 90 }
                Switch { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
                         on: Settings.reducedMotion; onToggled: (v) => Settings.reducedMotion = v }
            }
            Rectangle {
                width: parent.width; height: 74; radius: 12; color: Theme.tileFill
                Label { x: 14; y: 9; text: qsTr("Idioma") }
                Hint { x: 14; y: 33; text: qsTr("Se aplica al volver a iniciar sesión"); width: parent.width - 28 }
                Segmented {
                    anchors.right: parent.right; anchors.rightMargin: 14; y: 9
                    options: [{ label: "Español" }, { label: "English" }]
                    current: Settings.language.indexOf("en") === 0 ? 1 : 0
                    onPicked: (i) => Settings.language = i === 1 ? "en" : "es_ES"
                }
            }
            Rectangle {
                width: parent.width; height: 74; radius: 12; color: Theme.tileFill
                Label { x: 14; y: 9; text: qsTr("Tema") }
                Hint { x: 14; y: 33; text: qsTr("El tema claro llegará en una versión futura"); width: parent.width - 28 }
                Segmented {
                    anchors.right: parent.right; anchors.rightMargin: 14; y: 9
                    options: [{ label: qsTr("Oscuro") }, { label: qsTr("Claro"), enabled: false }]
                }
            }
            Rectangle {
                width: parent.width; height: 150; radius: 12; color: Theme.tileFill
                Label { x: 14; y: 9; text: qsTr("Fondo de pantalla") }
                Image { x: 14; y: 36; height: 100; width: 160; fillMode: Image.PreserveAspectCrop
                        source: "qrc:/BCShell/assets/wallpaper-default.png"; smooth: true }
                Hint { x: 190; y: 40; text: qsTr("BC OS (predeterminado)"); width: 200 }
            }
        }

        // 1 Sonido
        Column {
            visible: win.page === 1; width: parent.width; spacing: 12
            Label { visible: !Theme.gg; text: qsTr("Sonido"); font.pixelSize: Theme.gg ? 20 : 22; font.weight: Theme.gg ? Font.Bold : Font.DemiBold }
            Hint { visible: !SystemStatus.audioAvailable; width: parent.width
                   text: qsTr("No se detecta ningún dispositivo de audio (PipeWire).") }
            Rectangle {
                visible: SystemStatus.audioAvailable
                width: parent.width; height: 92; radius: 12; color: Theme.tileFill
                Label { x: 14; y: 10; text: qsTr("Volumen de salida") + "  " + Math.round(SystemStatus.volume * 100) + " %" }
                Rectangle { id: vt; x: 14; y: 56; width: parent.width - 120; height: 6; radius: 3; color: Theme.tileFill
                    Rectangle { width: parent.width * Math.min(1, SystemStatus.muted ? 0 : SystemStatus.volume); height: parent.height; radius: 3; color: Theme.accent }
                    Rectangle { x: parent.width * Math.min(1, SystemStatus.muted ? 0 : SystemStatus.volume) - 10; y: -7; width: 20; height: 20; radius: 10; color: "#E8EAF0" }
                    MouseArea { x: -10; y: -14; width: parent.width + 20; height: 34
                        onPressed: (m) => SystemStatus.setVolume((m.x - 10) / vt.width)
                        onPositionChanged: (m) => { if (pressed) SystemStatus.setVolume((m.x - 10) / vt.width) } }
                }
                Label { anchors.right: parent.right; anchors.rightMargin: 14; y: 10; text: qsTr("Silenciar"); color: Theme.textSecondary }
                Switch { anchors.right: parent.right; anchors.rightMargin: 14; y: 44; on: SystemStatus.muted; onToggled: SystemStatus.toggleMute() }
            }
        }

        // 2 Red
        Column {
            visible: win.page === 2; width: parent.width; spacing: 10
            Label { visible: !Theme.gg; text: qsTr("Red"); font.pixelSize: Theme.gg ? 20 : 22; font.weight: Theme.gg ? Font.Bold : Font.DemiBold }
            Group {
                Row2 { label: qsTr("Estado"); value: SystemStatus.online ? qsTr("Conectado") : qsTr("Sin conexión") }
                Row2 { label: qsTr("Conexión"); value: SystemStatus.connection !== "" ? SystemStatus.connection : "—" }
                Row2 { label: qsTr("Tipo"); value: SystemStatus.wired ? qsTr("Ethernet") : (SystemStatus.hasWifi ? qsTr("Wi-Fi") : "—") }
                Row2 { visible: SystemStatus.hasWifi; label: qsTr("Intensidad de señal"); value: SystemStatus.signal >= 0 ? SystemStatus.signal + " %" : "—" }
            }
            Rectangle {
                visible: SystemStatus.hasWifi
                width: parent.width; height: 44; radius: 12; color: Theme.tileFill
                Label { x: 14; anchors.verticalCenter: parent.verticalCenter; text: qsTr("Wi-Fi") }
                Switch { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
                         on: SystemStatus.wifiEnabled; onToggled: (v) => SystemStatus.setWifi(v) }
            }
        }

        // 3 Energía
        Column {
            visible: win.page === 3; width: parent.width; spacing: 10
            Label { visible: !Theme.gg; text: qsTr("Energía"); font.pixelSize: Theme.gg ? 20 : 22; font.weight: Theme.gg ? Font.Bold : Font.DemiBold }
            Group {
                Row2 { label: qsTr("Fuente de alimentación"); value: SystemStatus.hasBattery ? qsTr("Batería") : qsTr("Corriente eléctrica") }
                Row2 { visible: SystemStatus.hasBattery; label: qsTr("Carga"); value: SystemStatus.batteryPercent + " %" }
                Row2 { visible: SystemStatus.hasBattery; label: qsTr("Estado"); value: SystemStatus.batteryCharging ? qsTr("Cargando") : qsTr("Descargando") }
                Row2 { visible: SystemStatus.hasBacklight; label: qsTr("Brillo de pantalla"); value: Math.round(SystemStatus.brightness * 100) + " %" }
            }
        }

        // 4 Usuarios
        Column {
            visible: win.page === 4; width: parent.width; spacing: 10
            Label { visible: !Theme.gg; text: qsTr("Usuarios"); font.pixelSize: Theme.gg ? 20 : 22; font.weight: Theme.gg ? Font.Bold : Font.DemiBold }
            Repeater {
                model: Users.users
                Rectangle {
                    width: parent.width; height: 56; radius: 12; color: Theme.tileFill
                    Rectangle { x: 12; anchors.verticalCenter: parent.verticalCenter; width: 36; height: 36; radius: 18; color: "#4A5F91"
                        Text { anchors.centerIn: parent; text: modelData.display.charAt(0).toUpperCase(); color: "white"; font.family: Theme.fontFamily; font.pixelSize: 17; font.weight: Font.DemiBold } }
                    Label { x: 60; y: 9; text: modelData.display }
                    Hint { x: 60; y: 31; text: modelData.name }
                }
            }
        }

        // 5 Acerca de
        Column {
            visible: win.page === 5; width: parent.width; spacing: 10
            Label { visible: !Theme.gg; text: qsTr("Acerca de BC OS"); font.pixelSize: Theme.gg ? 20 : 22; font.weight: Theme.gg ? Font.Bold : Font.DemiBold }
            // Como «Acerca de este Mac»: logo grande, nombre y versión del sistema
            Item {
                visible: Theme.gg; width: parent.width; height: 150
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 4; width: 96; height: 96; radius: 22
                            gradient: Gradient { GradientStop { position: 0; color: "#2B2F6E" } GradientStop { position: 1; color: "#0B1033" } }
                            Brand { anchors.centerIn: parent; logoHeight: 26 } }
                Label { anchors.horizontalCenter: parent.horizontalCenter; y: 110; text: Monitor.osName; font.pixelSize: 22; font.weight: Font.Bold }
            }
            Group {
                Row2 { label: qsTr("Sistema"); value: Monitor.osName + " (ARM64)" }
                Row2 { label: qsTr("Equipo"); value: Monitor.hostname }
                Row2 { label: qsTr("Kernel"); value: "Linux " + Monitor.kernel }
                Row2 { label: qsTr("Procesador"); value: Monitor.cpuModel + " · " + Monitor.cpuCount }
                Row2 { label: qsTr("Memoria"); value: Monitor.formatBytes(Monitor.memTotal) }
            }
            Hint { width: parent.width; text: qsTr("Creado por Borja Candel. LIGERO. POTENTE. FLUIDO.") }
        }
    }
}
