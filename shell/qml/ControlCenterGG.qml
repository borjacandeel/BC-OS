import QtQuick
import BCShell

// Control Center Golden Gate: módulos de vidrio (Wi-Fi, Bluetooth, Concentración, Mosaico, Pantalla, Sonido,
// Reproducción) conectados a los servicios reales; cada módulo de red se despliega en su subpanel.
Item {
    id: cc
    readonly property real s: Theme.s
    function px(v) { return Math.round(v * s) }
    // macOS 27: sin panel de fondo, módulos de vidrio sueltos (pastillas de 140×62, círculos de 62, sliders de 292×60)
    width: px(292) + (main ? 0 : px(24))
    height: col.height + (main ? px(2) : px(24))
    Binding { target: Quick; property: "active"; value: cc.visible }

    // Controles editables (como «Editar controles» de macOS): qué módulos se muestran, guardado en Ajustes
    readonly property var defaults: ["red", "accesos", "pantalla", "sonido", "musica"]
    readonly property var catalog: [
        { k: "red", t: qsTr("Red, Concentración y Mosaico"), i: "network-wireless-signal-excellent-symbolic" },
        { k: "accesos", t: qsTr("Aspecto, Captura, Bloquear, Portapapeles"), i: "camera-photo-symbolic" },
        { k: "pantalla", t: qsTr("Pantalla"), i: "display-brightness-symbolic" },
        { k: "sonido", t: qsTr("Sonido"), i: "audio-volume-high-symbolic" },
        { k: "musica", t: qsTr("En reproducción"), i: "media-playback-start-symbolic" },
        { k: "noche", t: qsTr("Turno de noche"), i: "weather-clear-night-symbolic" },
        { k: "calculadora", t: qsTr("Calculadora"), i: "view-grid-symbolic" },
        { k: "notas", t: qsTr("Nota rápida"), i: "document-edit-symbolic" },
        { k: "ajustes", t: qsTr("Ajustes del Sistema"), i: "preferences-system-symbolic" } ]
    readonly property var extras: ["noche", "calculadora", "notas", "ajustes"]
    readonly property var shownList: { try { const v = JSON.parse(Settings.ccModules || "null"); return Array.isArray(v) ? v : defaults } catch (e) { return defaults } }
    property bool editing: false
    onVisibleChanged: if (!visible) editing = false
    function has(k) { return shownList.indexOf(k) >= 0 }
    function toggleModule(k) { const v = shownList.slice(); const i = v.indexOf(k); if (i >= 0) v.splice(i, 1); else v.push(k); Settings.ccModules = JSON.stringify(v) }
    readonly property bool main: UiState.centerPanel === ""

    Glass { visible: !cc.main; anchors.fill: parent; radius: px(26); tintBoost: 0.30 }

    // ---- Piezas de macOS 27 ----
    component Badge: Rectangle {
        property string key
        visible: cc.editing && key !== ""
        x: -px(5); y: -px(5); width: px(20); height: width; radius: width / 2; color: Theme.dark ? "#5A5A5E" : "#8E8E93"; z: 5
        Rectangle { anchors.centerIn: parent; width: px(9); height: px(2); radius: 1; color: "white" }
        MouseArea { anchors.fill: parent; anchors.margins: -px(4); onClicked: cc.toggleModule(parent.key) }
    }
    // Pastilla: círculo con icono (activo: blanco con el icono en azul) + nombre y estado
    component Pill: Item {
        id: pl
        property string icon; property string label; property string status
        property bool on: false; property bool available: true; property string key: ""
        signal toggled(); signal expand()
        width: px(140); height: px(62); opacity: available ? 1 : 0.5
        rotation: cc.editing && key !== "" ? wob.r : 0
        Glass { anchors.fill: parent; radius: height / 2; tintBoost: 0.10; shadow: false }
        Rectangle { x: px(12); anchors.verticalCenter: parent.verticalCenter; width: px(38); height: width; radius: width / 2
                    color: pl.on ? "#FFFFFF" : Qt.rgba(1, 1, 1, Theme.dark ? 0.16 : 0.55)
                    Behavior on color { ColorAnimation { duration: Theme.d(Theme.durHover) } }
                    Icon { anchors.centerIn: parent; name: pl.icon; size: px(18); color: pl.on ? Theme.accent : Theme.label }
                    MouseArea { anchors.fill: parent; enabled: pl.available && !cc.editing; onClicked: pl.toggled() } }
        Column { x: px(58); anchors.verticalCenter: parent.verticalCenter; width: parent.width - px(64)
                 Text { text: pl.label; color: Theme.label; font.family: Theme.font; font.pixelSize: px(13); font.weight: Font.DemiBold; width: parent.width; elide: Text.ElideRight }
                 Text { visible: text !== ""; text: pl.status; color: Theme.labelSecondary; font.family: Theme.font; font.pixelSize: px(11); width: parent.width; elide: Text.ElideRight } }
        MouseArea { x: px(54); width: parent.width - px(54); height: parent.height; enabled: pl.available && !cc.editing; onClicked: pl.expand() }
        Badge { key: pl.key }
    }
    // Botón redondo de 62
    component Round: Item {
        id: rd
        property string icon; property bool on: false; property string key: ""; property string tip
        signal clicked()
        width: px(62); height: px(62)
        rotation: cc.editing && key !== "" ? wob.r : 0
        Glass { anchors.fill: parent; radius: width / 2; tintBoost: 0.10; shadow: false }
        Rectangle { anchors.fill: parent; radius: width / 2; color: rd.on ? Theme.accent : (rma.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent") }
        Icon { anchors.centerIn: parent; name: rd.icon; size: px(22); color: rd.on ? "white" : Theme.label }
        MouseArea { id: rma; anchors.fill: parent; hoverEnabled: true; enabled: !cc.editing; onClicked: rd.clicked() }
        Badge { key: rd.key }
    }
    // Deslizador en pastilla de 292×60 (título arriba, iconos a los lados)
    component SliderPill: Item {
        id: sp
        property string title; property string icon; property string iconMax; property real value: 0; property bool available: true; property string key: ""
        signal moved(real v)
        width: px(292); height: px(60); opacity: available ? 1 : 0.5
        rotation: cc.editing && key !== "" ? wob.r : 0
        Glass { anchors.fill: parent; radius: px(26); tintBoost: 0.10; shadow: false }
        Text { x: px(16); y: px(9); text: sp.title; color: Theme.label; font.family: Theme.font; font.pixelSize: px(13); font.weight: Font.DemiBold }
        Icon { x: px(14); y: px(33); name: sp.icon; size: px(15); color: Theme.label }
        Icon { anchors.right: parent.right; anchors.rightMargin: px(14); y: px(33); name: sp.iconMax || sp.icon; size: px(17); color: Theme.label }
        Item {
            x: px(38); y: px(36); width: parent.width - px(76); height: px(8)
            Rectangle { anchors.fill: parent; radius: height / 2; color: Qt.rgba(Theme.label.r, Theme.label.g, Theme.label.b, 0.18) }
            Rectangle { width: Math.max(height, sp.value * parent.width); height: parent.height; radius: height / 2; color: Theme.label }
            MouseArea { anchors.fill: parent; anchors.margins: -px(10); enabled: sp.available && !cc.editing
                        function upd(m) { sp.moved(Math.max(0, Math.min(1, (m.x - px(10)) / (width - px(20))))) }
                        onPressed: (m) => upd(m); onPositionChanged: (m) => { if (pressed) upd(m) } }
        }
        Badge { key: sp.key }
    }

    component Module: Item {
        id: mod
        default property alias content: inner.data
        property bool hot: false
        property string key: ""
        Rectangle { anchors.fill: parent; radius: px(18); color: Theme.fill; border.width: 1; border.color: Theme.separator }
        Item { id: inner; anchors.fill: parent; enabled: !cc.editing }
        // En edición: tiembla un poco y muestra «−» para quitarlo
        rotation: cc.editing && key !== "" ? wob.r : 0
        Rectangle {
            visible: cc.editing && mod.key !== ""
            x: -px(6); y: -px(6); width: px(20); height: width; radius: width / 2; color: Theme.dark ? "#5A5A5E" : "#8E8E93"
            Rectangle { anchors.centerIn: parent; width: px(9); height: px(2); radius: 1; color: "white" }
            MouseArea { anchors.fill: parent; anchors.margins: -px(4); onClicked: cc.toggleModule(mod.key) }
        }
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

    QtObject { id: wob; property real r: 0 }
    SequentialAnimation {
        running: cc.editing && !Theme.reduced; loops: Animation.Infinite
        onStopped: wob.r = 0
        NumberAnimation { target: wob; property: "r"; to: 0.6; duration: 110 }
        NumberAnimation { target: wob; property: "r"; to: -0.6; duration: 220 }
        NumberAnimation { target: wob; property: "r"; to: 0; duration: 110 }
    }
    Column {
        id: col
        x: cc.main ? 0 : px(12); y: cc.main ? 0 : px(12); width: px(292); spacing: px(14)

        // Filas 1-2: Wi-Fi y Bluetooth (izquierda) y En reproducción (derecha, 140×140)
        Row {
            visible: cc.main && (cc.has("red") || cc.has("musica")); spacing: px(12)
            Column {
                visible: cc.has("red"); spacing: px(14)
                Pill { key: "red"; icon: "network-wireless-signal-excellent-symbolic"; label: qsTr("Wi-Fi"); available: SystemStatus.hasWifi
                       on: SystemStatus.wifiEnabled; status: SystemStatus.online && !SystemStatus.wired ? SystemStatus.connection : (SystemStatus.wifiEnabled ? qsTr("Activado") : qsTr("Desactivado"))
                       onToggled: SystemStatus.setWifi(!SystemStatus.wifiEnabled); onExpand: { UiState.centerPanel = "wifi"; Quick.scanWifi() } }
                Pill { icon: "bluetooth-active-symbolic"; label: qsTr("Bluetooth"); available: SystemStatus.bluetoothAvailable
                       on: SystemStatus.bluetoothOn; status: SystemStatus.bluetoothOn ? qsTr("Activado") : qsTr("Desactivado")
                       onToggled: SystemStatus.setBluetooth(!SystemStatus.bluetoothOn); onExpand: { UiState.centerPanel = "bluetooth"; Quick.scanBluetooth() } }
            }
            Item {
                visible: cc.has("musica"); width: px(140); height: px(138)
                rotation: cc.editing ? wob.r : 0
                Glass { anchors.fill: parent; radius: px(30); tintBoost: 0.10; shadow: false }
                Rectangle { x: px(14); y: px(14); width: px(42); height: width; radius: px(9); color: Qt.rgba(1, 1, 1, 0.16)
                            Icon { anchors.centerIn: parent; name: "media-playback-start-symbolic"; size: px(16); color: Theme.labelSecondary } }
                Text { x: px(14); y: px(70); width: parent.width - px(28); elide: Text.ElideRight
                       text: Quick.media.available ? Quick.media.title : qsTr("Sin reproducción"); color: Theme.label
                       font.family: Theme.font; font.pixelSize: px(13); font.weight: Font.DemiBold }
                Row {
                    x: px(18); y: px(100); spacing: px(18); opacity: Quick.media.available ? 1 : 0.45
                    Repeater {
                        model: [ { i: "media-skip-backward-symbolic", c: "previous" },
                                 { i: Quick.media.playing ? "media-playback-pause-symbolic" : "media-playback-start-symbolic", c: "play-pause" },
                                 { i: "media-skip-forward-symbolic", c: "next" } ]
                        Icon { required property var modelData; name: modelData.i; size: px(20); color: Theme.label
                               MouseArea { anchors.fill: parent; anchors.margins: -px(4); enabled: Quick.media.available && !cc.editing; onClicked: Quick.mediaCommand(modelData.c) } }
                    }
                }
                Badge { key: "musica" }
            }
        }
        // Fila 3: Red (pastilla) y Mosaico + Portapapeles (círculos)
        Row {
            visible: cc.main && cc.has("red"); spacing: px(12)
            Pill { icon: "network-wired-symbolic"; label: qsTr("Red"); on: SystemStatus.online
                   status: SystemStatus.online ? (SystemStatus.wired ? qsTr("Ethernet") : SystemStatus.connection) : qsTr("Sin conexión")
                   onToggled: Launcher.run("bc-shell", ["--app", "settings", "--open", "red"]); onExpand: toggled() }
            Round { icon: "view-grid-symbolic"; on: Sway.tiling; onClicked: Sway.toggleTiling() }
            Round { icon: "edit-paste-symbolic"; onClicked: UiState.toggleClipboard() }
        }
        // Fila 4: Aspecto y Captura (círculos) y Concentración (pastilla)
        Row {
            visible: cc.main && cc.has("accesos"); spacing: px(12)
            Round { key: "accesos"; icon: Theme.dark ? "weather-clear-symbolic" : "weather-clear-night-symbolic"
                    onClicked: Settings.appearance = Theme.dark ? "light" : "dark" }
            Round { icon: "camera-photo-symbolic"; onClicked: { UiState.closePopups(); Launcher.run("bc-screenshot", []) } }
            Pill { icon: "weather-clear-night-fill-symbolic"; label: qsTr("Concentración")
                   on: UiState.mode === "focus" || SystemStatus.dnd; status: on ? qsTr("Activado") : ""
                   onToggled: Settings.mode = (UiState.mode === "focus" ? "" : "focus"); onExpand: UiState.centerPanel = "focus" }
        }
        SliderPill { visible: cc.main && cc.has("pantalla"); key: "pantalla"; title: qsTr("Pantalla"); icon: "display-brightness-symbolic"
                     available: SystemStatus.hasBacklight; value: SystemStatus.brightness; onMoved: (v) => SystemStatus.setBrightness(Math.max(0.05, v)) }
        SliderPill { visible: cc.main && cc.has("sonido"); key: "sonido"; title: qsTr("Sonido"); icon: "audio-volume-low-symbolic"; iconMax: "audio-volume-high-symbolic"
                     available: SystemStatus.audioAvailable; value: SystemStatus.muted ? 0 : SystemStatus.volume; onMoved: (v) => SystemStatus.setVolume(v) }
        // Controles añadidos: círculos
        Flow {
            visible: cc.main && cc.extras.some(k => cc.has(k)); width: parent.width; spacing: px(12)
            Repeater {
                model: cc.catalog.filter(m => cc.extras.indexOf(m.k) >= 0 && cc.has(m.k))
                Round { required property var modelData; key: modelData.k; icon: modelData.i
                        on: modelData.k === "noche" && UiState.mode === "night"
                        onClicked: {
                            const k = modelData.k
                            if (k === "noche") { Settings.mode = (UiState.mode === "night" ? "" : "night"); return }
                            UiState.closePopups()
                            if (k === "calculadora") Launcher.run("bc-shell", ["--app", "calculator"])
                            else if (k === "notas") Launcher.run("bc-shell", ["--app", "notes"])
                            else Launcher.run("bc-shell", ["--app", "settings"]) } }
            }
        }
        // Edición: controles para añadir
        Item {
            visible: cc.main && cc.editing
            width: parent.width; height: addCol.height + px(12)
            Glass { anchors.fill: parent; radius: px(22); tintBoost: 0.18; shadow: false }
            Column {
                id: addCol; x: px(6); y: px(6); width: parent.width - px(12)
                Text { padding: px(6); text: qsTr("Añadir controles"); color: Theme.labelSecondary; font.family: Theme.font; font.pixelSize: px(11); font.weight: Font.Bold }
                Text { visible: cc.catalog.every(m => cc.has(m.k)); padding: px(6); text: qsTr("Ya están todos"); color: Theme.labelTertiary; font.family: Theme.font; font.pixelSize: px(12) }
                Repeater {
                    model: cc.catalog.filter(m => !cc.has(m.k))
                    delegate: Rectangle {
                        required property var modelData
                        width: addCol.width; height: px(34); radius: px(8); color: ama.containsMouse ? Theme.fillHover : "transparent"
                        Icon { x: px(8); anchors.verticalCenter: parent.verticalCenter; name: modelData.i; size: px(15); color: Theme.label }
                        Text { x: px(32); anchors.verticalCenter: parent.verticalCenter; width: parent.width - px(70); elide: Text.ElideRight
                               text: modelData.t; color: Theme.label; font.family: Theme.font; font.pixelSize: px(13) }
                        Rectangle { anchors.right: parent.right; anchors.rightMargin: px(8); anchors.verticalCenter: parent.verticalCenter
                                    width: px(20); height: width; radius: width / 2; color: "#30D158"
                                    Text { anchors.centerIn: parent; text: "+"; color: "white"; font.pixelSize: px(15); font.weight: Font.Bold } }
                        MouseArea { id: ama; anchors.fill: parent; hoverEnabled: true; onClicked: cc.toggleModule(modelData.k) }
                    }
                }
            }
        }
        // «Editar controles» (pastilla centrada, como en macOS 27)
        Item {
            visible: cc.main
            width: parent.width; height: px(26)
            Rectangle {
                anchors.centerIn: parent; height: px(24); width: editTxt.implicitWidth + px(22); radius: height / 2
                color: cc.editing ? Theme.accent : Qt.rgba(1, 1, 1, ema.containsMouse ? 0.42 : 0.30)
                Text { id: editTxt; anchors.centerIn: parent; text: cc.editing ? qsTr("Listo") : qsTr("Editar controles")
                       color: "white"; font.family: Theme.font; font.pixelSize: px(12); font.weight: Font.DemiBold }
                MouseArea { id: ema; anchors.fill: parent; hoverEnabled: true; onClicked: cc.editing = !cc.editing }
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
