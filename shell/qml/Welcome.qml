import QtQuick
import QtQuick.Shapes
import BCShell

// Asistente de bienvenida de BC OS (primer inicio y desde Configuración): estilo de escritorio,
// colores y fondo, y organización de ventanas. Todo se aplica al instante.
Item {
    id: root
    // Modo claro/oscuro: tinta del texto y velos (blancos en oscuro, negros en claro)
    readonly property color ink: Theme.lightUi ? "#1D1D1F" : Theme.white
    function wash(a) { return Theme.lightUi ? Qt.rgba(0, 0, 0, a * 0.7) : Qt.rgba(1, 1, 1, a) }
    property int step: 0
    readonly property int steps: 4
    signal finished()
    readonly property string wallDir: "/usr/share/bc/wallpapers/"
    readonly property var wallpapers: [
        { f: "bosque-niebla.jpg", n: qsTr("Bosque en la niebla") }, { f: "pinar-alba.jpg", n: qsTr("Pinar al alba") }, { f: "lago-claro.jpg", n: qsTr("Lago") },
        { f: "nieve.jpg", n: qsTr("Nieve") }, { f: "salvia.jpg", n: qsTr("Salvia") }, { f: "ondas.jpg", n: qsTr("Ondas") },
        { f: "bosque-noche.jpg", n: qsTr("Bosque de noche") }, { f: "aurora-boreal.jpg", n: qsTr("Aurora boreal") }, { f: "lago-noche.jpg", n: qsTr("Lago de noche") },
        { f: "bruma-verde.jpg", n: qsTr("Bruma verde") }, { f: "luna.jpg", n: qsTr("Luna") }, { f: "eclipse.jpg", n: qsTr("Eclipse") }]
    // Solo los colores base de BC OS (los del semáforo y los de las tarjetas del Monitor)
    readonly property var accents: [Theme.gg ? "#0A84FF" : "#2F7BF5", "#34C759", "#FF9F0A", "#FF5F57", "#8E9BB2"]

    property bool dotfilesChosen: Sessions.runningId === "dotfiles"
    function pickStyle(id) { Settings.desktopStyle = id; UiState.style = id; if (dotfilesChosen) { Sessions.remember(Sessions.currentUserName(), "bc"); dotfilesChosen = false } }
    function pickDotfiles() { if (Sessions.remember(Sessions.currentUserName(), "dotfiles")) dotfilesChosen = true }
    function pickWallpaper(f) { Settings.wallpaper = wallDir + f }
    function pickAccent(c) { Settings.accent = c; AppConfig.setAccent(c) }
    function pickTiling(on) { Sway.setTiling(on) }
    // Paso 0: máquina virtual o equipo físico (se preselecciona lo detectado)
    readonly property string detected: Quick.detectedMachine()
    property string machine: Quick.machineKind()
    function pickMachine(k) { machine = k; Quick.setMachineKind(k) }
    property string resolution: "auto"
    function next() { if (step < steps - 1) step++; else finish() }
    function finish() { Settings.welcomed = true; root.finished() }
    focus: true
    Keys.onEscapePressed: finish()
    Keys.onRightPressed: next()
    Keys.onLeftPressed: if (step > 0) step--
    Keys.onReturnPressed: next()

    Rectangle { anchors.fill: parent; color: Theme.lightUi ? Qt.rgba(0.95, 0.95, 0.97, 0.97) : Qt.rgba(0.02, 0.03, 0.07, 0.97) }
    MouseArea { anchors.fill: parent }   // no deja pasar clics

    component Chip: Rectangle {
        property string text
        property bool sel: false
        signal clicked()
        height: 34; width: chipT.implicitWidth + 32; radius: 17
        color: sel ? Theme.accent : root.wash(0.1)
        Text { id: chipT; anchors.centerIn: parent; text: parent.text; color: parent.sel ? "white" : root.ink; font.family: Theme.fontFamily; font.pixelSize: 14 }
        MouseArea { anchors.fill: parent; onClicked: parent.clicked() }
    }
    component Card: Rectangle {
        id: cardRoot
        property bool sel: false
        property string title
        property string badge
        property string desc
        default property alias preview: pv.data
        signal clicked()
        width: 230; height: 270; radius: 16
        color: root.wash(sel ? 0.12 : 0.06)
        border.width: sel ? 2 : 1; border.color: sel ? Theme.accent : Theme.hairline
        Behavior on color { ColorAnimation { duration: Theme.dur(120) } }
        scale: hov.containsMouse ? 1.025 : 1
        Behavior on scale { NumberAnimation { duration: Theme.dur(140); easing.type: Easing.OutCubic } }
        HoverHandler { id: hov }
        Item { id: pv; x: 10; y: 10; width: parent.width - 20; height: 140; clip: true }
        Rectangle { visible: cardRoot.sel; x: parent.width - 36; y: 18; width: 22; height: 22; radius: 11; color: Theme.accent
                    Text { anchors.centerIn: parent; text: "✓"; color: Theme.white; font.pixelSize: 13 } }
        Row { x: 16; y: 162; spacing: 8
              Text { text: cardRoot.title; color: root.ink; font.family: Theme.fontFamily; font.pixelSize: 17; font.weight: Font.DemiBold }
              Rectangle { visible: cardRoot.badge !== ""; anchors.verticalCenter: parent.verticalCenter; width: bT.implicitWidth + 12; height: 18; radius: 9
                          color: root.wash(0.14)
                          Text { id: bT; anchors.centerIn: parent; text: cardRoot.badge; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 } } }
        Text { x: 16; y: 192; width: parent.width - 32; text: cardRoot.desc; wrapMode: Text.WordWrap
               color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 13 }
        MouseArea { anchors.fill: parent; onClicked: cardRoot.clicked() }
    }
    // Maqueta de pantalla para las vistas previas
    component Mock: Rectangle {
        property string kind: "mac"     // mac | win | minimal | float | tile
        anchors.fill: parent; radius: 10
        gradient: Gradient { GradientStop { position: 0; color: "#1B2740" } GradientStop { position: 1; color: "#0A1020" } }
        clip: true
        // Golden Gate: fondo Ondas real, barra transparente y columna de widgets de vidrio
        Image { visible: Theme.gg && kind === "mac"; anchors.fill: parent; source: "qrc:/BCShell/assets/wallpaper-default.png"; fillMode: Image.PreserveAspectCrop; sourceSize.width: 400 }
        Column { visible: Theme.gg && kind === "mac"; x: 5; y: 12; spacing: 3
                 Repeater { model: [36, 18, 36]; Rectangle { required property int modelData; width: 38; height: modelData; radius: 5; color: Qt.rgba(0.04, 0.05, 0.13, 0.6); border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.18) } } }
        Rectangle { visible: (kind === "mac" && !Theme.gg) || kind === "minimal" || kind === "float" || kind === "tile"; width: parent.width; height: 8; color: Qt.rgba(1, 1, 1, 0.18) }
        Rectangle { visible: kind === "win"; anchors.bottom: parent.bottom; width: parent.width; height: 10; color: Qt.rgba(1, 1, 1, 0.2)
                    Row { anchors.centerIn: parent; spacing: 4; Repeater { model: 5; Rectangle { width: 6; height: 6; radius: 2; color: Qt.rgba(1, 1, 1, 0.6) } } } }
        Rectangle { visible: kind === "mac"; anchors.bottom: parent.bottom; anchors.bottomMargin: 6; anchors.horizontalCenter: parent.horizontalCenter
                    width: 70; height: 14; radius: 7; color: Qt.rgba(1, 1, 1, 0.22)
                    Row { anchors.centerIn: parent; spacing: 4; Repeater { model: 5; Rectangle { width: 7; height: 7; radius: 2.5; color: Qt.rgba(1, 1, 1, 0.7) } } } }
        Rectangle { visible: (kind === "mac" && !Theme.gg) || kind === "win" || kind === "minimal"; x: parent.width * 0.22; y: 22; width: parent.width * 0.5; height: 62; radius: 6; color: Qt.rgba(0.03, 0.05, 0.10, 0.95)
                    Rectangle { x: 5; y: 5; width: 22; height: 3; radius: 1.5; color: Qt.rgba(1, 1, 1, 0.35) } }
        Rectangle { visible: kind === "float"; x: parent.width * 0.2; y: 22; width: parent.width * 0.5; height: 70; radius: 6; color: Qt.rgba(0.03, 0.05, 0.10, 0.95) }
        Rectangle { visible: kind === "float"; x: parent.width * 0.42; y: 48; width: parent.width * 0.4; height: 60; radius: 6; color: Qt.rgba(0.10, 0.15, 0.25, 0.95) }
        Row { visible: kind === "tile"; x: 6; y: 14; width: parent.width - 12; height: parent.height - 22; spacing: 5
              Rectangle { width: (parent.width - 5) / 2; height: parent.height; radius: 4; color: Qt.rgba(0.03, 0.05, 0.10, 0.95) }
              Column { width: (parent.width - 5) / 2; height: parent.height; spacing: 5
                       Rectangle { width: parent.width; height: (parent.height - 5) / 2; radius: 4; color: Qt.rgba(0.10, 0.15, 0.25, 0.95) }
                       Rectangle { width: parent.width; height: (parent.height - 5) / 2; radius: 4; color: Qt.rgba(0.10, 0.15, 0.25, 0.95) } } }
    }

    component DotfilesMock: Rectangle {
        anchors.fill: parent; radius: 10; clip: true
        gradient: Gradient { GradientStop { position: 0; color: "#1F4565" } GradientStop { position: 0.6; color: "#6CA4B8" } GradientStop { position: 0.85; color: "#E6D8C0" } }
        Shape {
            anchors.fill: parent
            ShapePath { fillColor: "#3E6E88"; strokeColor: "transparent"
                PathPolyline { path: [Qt.point(0, 110), Qt.point(40, 96), Qt.point(80, 104), Qt.point(130, 88), Qt.point(190, 102), Qt.point(210, 96), Qt.point(210, 140), Qt.point(0, 140)] } }
            ShapePath { fillColor: "#0A1522"; strokeColor: "transparent"
                PathPolyline { path: [Qt.point(0, 128), Qt.point(50, 112), Qt.point(95, 124), Qt.point(150, 104), Qt.point(210, 126), Qt.point(210, 140), Qt.point(0, 140)] } }
        }
        Rectangle { width: parent.width; height: 12; color: Qt.rgba(0.05, 0.1, 0.15, 0.7)
            Row { x: 8; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                  Repeater { model: ["1", "2", "7"]; Text { text: modelData; color: index === 1 ? "#FFFFFF" : "#9DB2BF"; font.pixelSize: 8 } } }
            Text { anchors.centerIn: parent; text: " Artista: Pista"; color: "#EAF1F5"; font.pixelSize: 7 }
            Text { anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: "19:22 | 06 Nov"; color: "#EAF1F5"; font.pixelSize: 7 } }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(24, parent.height * 0.08)
        spacing: 8
        Row { anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
              Brand { logoHeight: 14; anchors.verticalCenter: parent.verticalCenter; color: root.ink }
              Text { text: qsTr("¡Bienvenido a BC OS!"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 14 } }
        Text { anchors.horizontalCenter: parent.horizontalCenter; color: root.ink; font.family: Theme.fontFamily; font.pixelSize: 32; font.weight: Font.DemiBold
               text: root.step === 0 ? qsTr("¿Dónde está instalado BC OS?") : root.step === 1 ? qsTr("Elige cómo se ve tu escritorio") : (root.step === 2 ? qsTr("Elige tus colores y tu fondo") : qsTr("Elige cómo se organizan tus ventanas")) }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: qsTr("Puedes cambiarlo cuando quieras desde Configuración."); color: Theme.textSecondary
               font.family: Theme.fontFamily; font.pixelSize: 14 }
    }

    Item {
        id: body
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(130, parent.height * 0.08 + 110)
        width: parent.width; height: 300

        // Paso 0: dónde se ejecuta (adapta el render: por software en VM, GPU y efectos en equipo físico)
        Column {
            opacity: root.step === 0 ? 1 : 0; visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(220); easing.type: Easing.OutCubic } }
            anchors.horizontalCenter: parent.horizontalCenter; spacing: 16
            Row {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 18
                Card { title: qsTr("Máquina virtual"); badge: root.detected === "vm" ? qsTr("Detectado") : ""
                       desc: qsTr("VirtualBox, UTM, QEMU… Dibujo por software, ligero y estable, sin efectos de GPU.")
                       sel: root.machine === "vm"; onClicked: root.pickMachine("vm")
                       Rectangle { anchors.fill: parent; radius: 10; color: "#101626"
                           Rectangle { anchors.centerIn: parent; width: 120; height: 78; radius: 8; color: "#1B2740"; border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.2)
                               Rectangle { width: parent.width; height: 12; radius: 8; color: Qt.rgba(1, 1, 1, 0.12)
                                   Row { x: 6; anchors.verticalCenter: parent.verticalCenter; spacing: 3
                                         Repeater { model: ["#FF5F57", "#FEBC2E", "#28C840"]; Rectangle { required property string modelData; width: 5; height: 5; radius: 2.5; color: modelData } } } }
                               Text { anchors.centerIn: parent; anchors.verticalCenterOffset: 6; text: "BC OS"; color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 14; font.weight: Font.DemiBold } } } }
                Card { title: qsTr("Equipo físico"); badge: root.detected === "fisico" ? qsTr("Detectado") : ""
                       desc: Quick.hasGpu() ? qsTr("Usa la GPU: desenfoque real detrás de ventanas, sombras y esquinas redondeadas.")
                                            : qsTr("Usa la GPU cuando la haya: desenfoque real, sombras y esquinas (aquí no se detecta GPU).")
                       sel: root.machine === "fisico"; onClicked: root.pickMachine("fisico")
                       Rectangle { anchors.fill: parent; radius: 10; color: "#101626"
                           Rectangle { anchors.centerIn: parent; anchors.verticalCenterOffset: -8; width: 130; height: 82; radius: 6; color: "#05070D"; border.width: 3; border.color: "#3A4256"
                               Image { anchors.fill: parent; anchors.margins: 3; source: "qrc:/BCShell/assets/wallpaper-default.png"; fillMode: Image.PreserveAspectCrop; sourceSize.width: 260 } }
                           Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: parent.height / 2 + 34; width: 40; height: 6; radius: 3; color: "#3A4256" } } }
            }
            // En máquina virtual: resolución de la pantalla (se aplica ya y se recuerda en cada inicio)
            Column {
                visible: root.machine === "vm"
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: qsTr("Resolución de la pantalla")
                       color: root.ink; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.DemiBold }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
                    Repeater {
                        model: ["auto", "1280x800", "1440x900", "1470x956", "1512x982", "1710x1112", "1920x1080", "2560x1440"]
                        Rectangle {
                            required property string modelData
                            readonly property bool on: root.resolution === modelData
                            width: rtxt.implicitWidth + 26; height: 30; radius: 15
                            color: on ? Theme.accent : root.wash(rhov.containsMouse ? 0.16 : 0.1)
                            border.width: on ? 0 : 1; border.color: root.wash(0.16)
                            Behavior on color { ColorAnimation { duration: Theme.dur(160) } }
                            readonly property var mac: ({ "1470x956": "Air 13″", "1512x982": "Pro 14″", "1710x1112": "Air 15″" })
                            Text { id: rtxt; anchors.centerIn: parent; text: modelData === "auto" ? qsTr("Automática") : (parent.mac[modelData] ? parent.mac[modelData] : modelData.replace("x", " × "))
                                   color: parent.on ? Theme.white : root.ink; font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: Font.Medium }
                            MouseArea { id: rhov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.resolution = modelData; Quick.setDisplayMode(modelData) } }
                        }
                    }
                }
            }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: qsTr("Se aplica al volver a iniciar sesión. Se puede cambiar en Ajustes ▸ General.")
                   color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 13 }
        }

        // Paso 1: estilo
        Row {
            opacity: root.step === 1 ? 1 : 0; visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(220); easing.type: Easing.OutCubic } }
            scale: root.step === 1 ? 1 : 0.97
            Behavior on scale { NumberAnimation { duration: Theme.dur(260); easing.type: Easing.OutCubic } }
            anchors.horizontalCenter: parent.horizontalCenter; spacing: 18
            Card { title: qsTr("Windows"); badge: qsTr("Lo de siempre"); desc: qsTr("Barra de tareas abajo con menú Inicio y los atajos de siempre.")
                   sel: UiState.style === "win" && !root.dotfilesChosen; onClicked: root.pickStyle("win"); Mock { kind: "win" } }
            Card { title: qsTr("BC"); badge: qsTr("Recomendado"); desc: qsTr("Barra arriba con menús, Dock flotante y animaciones: el estilo de BC OS.")
                   sel: UiState.style === "mac" && !root.dotfilesChosen; onClicked: root.pickStyle("mac"); Mock { kind: "mac" } }
            Card { title: qsTr("Dotfiles"); badge: qsTr("Mosaico"); desc: qsTr("bspwm con polybar, rofi y picom (X11). Se activa al volver a iniciar sesión.")
                   sel: root.dotfilesChosen; onClicked: root.pickDotfiles(); DotfilesMock { } }
        }

        Row {
            visible: root.step === 1 && root.dotfilesChosen
            anchors.horizontalCenter: parent.horizontalCenter
            y: 282; spacing: 12
            Text { anchors.verticalCenter: parent.verticalCenter; text: qsTr("Cierra la sesión y vuelve a entrar para usar Dotfiles."); color: Theme.textSecondary
                   font.family: Theme.fontFamily; font.pixelSize: 14 }
            Rectangle { height: 30; width: lo.implicitWidth + 28; radius: 15; color: Theme.accent
                        Text { id: lo; anchors.centerIn: parent; text: qsTr("Cerrar sesión ahora"); color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 13 }
                        MouseArea { anchors.fill: parent; onClicked: { Settings.welcomed = true; root.finished(); UiState.openPower("logout") } } }
        }

        // Paso 1: colores y fondo
        Column {
            opacity: root.step === 2 ? 1 : 0; visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(220); easing.type: Easing.OutCubic } }
            scale: root.step === 2 ? 1 : 0.97
            Behavior on scale { NumberAnimation { duration: Theme.dur(260); easing.type: Easing.OutCubic } }
            anchors.horizontalCenter: parent.horizontalCenter; spacing: 22
            // Aspecto: tres miniaturas como en Ajustes ▸ Aspecto de macOS
            Row {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 28
                Repeater {
                    model: [ { v: "light", t: qsTr("Claro") }, { v: "dark", t: qsTr("Oscuro") }, { v: "auto", t: qsTr("Automático") } ]
                    Column {
                        required property var modelData
                        readonly property bool sel: Settings.appearance === modelData.v
                        spacing: 8
                        Rectangle {
                            width: 112; height: 72; radius: 12; color: "transparent"
                            border.width: parent.sel ? 3 : 0; border.color: Theme.accent
                            Rectangle {
                                anchors.fill: parent; anchors.margins: parent.parent.sel ? 5 : 0; radius: 8; clip: true
                                gradient: Gradient {
                                    GradientStop { position: 0; color: modelData.v === "dark" ? "#27305A" : "#CFE3FA" }
                                    GradientStop { position: 1; color: modelData.v === "dark" ? "#141A30" : "#8DB6E6" } }
                                Rectangle { x: 8; y: 8; width: parent.width * 0.62; height: parent.height - 16; radius: 5; color: modelData.v === "dark" ? "#2C2C31" : "#FFFFFF"
                                    Row { x: 5; y: 5; spacing: 3; Repeater { model: [Theme.close, Theme.minimize, Theme.zoom]
                                          Rectangle { required property color modelData; width: 5; height: 5; radius: 2.5; color: modelData } } } }
                                Item { visible: modelData.v === "auto"; x: parent.width / 2; width: parent.width / 2; height: parent.height; clip: true
                                       Rectangle { x: -parent.x; width: parent.parent.width; height: parent.height
                                                   gradient: Gradient { GradientStop { position: 0; color: "#27305A" } GradientStop { position: 1; color: "#141A30" } } }
                                       Rectangle { x: 8 - parent.x; y: 8; width: parent.parent.width * 0.62; height: parent.parent.height - 16; radius: 5; color: "#2C2C31" } }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Settings.appearance = modelData.v }
                        }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.t; color: parent.sel ? root.ink : Theme.textSecondary
                               font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: parent.sel ? Font.DemiBold : Font.Normal }
                    }
                }
            }
            // Fondos: rejilla de miniaturas con el nombre debajo (sin cortes a los lados)
            Grid {
                anchors.horizontalCenter: parent.horizontalCenter; columns: 6; columnSpacing: 14; rowSpacing: 10
                Repeater {
                    model: root.wallpapers
                    delegate: Column {
                        required property var modelData
                        readonly property bool sel: Settings.wallpaper === root.wallDir + modelData.f || (Settings.wallpaper === "" && modelData.f === "ondas.jpg")
                        spacing: 5
                        Rectangle {
                            width: 132; height: 80; radius: 10; color: "transparent"
                            border.width: parent.sel ? 3 : 0; border.color: Theme.accent
                            Rectangle { anchors.fill: parent; anchors.margins: parent.parent.sel ? 4 : 0; radius: parent.parent.sel ? 7 : 10; clip: true; color: "#0A1020"
                                Image { anchors.fill: parent; source: root.step === 2 ? "file://" + root.wallDir + modelData.f : ""; fillMode: Image.PreserveAspectCrop
                                        asynchronous: true; sourceSize.width: 280; smooth: true } }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.pickWallpaper(modelData.f) }
                        }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.n; color: parent.sel ? root.ink : Theme.textSecondary
                               font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: parent.sel ? Font.DemiBold : Font.Normal }
                    }
                }
            }
            // Color de acento: círculos con anillo en el elegido (como macOS)
            Row { anchors.horizontalCenter: parent.horizontalCenter; spacing: 12
                  Text { anchors.verticalCenter: parent.verticalCenter; text: qsTr("Color de acento"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 14; rightPadding: 6 }
                  Repeater {
                      model: root.accents
                      delegate: Rectangle {
                          required property string modelData
                          readonly property bool sel: AppConfig.accent.toLowerCase() === modelData.toLowerCase()
                          width: 28; height: 28; radius: 14; color: "transparent"; border.width: sel ? 2 : 0; border.color: modelData
                          Rectangle { anchors.centerIn: parent; width: parent.sel ? 20 : 26; height: width; radius: width / 2; color: modelData }
                          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.pickAccent(modelData) }
                      }
                  } }
        }

        // Paso 2: ventanas
        Column {
            opacity: root.step === 3 ? 1 : 0; visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(220); easing.type: Easing.OutCubic } }
            scale: root.step === 3 ? 1 : 0.97
            Behavior on scale { NumberAnimation { duration: Theme.dur(260); easing.type: Easing.OutCubic } }
            anchors.horizontalCenter: parent.horizontalCenter; spacing: 22
            Row { anchors.horizontalCenter: parent.horizontalCenter; spacing: 18
                  Card { title: qsTr("Flotantes"); badge: qsTr("Como siempre"); desc: qsTr("Las ventanas se colocan y se mueven libremente.")
                         sel: !Sway.tiling; onClicked: root.pickTiling(false); Mock { kind: "float" } }
                  Card { title: qsTr("Mosaico"); badge: ""; desc: qsTr("Las ventanas se reparten la pantalla solas, como en bspwm.")
                         sel: Sway.tiling; onClicked: root.pickTiling(true); Mock { kind: "tile" } } }
            Row { anchors.horizontalCenter: parent.horizontalCenter; spacing: 10
                  Chip { text: qsTr("Widgets en el escritorio"); sel: Settings.widgets; onClicked: { Settings.widgets = !Settings.widgets; UiState.widgets = Settings.widgets } }
                  Chip { text: qsTr("Relajación"); sel: UiState.mode === "relax"; onClicked: { const m = UiState.mode === "relax" ? "" : "relax"; UiState.mode = m; Settings.mode = m } }
                  Chip { text: qsTr("Concentración"); sel: UiState.mode === "focus"; onClicked: { const m = UiState.mode === "focus" ? "" : "focus"; UiState.mode = m; Settings.mode = m } }
                  Chip { text: qsTr("Noche"); sel: UiState.mode === "night"; onClicked: { const m = UiState.mode === "night" ? "" : "night"; UiState.mode = m; Settings.mode = m } } }
        }
    }

    // Pie
    Row {
        anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 56; spacing: 18
        Rectangle { visible: root.step === 0; width: 90; height: 38; radius: 19; color: root.wash(0.1)
                    Text { anchors.centerIn: parent; text: qsTr("Saltar"); color: root.ink; font.family: Theme.fontFamily; font.pixelSize: 14 }
                    MouseArea { anchors.fill: parent; onClicked: root.finish() } }
        Rectangle { visible: root.step > 0; width: 90; height: 38; radius: 19; color: root.wash(0.1)
                    Text { anchors.centerIn: parent; text: qsTr("Atrás"); color: root.ink; font.family: Theme.fontFamily; font.pixelSize: 14 }
                    MouseArea { anchors.fill: parent; onClicked: root.step-- } }
        Row { anchors.verticalCenter: parent.verticalCenter; spacing: 8
              Repeater { model: root.steps
                         delegate: Rectangle { required property int index; width: index === root.step ? 22 : 8; height: 8; radius: 4
                                               color: index === root.step ? Theme.accent : root.wash(0.3)
                                               Behavior on width { NumberAnimation { duration: Theme.dur(160) } } } } }
        Rectangle { width: root.step === root.steps - 1 ? 220 : 130; height: 38; radius: 19; color: Theme.accent
                    Text { anchors.centerIn: parent; text: root.step === root.steps - 1 ? qsTr("Empezar a usar BC OS") : qsTr("Continuar"); color: Theme.white
                           font.family: Theme.fontFamily; font.pixelSize: 14; font.weight: Font.DemiBold }
                    MouseArea { anchors.fill: parent; onClicked: root.next() } }
    }
}
