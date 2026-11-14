import QtQuick
import BCShell

// Configuración: Apariencia, Sonido, Red, Energía, Usuarios y Acerca de (datos reales).
AppWindow {
    id: win
    width: 780
    height: 520
    title: qsTr("Configuración")
    property int page: 0
    Component.onCompleted: Monitor.active = Qt.binding(() => win.visible && win.page === 5)

    readonly property var pages: [
        { name: qsTr("Apariencia"), icon: "preferences-system-symbolic" },
        { name: qsTr("Sonido"), icon: "audio-volume-high-symbolic" },
        { name: qsTr("Red"), icon: "network-wireless-signal-excellent-symbolic" },
        { name: qsTr("Energía"), icon: "preferences-system-power-symbolic" },
        { name: qsTr("Usuarios"), icon: "system-users-symbolic" },
        { name: qsTr("Acerca de"), icon: "dialog-information-symbolic" }
    ]

    component Label: Text {
        color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 15
    }
    component Hint: Text {
        color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 13; wrapMode: Text.WordWrap
    }
    component Row2: Rectangle {
        property string label
        property string value
        width: parent.width; height: 44; radius: 12; color: Theme.tileFill
        Label { x: 14; anchors.verticalCenter: parent.verticalCenter; text: parent.label }
        Label { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
                text: parent.value; color: Theme.textSecondary }
    }
    component Switch: Rectangle {
        id: sw
        property bool on: false
        signal toggled(bool v)
        width: 46; height: 28; radius: 14
        color: on ? "#34C759" : Qt.rgba(1, 1, 1, 0.22)
        Behavior on color { ColorAnimation { duration: Theme.dur(160) } }
        Rectangle { y: 2; x: sw.on ? 20 : 2; width: 24; height: 24; radius: 12; color: "white"
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
                color: index === parent.current ? Theme.accent : Qt.rgba(1, 1, 1, 0.1)
                opacity: modelData.enabled === false ? 0.45 : 1
                Text { anchors.centerIn: parent; text: modelData.label; color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 14 }
                MouseArea { anchors.fill: parent; enabled: modelData.enabled !== false; onClicked: parent.parent.picked(index) }
            }
        }
    }

    // Barra lateral
    Rectangle {
        id: side
        width: 200; height: parent.height
        color: Qt.rgba(0.03, 0.06, 0.16, 0.45)
        Column {
            x: 10; y: 12; width: parent.width - 20; spacing: 3
            Repeater {
                model: win.pages
                Rectangle {
                    width: parent.width; height: 38; radius: 9
                    color: index === win.page ? Theme.accentSelected : (ma.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                    Icon { x: 12; anchors.verticalCenter: parent.verticalCenter; name: modelData.icon; size: 20 }
                    Label { x: 44; anchors.verticalCenter: parent.verticalCenter; text: modelData.name }
                    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: win.page = index }
                }
            }
        }
    }

    Item {
        x: 224; y: 22; width: parent.width - 224 - 24; height: parent.height - 22 - 12

        // 0 Apariencia
        Column {
            visible: win.page === 0; width: parent.width; spacing: 12
            Label { text: qsTr("Apariencia"); font.pixelSize: 22; font.weight: Font.DemiBold }
            Row2 { label: qsTr("Widgets en el escritorio"); value: ""
                   Switch { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                            on: Settings.widgets; onToggled: (v) => Settings.widgets = v } }
            Rectangle { width: 260; height: 40; radius: 12; color: Theme.accent
                        Text { anchors.centerIn: parent; text: qsTr("Abrir el asistente de bienvenida"); color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 14 }
                        MouseArea { anchors.fill: parent; onClicked: Launcher.run("bc-ctl", ["welcome"]) } }
            Label { text: qsTr("Estilo de escritorio") }
            Row {
                spacing: 12
                Repeater {
                    model: [{ id: "mac", name: qsTr("BC"), desc: qsTr("Barra superior y Dock") },
                            { id: "win", name: qsTr("Windows"), desc: qsTr("Barra de tareas y menú Inicio") },
                            { id: "minimal", name: qsTr("Minimal"), desc: qsTr("Solo la barra superior") }]
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
            Label { text: qsTr("Sonido"); font.pixelSize: 22; font.weight: Font.DemiBold }
            Hint { visible: !SystemStatus.audioAvailable; width: parent.width
                   text: qsTr("No se detecta ningún dispositivo de audio (PipeWire).") }
            Rectangle {
                visible: SystemStatus.audioAvailable
                width: parent.width; height: 92; radius: 12; color: Theme.tileFill
                Label { x: 14; y: 10; text: qsTr("Volumen de salida") + "  " + Math.round(SystemStatus.volume * 100) + " %" }
                Rectangle { id: vt; x: 14; y: 56; width: parent.width - 120; height: 6; radius: 3; color: Qt.rgba(1, 1, 1, 0.16)
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
            Label { text: qsTr("Red"); font.pixelSize: 22; font.weight: Font.DemiBold }
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
            Label { text: qsTr("Energía"); font.pixelSize: 22; font.weight: Font.DemiBold }
            Row2 { label: qsTr("Fuente de alimentación"); value: SystemStatus.hasBattery ? qsTr("Batería") : qsTr("Corriente eléctrica") }
            Row2 { visible: SystemStatus.hasBattery; label: qsTr("Carga"); value: SystemStatus.batteryPercent + " %" }
            Row2 { visible: SystemStatus.hasBattery; label: qsTr("Estado"); value: SystemStatus.batteryCharging ? qsTr("Cargando") : qsTr("Descargando") }
            Row2 { visible: SystemStatus.hasBacklight; label: qsTr("Brillo de pantalla"); value: Math.round(SystemStatus.brightness * 100) + " %" }
        }

        // 4 Usuarios
        Column {
            visible: win.page === 4; width: parent.width; spacing: 10
            Label { text: qsTr("Usuarios"); font.pixelSize: 22; font.weight: Font.DemiBold }
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
            Label { text: qsTr("Acerca de BC OS"); font.pixelSize: 22; font.weight: Font.DemiBold }
            Row2 { label: qsTr("Sistema"); value: Monitor.osName + " (ARM64)" }
            Row2 { label: qsTr("Equipo"); value: Monitor.hostname }
            Row2 { label: qsTr("Kernel"); value: "Linux " + Monitor.kernel }
            Row2 { label: qsTr("Procesador"); value: Monitor.cpuModel + " · " + Monitor.cpuCount }
            Row2 { label: qsTr("Memoria"); value: Monitor.formatBytes(Monitor.memTotal) }
            Hint { width: parent.width; text: qsTr("Creado por Borja Candel. LIGERO. POTENTE. FLUIDO.") }
        }
    }
}
