import QtQuick
import BCShell

// Control Center Golden Gate: módulos de vidrio (Wi-Fi, Bluetooth, Concentración, Mosaico, Pantalla, Sonido,
// Reproducción) conectados a los servicios reales; cada módulo de red se despliega en su subpanel.
Item {
    id: cc
    readonly property real s: Theme.s
    function px(v) { return Math.round(v * s) }
    width: px(320)
    height: col.height + px(24)
    Binding { target: Quick; property: "active"; value: cc.visible }

    Glass { anchors.fill: parent; radius: px(26); tintBoost: 0.30 }

    component Module: Item {
        id: mod
        default property alias content: inner.data
        property bool hot: false
        Rectangle { anchors.fill: parent; radius: px(18); color: Theme.fill; border.width: 1; border.color: Theme.separator }
        Item { id: inner; anchors.fill: parent }
    }
    component Toggle: Item {
        id: tg
        property string icon
        property string label
        property string status
        property bool on: false
        property bool available: true
        signal toggled()
        signal expand()
        height: px(44); width: parent ? parent.width : px(140)
        opacity: available ? 1 : 0.45
        Rectangle {
            id: dot; x: px(8); anchors.verticalCenter: parent.verticalCenter
            width: px(30); height: width; radius: width / 2; color: tg.on ? Theme.selection : Theme.fill
            Behavior on color { ColorAnimation { duration: Theme.d(Theme.durHover) } }
            Icon { anchors.centerIn: parent; name: tg.icon; size: px(16); color: tg.on ? "white" : Theme.label }
            MouseArea { anchors.fill: parent; enabled: tg.available; onClicked: tg.toggled() }
        }
        Column {
            id: txt
            anchors.left: dot.right; anchors.leftMargin: px(8); anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            Text { text: tg.label; color: Theme.label; font.family: Theme.font; font.pixelSize: px(13); font.weight: Font.DemiBold; width: parent.width; elide: Text.ElideRight }
            Text { visible: text !== ""; text: tg.status; color: Theme.labelSecondary; font.family: Theme.font; font.pixelSize: px(11); width: parent.width; elide: Text.ElideRight }
        }
        MouseArea { anchors.fill: txt; enabled: tg.available; onClicked: tg.expand() }
    }
    component Slider: Item {
        id: sl
        property string icon
        property string title
        property real value: 0
        property bool available: true
        signal moved(real v)
        height: px(62); width: parent.width
        opacity: available ? 1 : 0.45
        Text { x: px(14); y: px(8); text: sl.title; color: Theme.label; font.family: Theme.font; font.pixelSize: px(13); font.weight: Font.DemiBold }
        Rectangle {
            id: track; x: px(12); y: px(32); width: parent.width - px(24); height: px(22); radius: height / 2; color: Theme.fill; clip: false
            Rectangle { width: Math.max(height, sl.value * parent.width); height: parent.height; radius: parent.radius; color: Theme.label; opacity: 0.92 }
            Icon { x: px(5); anchors.verticalCenter: parent.verticalCenter; name: sl.icon; size: px(13); color: Theme.dark ? "#1C1C1E" : "white" }
            MouseArea {
                anchors.fill: parent; enabled: sl.available
                function upd(m) { sl.moved(Math.max(0, Math.min(1, m.x / width))) }
                onPressed: (m) => upd(m); onPositionChanged: (m) => { if (pressed) upd(m) }
            }
        }
    }

    Column {
        id: col
        x: px(12); y: px(12); width: parent.width - px(24); spacing: px(10)

        // Fila superior: red (izquierda) y Concentración + Mosaico (derecha)
        Row {
            spacing: px(10); width: parent.width
            visible: UiState.centerPanel === ""
            Module {
                width: (parent.width - px(10)) / 2; height: px(150)
                Column {
                    anchors.fill: parent; anchors.margins: px(4); spacing: 0
                    Toggle { icon: "network-wireless-signal-excellent-symbolic"; label: qsTr("Wi-Fi"); available: SystemStatus.hasWifi
                             on: SystemStatus.wifiEnabled; status: SystemStatus.online && !SystemStatus.wired ? SystemStatus.connection : (SystemStatus.wifiEnabled ? qsTr("Activado") : qsTr("Desactivado"))
                             onToggled: SystemStatus.setWifi(!SystemStatus.wifiEnabled); onExpand: { UiState.centerPanel = "wifi"; Quick.scanWifi() } }
                    Toggle { icon: "bluetooth-active-symbolic"; label: qsTr("Bluetooth"); available: SystemStatus.bluetoothAvailable
                             on: SystemStatus.bluetoothOn; status: SystemStatus.bluetoothOn ? qsTr("Activado") : qsTr("Desactivado")
                             onToggled: SystemStatus.setBluetooth(!SystemStatus.bluetoothOn); onExpand: { UiState.centerPanel = "bluetooth"; Quick.scanBluetooth() } }
                    Toggle { icon: "network-wired-symbolic"; label: qsTr("Red"); on: SystemStatus.online
                             status: SystemStatus.online ? (SystemStatus.wired ? qsTr("Ethernet") : SystemStatus.connection) : qsTr("Sin conexión")
                             onToggled: Launcher.run("bc-shell", ["--app", "settings", "--open", "red"]); onExpand: toggled() }
                }
            }
            Column {
                width: (parent.width - px(10)) / 2; spacing: px(10)
                Module {
                    width: parent.width; height: px(70)
                    Toggle { anchors.verticalCenter: parent.verticalCenter; x: px(4); width: parent.width - px(8)
                             icon: "weather-clear-night-fill-symbolic"; label: qsTr("Concentración")
                             on: UiState.mode === "focus" || SystemStatus.dnd; status: on ? qsTr("Activado") : ""
                             onToggled: Settings.mode = (UiState.mode === "focus" ? "" : "focus"); onExpand: UiState.centerPanel = "focus" }
                }
                Module {
                    width: parent.width; height: px(70)
                    Toggle { anchors.verticalCenter: parent.verticalCenter; x: px(4); width: parent.width - px(8)
                             icon: "view-grid-symbolic"; label: qsTr("Mosaico"); on: Sway.tiling; status: on ? qsTr("Ventanas en mosaico") : qsTr("Flotantes")
                             onToggled: Sway.toggleTiling(); onExpand: toggled() }
                }
            }
        }
        // Accesos rápidos: aspecto, captura, bloqueo, portapapeles
        Row {
            visible: UiState.centerPanel === ""
            spacing: px(10)
            Repeater {
                model: [ { i: Theme.dark ? "weather-clear-symbolic" : "weather-clear-night-symbolic", t: Theme.dark ? qsTr("Claro") : qsTr("Oscuro"), c: "appearance" },
                         { i: "camera-photo-symbolic", t: qsTr("Captura"), c: "shot" },
                         { i: "system-lock-screen-symbolic", t: qsTr("Bloquear"), c: "lock" },
                         { i: "edit-paste-symbolic", t: qsTr("Portapapeles"), c: "clip" } ]
                delegate: Module {
                    required property var modelData
                    width: (col.width - px(30)) / 4; height: px(70)
                    Icon { anchors.horizontalCenter: parent.horizontalCenter; y: px(14); name: modelData.i; size: px(20); color: Theme.label }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; y: px(44); text: modelData.t; color: Theme.label; font.family: Theme.font; font.pixelSize: px(10) }
                    MouseArea { anchors.fill: parent; onClicked: {
                        if (modelData.c === "appearance") Settings.appearance = Theme.dark ? "light" : "dark"
                        else if (modelData.c === "shot") { UiState.closePopups(); Launcher.run("bc-screenshot", []) }
                        else if (modelData.c === "lock") UiState.run("bc:lock")
                        else UiState.toggleClipboard() } }
                }
            }
        }
        Module {
            visible: UiState.centerPanel === ""
            width: parent.width; height: px(66)
            Slider { anchors.verticalCenter: parent.verticalCenter; title: qsTr("Pantalla"); icon: "display-brightness-symbolic"
                     available: SystemStatus.hasBacklight; value: SystemStatus.brightness; onMoved: (v) => SystemStatus.setBrightness(Math.max(0.05, v)) }
        }
        Module {
            visible: UiState.centerPanel === ""
            width: parent.width; height: px(66)
            Slider { anchors.verticalCenter: parent.verticalCenter; title: qsTr("Sonido"); icon: Icons.volumeIcon(SystemStatus.volume, SystemStatus.muted)
                     available: SystemStatus.audioAvailable; value: SystemStatus.muted ? 0 : SystemStatus.volume; onMoved: (v) => SystemStatus.setVolume(v) }
        }
        // Reproducción en curso
        Module {
            visible: UiState.centerPanel === ""
            width: parent.width; height: px(64)
            Column {
                x: px(14); anchors.verticalCenter: parent.verticalCenter; width: parent.width - px(120)
                Text { text: Quick.media.available ? Quick.media.title : qsTr("Sin reproducción"); color: Theme.label; font.family: Theme.font
                       font.pixelSize: px(13); font.weight: Font.DemiBold; width: parent.width; elide: Text.ElideRight }
                Text { text: Quick.media.available ? (Quick.media.artist || "") : qsTr("Abre música o un vídeo"); color: Theme.labelSecondary
                       font.family: Theme.font; font.pixelSize: px(11); width: parent.width; elide: Text.ElideRight }
            }
            Row {
                anchors.right: parent.right; anchors.rightMargin: px(12); anchors.verticalCenter: parent.verticalCenter; spacing: px(10)
                opacity: Quick.media.available ? 1 : 0.4
                Repeater {
                    model: [ { i: "media-skip-backward-symbolic", c: "previous" },
                             { i: Quick.media.playing ? "media-playback-pause-symbolic" : "media-playback-start-symbolic", c: "play-pause" },
                             { i: "media-skip-forward-symbolic", c: "next" } ]
                    Icon { required property var modelData; name: modelData.i; size: px(20); color: Theme.label
                           MouseArea { anchors.fill: parent; anchors.margins: -px(4); enabled: Quick.media.available; onClicked: Quick.mediaCommand(modelData.c) } }
                }
            }
        }

        // ---- Subpaneles ---------------------------------------------------------------------
        Item {
            visible: UiState.centerPanel !== ""
            width: parent.width; height: px(34)
            Text { anchors.verticalCenter: parent.verticalCenter; x: px(4); color: Theme.label; font.family: Theme.font; font.pixelSize: px(15); font.weight: Font.Bold
                   text: ({ wifi: qsTr("Wi-Fi"), bluetooth: qsTr("Bluetooth"), focus: qsTr("Concentración") })[UiState.centerPanel] || "" }
            Rectangle {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; width: px(26); height: width; radius: width / 2; color: Theme.fill
                Icon { anchors.centerIn: parent; name: "go-previous-symbolic"; size: px(14); color: Theme.label }
                MouseArea { anchors.fill: parent; onClicked: UiState.centerPanel = "" }
            }
        }
        Module {
            visible: UiState.centerPanel === "wifi"
            width: parent.width; height: Math.min(px(320), wifiCol.height + px(12))
            clip: true
            Column {
                id: wifiCol; x: px(6); y: px(6); width: parent.width - px(12)
                Text { visible: Quick.networks.length === 0; padding: px(10); color: Theme.labelSecondary; font.family: Theme.font; font.pixelSize: px(12)
                       text: Quick.busy ? qsTr("Buscando redes…") : qsTr("No se encontraron redes") }
                Repeater {
                    model: Quick.networks.slice(0, 9)
                    delegate: Rectangle {
                        required property var modelData
                        width: wifiCol.width; height: px(34); radius: px(8); color: wma.containsMouse ? Theme.fillHover : "transparent"
                        Icon { x: px(8); anchors.verticalCenter: parent.verticalCenter; size: px(15); color: modelData.active ? Theme.selection : Theme.label
                               name: Icons.networkIcon(true, false, SystemStatus.signalBars(modelData.signal)) }
                        Text { x: px(32); anchors.verticalCenter: parent.verticalCenter; text: modelData.ssid; color: Theme.label; font.family: Theme.font
                               font.pixelSize: px(13); font.weight: modelData.active ? Font.DemiBold : Font.Normal; width: parent.width - px(70); elide: Text.ElideRight }
                        Text { anchors.right: parent.right; anchors.rightMargin: px(10); anchors.verticalCenter: parent.verticalCenter
                               text: modelData.secure ? "🔒" : ""; font.pixelSize: px(11) }
                        MouseArea { id: wma; anchors.fill: parent; hoverEnabled: true
                                    onClicked: { if (modelData.active) return; if (modelData.secure) { pw.ssid = modelData.ssid; pw.visible = true; pwIn.forceActiveFocus() } else Quick.connectWifi(modelData.ssid) } }
                    }
                }
                Item {
                    id: pw; visible: false; property string ssid
                    width: wifiCol.width; height: px(40)
                    Rectangle { anchors.fill: parent; anchors.margins: px(4); radius: px(8); color: Theme.controlBg; border.width: 1; border.color: Theme.selection
                        TextInput { id: pwIn; anchors.fill: parent; anchors.leftMargin: px(10); verticalAlignment: TextInput.AlignVCenter; echoMode: TextInput.Password
                                    color: Theme.label; font.family: Theme.font; font.pixelSize: px(13)
                                    onAccepted: { Quick.connectWifi(pw.ssid, text); text = ""; pw.visible = false }
                                    Text { visible: !parent.text; anchors.verticalCenter: parent.verticalCenter; text: qsTr("Contraseña de «%1»").arg(pw.ssid); color: Theme.labelTertiary; font: parent.font } } }
                }
            }
        }
        Module {
            visible: UiState.centerPanel === "bluetooth"
            width: parent.width; height: Math.min(px(320), btCol.height + px(12))
            clip: true
            Column {
                id: btCol; x: px(6); y: px(6); width: parent.width - px(12)
                Text { visible: Quick.btDevices.length === 0; padding: px(10); color: Theme.labelSecondary; font.family: Theme.font; font.pixelSize: px(12)
                       text: !SystemStatus.bluetoothAvailable ? qsTr("No hay adaptador Bluetooth") : (Quick.busy ? qsTr("Buscando dispositivos…") : qsTr("Sin dispositivos")) }
                Repeater {
                    model: Quick.btDevices.slice(0, 9)
                    delegate: Rectangle {
                        required property var modelData
                        width: btCol.width; height: px(34); radius: px(8); color: bma.containsMouse ? Theme.fillHover : "transparent"
                        Rectangle { x: px(6); anchors.verticalCenter: parent.verticalCenter; width: px(22); height: width; radius: width / 2
                                    color: modelData.connected ? Theme.selection : Theme.fill
                                    Icon { anchors.centerIn: parent; name: "bluetooth-active-symbolic"; size: px(12); color: modelData.connected ? "white" : Theme.label } }
                        Text { x: px(36); anchors.verticalCenter: parent.verticalCenter; text: modelData.name; color: Theme.label; font.family: Theme.font
                               font.pixelSize: px(13); width: parent.width - px(46); elide: Text.ElideRight }
                        MouseArea { id: bma; anchors.fill: parent; hoverEnabled: true; onClicked: Quick.toggleBluetoothDevice(modelData.mac, !modelData.connected) }
                    }
                }
            }
        }
        Module {
            visible: UiState.centerPanel === "focus"
            width: parent.width; height: focusCol.height + px(12)
            Column {
                id: focusCol; x: px(6); y: px(6); width: parent.width - px(12)
                Repeater {
                    model: [ { m: "focus", t: qsTr("No molestar"), i: "weather-clear-night-fill-symbolic" }, { m: "relax", t: qsTr("Relajación"), i: "weather-clear-symbolic" },
                             { m: "night", t: qsTr("Noche"), i: "weather-clear-night-symbolic" } ]
                    delegate: Rectangle {
                        required property var modelData
                        width: focusCol.width; height: px(38); radius: px(8); color: fma.containsMouse ? Theme.fillHover : "transparent"
                        Rectangle { x: px(6); anchors.verticalCenter: parent.verticalCenter; width: px(26); height: width; radius: width / 2
                                    color: UiState.mode === modelData.m ? Theme.selection : Theme.fill
                                    Icon { anchors.centerIn: parent; name: modelData.i; size: px(14); color: UiState.mode === modelData.m ? "white" : Theme.label } }
                        Text { x: px(42); anchors.verticalCenter: parent.verticalCenter; text: modelData.t; color: Theme.label; font.family: Theme.font; font.pixelSize: px(13) }
                        MouseArea { id: fma; anchors.fill: parent; hoverEnabled: true; onClicked: Settings.mode = (UiState.mode === modelData.m ? "" : modelData.m) }
                    }
                }
            }
        }
    }
}
