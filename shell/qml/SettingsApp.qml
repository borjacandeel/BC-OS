import QtQuick
import BCShell

// Configuración: Apariencia, Sonido, Red, Energía, Usuarios y Acerca de (datos reales).
AppWindow {
    id: win
    width: 860
    height: 580
    title: qsTr("Ajustes del Sistema")
    property int page: AppConfig.classic ? 0 : 6
    Component.onCompleted: Monitor.active = Qt.binding(() => win.visible && win.page === 5)

    // Golden Gate: barra lateral de borde a borde con iconos en color (cuadrado redondeado + glifo blanco)
    readonly property var pages: [
        { idx: 2, name: qsTr("Red"), icon: "network-wireless-signal-excellent-symbolic", c: "#0A84FF" },
        { idx: 1, name: qsTr("Sonido"), icon: "audio-volume-high-symbolic", c: "#FF375F" },
        { idx: 9, name: qsTr("Notificaciones"), icon: "notification-symbolic", c: "#FF453A" },
        { idx: 3, name: qsTr("Batería y energía"), icon: "preferences-system-power-symbolic", c: "#30D158" },
        { sep: true },
        { idx: 6, name: qsTr("Aspecto"), icon: "weather-clear-night-fill-symbolic", c: "#1C1C1E" },
        { idx: 7, name: qsTr("Escritorio y Dock"), icon: "view-app-grid-symbolic", c: "#1C1C1E" },
        { idx: 8, name: qsTr("Fondo de pantalla"), icon: "image-x-generic", c: "#32ADE6" },
        { idx: 0, name: qsTr("General"), icon: "preferences-system-symbolic", c: "#8E8E93" },
        { sep: true },
        { idx: 4, name: qsTr("Usuarios"), icon: "system-users-symbolic", c: "#8E8E93" },
        { idx: 5, name: qsTr("Acerca de"), icon: "dialog-information-symbolic", c: "#8E8E93" }
    ]
    property string query: ""

    component Label: Text {
        color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: Theme.gg ? 13 : 15
    }
    component Hint: Text {
        color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.gg ? 12 : 13; wrapMode: Text.WordWrap
    }
    component Row2: Rectangle {
        property string label
        property string value
        width: parent.width; height: Theme.gg ? 38 : 44; radius: Theme.gg ? 10 : 12; color: Theme.tileFill
        Label { x: 14; anchors.verticalCenter: parent.verticalCenter; text: parent.label }
        Label { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
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
        color: Theme.gg ? (win.active ? Theme.sidebarBgActive : Theme.sidebarBg) : Qt.rgba(0.03, 0.06, 0.16, 0.45)
        Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.hairline }
        // Búsqueda
        Rectangle {
            x: 12; y: 8; width: parent.width - 24; height: 28; radius: 8; color: Theme.tileFill
            Icon { x: 8; anchors.verticalCenter: parent.verticalCenter; name: Icons.search; size: 14; color: Theme.textSecondary }
            TextInput { id: q; x: 28; width: parent.width - 36; anchors.verticalCenter: parent.verticalCenter; color: Theme.textPrimary
                        font.family: Theme.fontFamily; font.pixelSize: 13; onTextChanged: win.query = text.toLowerCase()
                        Text { visible: !parent.text; text: qsTr("Buscar"); color: Theme.textSecondary; font: parent.font } }
        }
        Column {
            x: 10; y: 46; width: parent.width - 20; spacing: 1
            Repeater {
                model: win.pages
                Item {
                    required property var modelData
                    width: parent.width
                    visible: modelData.sep ? win.query === "" : (win.query === "" || modelData.name.toLowerCase().indexOf(win.query) >= 0)
                    height: !visible ? 0 : (modelData.sep ? 14 : 30)
                    Rectangle { visible: !!modelData.sep; anchors.centerIn: parent; width: parent.width - 16; height: 1; color: Theme.hairline }
                    Rectangle {
                        visible: !modelData.sep
                        anchors.fill: parent; radius: 7
                        color: modelData.idx === win.page ? (win.active || !Theme.gg ? Theme.accent : Theme.tileFill) : (ma.containsMouse ? Theme.tileFill : "transparent")
                        // Golden Gate: iconos en color solo en la ventana activa
                        Rectangle { x: 6; anchors.verticalCenter: parent.verticalCenter; width: 20; height: 20; radius: 5
                                    color: win.active || !Theme.gg ? (modelData.c || "#8E8E93") : Qt.rgba(0.5, 0.5, 0.55, 0.6)
                                    Icon { anchors.centerIn: parent; name: modelData.icon || ""; size: 13; color: "white" } }
                        Label { x: 34; anchors.verticalCenter: parent.verticalCenter; text: modelData.name || ""; font.pixelSize: 13
                                color: modelData.idx === win.page && (win.active || !Theme.gg) ? "white" : Theme.textPrimary }
                        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: win.page = modelData.idx }
                    }
                }
            }
        }
    }

    Flickable {
        x: 254; y: 18; width: parent.width - 254 - 24; height: parent.height - 18 - 12
        contentHeight: Math.max(height, pageCol6.visible ? pageCol6.height : (pageCol7.visible ? pageCol7.height : height))
        clip: true

        // 6 Aspecto (Golden Gate)
        Column {
            id: pageCol6
            visible: win.page === 6; width: parent.width; spacing: 14
            Label { text: qsTr("Aspecto"); font.pixelSize: 20; font.weight: Font.Bold }
            Row {
                spacing: 18
                Repeater {
                    model: [ { v: "auto", t: qsTr("Automático") }, { v: "light", t: qsTr("Claro") }, { v: "dark", t: qsTr("Oscuro") } ]
                    Column {
                        required property var modelData
                        spacing: 6
                        Rectangle {
                            width: 120; height: 78; radius: 10; clip: true
                            border.width: Settings.appearance === modelData.v ? 3 : 1
                            border.color: Settings.appearance === modelData.v ? Theme.accent : Theme.hairline
                            color: modelData.v === "light" ? "#E9E9EE" : (modelData.v === "dark" ? "#1E1E22" : "#8E8E93")
                            Rectangle { x: 10; y: 10; width: 70; height: 46; radius: 6; color: modelData.v === "dark" ? "#2C2C31" : "#FFFFFF"
                                        Row { x: 6; y: 6; spacing: 3; Repeater { model: [Theme.close, Theme.minimize, Theme.zoom]; Rectangle { required property color modelData; width: 6; height: 6; radius: 3; color: modelData } } } }
                            Rectangle { visible: modelData.v === "auto"; x: 60; width: 60; height: 78; color: "#1E1E22" }
                            MouseArea { anchors.fill: parent; onClicked: Settings.appearance = modelData.v }
                        }
                        Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.t; font.pixelSize: 13 }
                    }
                }
            }
            Label { text: qsTr("Liquid Glass"); font.weight: Font.DemiBold }
            Hint { width: parent.width; text: qsTr("De ultratransparente a totalmente tintado: afecta a la barra, el Dock, los widgets, los menús y los paneles.") }
            Item {
                width: parent.width; height: 34
                Label { anchors.verticalCenter: parent.verticalCenter; text: qsTr("Transparente"); font.pixelSize: 12; color: Theme.textSecondary }
                Rectangle {
                    id: gtrack; x: 96; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 96 - 80; height: 6; radius: 3; color: Theme.tileFill
                    Rectangle { width: Settings.glassTint * parent.width; height: parent.height; radius: 3; color: Theme.accent }
                    Rectangle { x: Settings.glassTint * parent.width - 10; anchors.verticalCenter: parent.verticalCenter; width: 20; height: 20; radius: 10; color: "white"
                                border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.2) }
                    MouseArea { anchors.fill: parent; anchors.margins: -10
                                function upd(m) { Settings.glassTint = Math.max(0, Math.min(1, (m.x - 10) / gtrack.width)) }
                                onPressed: (m) => upd(m); onPositionChanged: (m) => { if (pressed) upd(m) } }
                }
                Label { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: qsTr("Tintado"); font.pixelSize: 12; color: Theme.textSecondary }
            }
            Label { text: qsTr("Color de resalte"); font.weight: Font.DemiBold }
            Row {
                spacing: 10
                Repeater {
                    model: ["#0A84FF", "#BF5AF2", "#FF375F", "#FF453A", "#FF9F0A", "#FFD60A", "#30D158", "#8E8E93"]
                    Rectangle { required property string modelData; width: 22; height: 22; radius: 11; color: modelData
                                border.width: Settings.accent.toUpperCase() === modelData ? 3 : 0; border.color: Theme.textPrimary
                                MouseArea { anchors.fill: parent; onClicked: Settings.accent = modelData } }
                }
            }
            Row2 { label: qsTr("Reducir movimiento"); value: ""
                   Switch { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                            on: Settings.reducedMotion; onToggled: (v) => Settings.reducedMotion = v } }
            Row2 { label: qsTr("Sonidos de la interfaz"); value: ""
                   Switch { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                            on: Settings.sounds; onToggled: (v) => Settings.sounds = v } }
        }

        // 7 Escritorio y Dock
        Column {
            id: pageCol7
            visible: win.page === 7; width: parent.width; spacing: 12
            Label { text: qsTr("Escritorio y Dock"); font.pixelSize: 20; font.weight: Font.Bold }
            Item {
                width: parent.width; height: 44
                Label { anchors.verticalCenter: parent.verticalCenter; text: qsTr("Tamaño") }
                Rectangle {
                    id: dtrack; x: 160; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 180; height: 6; radius: 3; color: Theme.tileFill
                    readonly property real f: (Settings.dockSize - 32) / 64
                    Rectangle { width: dtrack.f * parent.width; height: parent.height; radius: 3; color: Theme.accent }
                    Rectangle { x: dtrack.f * parent.width - 10; anchors.verticalCenter: parent.verticalCenter; width: 20; height: 20; radius: 10; color: "white"; border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.2) }
                    MouseArea { anchors.fill: parent; anchors.margins: -10
                                function upd(m) { Settings.dockSize = Math.round(32 + 64 * Math.max(0, Math.min(1, (m.x - 10) / dtrack.width))) }
                                onPressed: (m) => upd(m); onPositionChanged: (m) => { if (pressed) upd(m) } }
                }
            }
            Row2 { label: qsTr("Ampliación"); value: ""
                   Switch { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                            on: Settings.dockMagnify; onToggled: (v) => Settings.dockMagnify = v } }
            Row2 { label: qsTr("Ocultar y mostrar el Dock automáticamente"); value: ""
                   Switch { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                            on: Settings.dockAutohide; onToggled: (v) => Settings.dockAutohide = v } }
            Row2 { label: qsTr("Mostrar apps recientes en el Dock"); value: ""
                   Switch { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                            on: Settings.dockShowRecent; onToggled: (v) => Settings.dockShowRecent = v } }
            Row2 { label: qsTr("Restablecer las apps del Dock"); value: ""
                   Rectangle { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; width: 110; height: 26; radius: 7; color: Theme.tileFill
                               Text { anchors.centerIn: parent; text: qsTr("Restablecer"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                               MouseArea { anchors.fill: parent; onClicked: Settings.dockApps = [] } } }
            Label { text: qsTr("Widgets"); font.weight: Font.DemiBold }
            Row2 { label: qsTr("Mostrar widgets en el escritorio"); value: ""
                   Switch { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                            on: Settings.widgets; onToggled: (v) => Settings.widgets = v } }
            Row2 { label: qsTr("Volver a colocar los widgets en su columna"); value: ""
                   Rectangle { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; width: 110; height: 26; radius: 7; color: Theme.tileFill
                               Text { anchors.centerIn: parent; text: qsTr("Colocar"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                               MouseArea { anchors.fill: parent; onClicked: Settings.widgetLayout = "{}" } } }
            Hint { width: parent.width; text: qsTr("Otras apps pueden añadir su widget dejando un archivo JSON en ~/.local/share/bc/widgets/.") }
            Label { text: qsTr("Mission Control"); font.weight: Font.DemiBold }
            Hint { width: parent.width; text: qsTr("Ctrl+↑ o F3, o desliza tres dedos hacia arriba. Ctrl+←/→ cambia de escritorio.") }
        }

        // 8 Fondo de pantalla
        Column {
            visible: win.page === 8; width: parent.width; spacing: 12
            Label { text: qsTr("Fondo de pantalla"); font.pixelSize: 20; font.weight: Font.Bold }
            Grid {
                columns: 3; spacing: 12
                Repeater {
                    model: ["ondas.jpg", "medianoche.jpg", "oceano.jpg", "montanas.jpg", "grafito.jpg", "plata.jpg"]
                    Rectangle {
                        required property string modelData
                        readonly property string path: "/usr/share/bc/wallpapers/" + modelData
                        width: 170; height: 96; radius: 10; clip: true; color: Theme.tileFill
                        border.width: (Settings.wallpaper === path || (Settings.wallpaper === "" && modelData === "ondas.jpg")) ? 3 : 0; border.color: Theme.accent
                        Image { anchors.fill: parent; anchors.margins: parent.border.width; source: win.page === 8 ? "file://" + parent.path : ""; sourceSize: Qt.size(340, 192); fillMode: Image.PreserveAspectCrop; asynchronous: true }
                        MouseArea { anchors.fill: parent; onClicked: Settings.wallpaper = (modelData === "ondas.jpg" ? "" : parent.path) }
                    }
                }
            }
        }

        // 9 Notificaciones
        Column {
            visible: win.page === 9; width: parent.width; spacing: 12
            Label { text: qsTr("Notificaciones"); font.pixelSize: 20; font.weight: Font.Bold }
            Row2 { label: qsTr("No molestar"); value: ""
                   Switch { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                            on: Settings.mode === "focus"; onToggled: (v) => Settings.mode = v ? "focus" : "" } }
            Hint { width: parent.width; text: qsTr("Con «No molestar» las notificaciones se guardan en el Centro de notificaciones sin mostrarse. Ábrelo pulsando la fecha y la hora.") }
        }

        // 0 Apariencia
        Column {
            visible: win.page === 0; width: parent.width; spacing: 12
            Label { text: qsTr("General"); font.pixelSize: Theme.gg ? 20 : 22; font.weight: Theme.gg ? Font.Bold : Font.DemiBold }
            Row2 { label: qsTr("Widgets en el escritorio"); value: ""
                   Switch { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                            on: Settings.widgets; onToggled: (v) => Settings.widgets = v } }
            Rectangle { width: 260; height: 40; radius: 12; color: Theme.accent
                        Text { anchors.centerIn: parent; text: qsTr("Abrir el asistente de bienvenida"); color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 14 }
                        MouseArea { anchors.fill: parent; onClicked: Launcher.run("bc-ctl", ["welcome"]) } }
            Label { text: qsTr("Entorno al iniciar sesión") }
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
            Label { text: qsTr("Estilo de escritorio") }
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
            Label { text: qsTr("Sonido"); font.pixelSize: Theme.gg ? 20 : 22; font.weight: Theme.gg ? Font.Bold : Font.DemiBold }
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
            Label { text: qsTr("Red"); font.pixelSize: Theme.gg ? 20 : 22; font.weight: Theme.gg ? Font.Bold : Font.DemiBold }
            Row2 { label: qsTr("Estado"); value: SystemStatus.online ? qsTr("Conectado") : qsTr("Sin conexión") }
            Row2 { label: qsTr("Conexión"); value: SystemStatus.connection !== "" ? SystemStatus.connection : "—" }
            Row2 { label: qsTr("Tipo"); value: SystemStatus.wired ? qsTr("Ethernet") : (SystemStatus.hasWifi ? qsTr("Wi-Fi") : "—") }
            Row2 { visible: SystemStatus.hasWifi; label: qsTr("Intensidad de señal"); value: SystemStatus.signal >= 0 ? SystemStatus.signal + " %" : "—" }
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
            Label { text: qsTr("Energía"); font.pixelSize: Theme.gg ? 20 : 22; font.weight: Theme.gg ? Font.Bold : Font.DemiBold }
            Row2 { label: qsTr("Fuente de alimentación"); value: SystemStatus.hasBattery ? qsTr("Batería") : qsTr("Corriente eléctrica") }
            Row2 { visible: SystemStatus.hasBattery; label: qsTr("Carga"); value: SystemStatus.batteryPercent + " %" }
            Row2 { visible: SystemStatus.hasBattery; label: qsTr("Estado"); value: SystemStatus.batteryCharging ? qsTr("Cargando") : qsTr("Descargando") }
            Row2 { visible: SystemStatus.hasBacklight; label: qsTr("Brillo de pantalla"); value: Math.round(SystemStatus.brightness * 100) + " %" }
        }

        // 4 Usuarios
        Column {
            visible: win.page === 4; width: parent.width; spacing: 10
            Label { text: qsTr("Usuarios"); font.pixelSize: Theme.gg ? 20 : 22; font.weight: Theme.gg ? Font.Bold : Font.DemiBold }
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
            Label { text: qsTr("Acerca de BC OS"); font.pixelSize: Theme.gg ? 20 : 22; font.weight: Theme.gg ? Font.Bold : Font.DemiBold }
            Row2 { label: qsTr("Sistema"); value: Monitor.osName + " (ARM64)" }
            Row2 { label: qsTr("Equipo"); value: Monitor.hostname }
            Row2 { label: qsTr("Kernel"); value: "Linux " + Monitor.kernel }
            Row2 { label: qsTr("Procesador"); value: Monitor.cpuModel + " · " + Monitor.cpuCount }
            Row2 { label: qsTr("Memoria"); value: Monitor.formatBytes(Monitor.memTotal) }
            Hint { width: parent.width; text: qsTr("Creado por Borja Candel. LIGERO. POTENTE. FLUIDO.") }
        }
    }
}
