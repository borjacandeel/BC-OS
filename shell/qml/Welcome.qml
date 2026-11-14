import QtQuick
import BCShell

// Asistente de bienvenida de BC OS (primer inicio y desde Configuración): estilo de escritorio,
// colores y fondo, y organización de ventanas. Todo se aplica al instante.
Item {
    id: root
    property int step: 0
    readonly property int steps: 3
    signal finished()
    readonly property string wallDir: "/usr/share/bc/wallpapers/"
    readonly property var wallpapers: [
        { f: "medianoche.jpg", n: qsTr("Medianoche") }, { f: "oceano.jpg", n: qsTr("Océano") },
        { f: "grafito.jpg", n: qsTr("Grafito") }, { f: "plata.jpg", n: qsTr("Plata") }]
    // Solo los colores base de BC OS (los del semáforo y los de las tarjetas del Monitor)
    readonly property var accents: ["#2F7BF5", "#34C759", "#FF9F0A", "#FF5F57", "#8E9BB2"]

    function pickStyle(id) { Settings.desktopStyle = id; UiState.style = id }
    function pickWallpaper(f) { Settings.wallpaper = wallDir + f }
    function pickAccent(c) { Settings.accent = c; AppConfig.setAccent(c) }
    function pickTiling(on) { Sway.setTiling(on) }
    function next() { if (step < steps - 1) step++; else finish() }
    function finish() { Settings.welcomed = true; root.finished() }
    focus: true
    Keys.onEscapePressed: finish()
    Keys.onRightPressed: next()
    Keys.onLeftPressed: if (step > 0) step--
    Keys.onReturnPressed: next()

    Rectangle { anchors.fill: parent; color: Qt.rgba(0.02, 0.03, 0.07, 0.97) }
    MouseArea { anchors.fill: parent }   // no deja pasar clics

    component Chip: Rectangle {
        property string text
        property bool sel: false
        signal clicked()
        height: 34; width: chipT.implicitWidth + 32; radius: 17
        color: sel ? Theme.accent : Qt.rgba(1, 1, 1, 0.1)
        Text { id: chipT; anchors.centerIn: parent; text: parent.text; color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 14 }
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
        color: Qt.rgba(1, 1, 1, sel ? 0.12 : 0.06)
        border.width: sel ? 2 : 1; border.color: sel ? Theme.accent : Theme.hairline
        Behavior on color { ColorAnimation { duration: Theme.dur(120) } }
        Item { id: pv; x: 10; y: 10; width: parent.width - 20; height: 140; clip: true }
        Rectangle { visible: cardRoot.sel; x: parent.width - 36; y: 18; width: 22; height: 22; radius: 11; color: Theme.accent
                    Text { anchors.centerIn: parent; text: "✓"; color: Theme.white; font.pixelSize: 13 } }
        Row { x: 16; y: 162; spacing: 8
              Text { text: cardRoot.title; color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 17; font.weight: Font.DemiBold }
              Rectangle { visible: cardRoot.badge !== ""; anchors.verticalCenter: parent.verticalCenter; width: bT.implicitWidth + 12; height: 18; radius: 9
                          color: Qt.rgba(1, 1, 1, 0.14)
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
        Rectangle { visible: kind === "mac" || kind === "minimal" || kind === "float" || kind === "tile"; width: parent.width; height: 8; color: Qt.rgba(1, 1, 1, 0.18) }
        Rectangle { visible: kind === "win"; anchors.bottom: parent.bottom; width: parent.width; height: 10; color: Qt.rgba(1, 1, 1, 0.2)
                    Row { anchors.centerIn: parent; spacing: 4; Repeater { model: 5; Rectangle { width: 6; height: 6; radius: 2; color: Qt.rgba(1, 1, 1, 0.6) } } } }
        Rectangle { visible: kind === "mac"; anchors.bottom: parent.bottom; anchors.bottomMargin: 6; anchors.horizontalCenter: parent.horizontalCenter
                    width: 70; height: 14; radius: 7; color: Qt.rgba(1, 1, 1, 0.22)
                    Row { anchors.centerIn: parent; spacing: 4; Repeater { model: 5; Rectangle { width: 7; height: 7; radius: 2.5; color: Qt.rgba(1, 1, 1, 0.7) } } } }
        Rectangle { visible: kind === "mac" || kind === "win" || kind === "minimal"; x: parent.width * 0.22; y: 22; width: parent.width * 0.5; height: 62; radius: 6; color: Qt.rgba(0.03, 0.05, 0.10, 0.95)
                    Rectangle { x: 5; y: 5; width: 22; height: 3; radius: 1.5; color: Qt.rgba(1, 1, 1, 0.35) } }
        Rectangle { visible: kind === "float"; x: parent.width * 0.2; y: 22; width: parent.width * 0.5; height: 70; radius: 6; color: Qt.rgba(0.03, 0.05, 0.10, 0.95) }
        Rectangle { visible: kind === "float"; x: parent.width * 0.42; y: 48; width: parent.width * 0.4; height: 60; radius: 6; color: Qt.rgba(0.10, 0.15, 0.25, 0.95) }
        Row { visible: kind === "tile"; x: 6; y: 14; width: parent.width - 12; height: parent.height - 22; spacing: 5
              Rectangle { width: (parent.width - 5) / 2; height: parent.height; radius: 4; color: Qt.rgba(0.03, 0.05, 0.10, 0.95) }
              Column { width: (parent.width - 5) / 2; height: parent.height; spacing: 5
                       Rectangle { width: parent.width; height: (parent.height - 5) / 2; radius: 4; color: Qt.rgba(0.10, 0.15, 0.25, 0.95) }
                       Rectangle { width: parent.width; height: (parent.height - 5) / 2; radius: 4; color: Qt.rgba(0.10, 0.15, 0.25, 0.95) } } }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(24, parent.height * 0.08)
        spacing: 8
        Row { anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
              Brand { logoHeight: 14; anchors.verticalCenter: parent.verticalCenter }
              Text { text: qsTr("¡Bienvenido a BC OS!"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 14 } }
        Text { anchors.horizontalCenter: parent.horizontalCenter; color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 32; font.weight: Font.DemiBold
               text: root.step === 0 ? qsTr("Elige cómo se ve tu escritorio") : (root.step === 1 ? qsTr("Elige tus colores y tu fondo") : qsTr("Elige cómo se organizan tus ventanas")) }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: qsTr("Puedes cambiarlo cuando quieras desde Configuración."); color: Theme.textSecondary
               font.family: Theme.fontFamily; font.pixelSize: 14 }
    }

    Item {
        id: body
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(130, parent.height * 0.08 + 110)
        width: parent.width; height: 300

        // Paso 0: estilo
        Row {
            visible: root.step === 0
            anchors.horizontalCenter: parent.horizontalCenter; spacing: 18
            Card { title: qsTr("Windows"); badge: qsTr("Lo de siempre"); desc: qsTr("Barra de tareas abajo con menú Inicio y los atajos de siempre.")
                   sel: UiState.style === "win"; onClicked: root.pickStyle("win"); Mock { kind: "win" } }
            Card { title: qsTr("BC"); badge: qsTr("Recomendado"); desc: qsTr("Barra arriba con menús, Dock flotante y animaciones: el estilo de BC OS.")
                   sel: UiState.style === "mac"; onClicked: root.pickStyle("mac"); Mock { kind: "mac" } }
            Card { title: qsTr("Minimal"); badge: ""; desc: qsTr("Solo la barra superior: limpio, sin Dock ni widgets.")
                   sel: UiState.style === "minimal"; onClicked: root.pickStyle("minimal"); Mock { kind: "minimal" } }
        }

        // Paso 1: colores y fondo
        Column {
            visible: root.step === 1
            anchors.horizontalCenter: parent.horizontalCenter; spacing: 22
            Row { anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
                  Chip { text: qsTr("Oscuro"); sel: true }
                  Chip { text: qsTr("Claro (próximamente)"); opacity: 0.5 } }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 12
                Repeater {
                    model: root.wallpapers
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool sel: Settings.wallpaper === root.wallDir + modelData.f || (Settings.wallpaper === "" && modelData.f === "medianoche.jpg")
                        width: 150; height: 100; radius: 12; color: "#0A1020"; clip: true
                        border.width: sel ? 3 : 1; border.color: sel ? Theme.accent : Theme.hairline
                        Image { anchors.fill: parent; anchors.margins: 3; source: root.step === 1 && visible ? "file://" + root.wallDir + modelData.f : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 300 }
                        Text { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottomMargin: 5; text: modelData.n
                               color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 12; style: Text.Outline; styleColor: "#000000" }
                        MouseArea { anchors.fill: parent; onClicked: root.pickWallpaper(modelData.f) }
                    }
                }
            }
            Row { anchors.horizontalCenter: parent.horizontalCenter; spacing: 12
                  Text { anchors.verticalCenter: parent.verticalCenter; text: qsTr("Color de acento"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 14 }
                  Repeater {
                      model: root.accents
                      delegate: Rectangle {
                          required property string modelData
                          width: 30; height: 30; radius: 15; color: modelData
                          border.width: AppConfig.accent.toLowerCase() === modelData.toLowerCase() ? 3 : 0; border.color: Theme.white
                          MouseArea { anchors.fill: parent; onClicked: root.pickAccent(modelData) }
                      }
                  } }
        }

        // Paso 2: ventanas
        Column {
            visible: root.step === 2
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
        Rectangle { visible: root.step === 0; width: 90; height: 38; radius: 19; color: Qt.rgba(1, 1, 1, 0.1)
                    Text { anchors.centerIn: parent; text: qsTr("Saltar"); color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 14 }
                    MouseArea { anchors.fill: parent; onClicked: root.finish() } }
        Rectangle { visible: root.step > 0; width: 90; height: 38; radius: 19; color: Qt.rgba(1, 1, 1, 0.1)
                    Text { anchors.centerIn: parent; text: qsTr("Atrás"); color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 14 }
                    MouseArea { anchors.fill: parent; onClicked: root.step-- } }
        Row { anchors.verticalCenter: parent.verticalCenter; spacing: 8
              Repeater { model: root.steps
                         delegate: Rectangle { required property int index; width: index === root.step ? 22 : 8; height: 8; radius: 4
                                               color: index === root.step ? Theme.accent : Qt.rgba(1, 1, 1, 0.3)
                                               Behavior on width { NumberAnimation { duration: Theme.dur(160) } } } } }
        Rectangle { width: root.step === root.steps - 1 ? 220 : 130; height: 38; radius: 19; color: Theme.accent
                    Text { anchors.centerIn: parent; text: root.step === root.steps - 1 ? qsTr("Empezar a usar BC OS") : qsTr("Continuar"); color: Theme.white
                           font.family: Theme.fontFamily; font.pixelSize: 14; font.weight: Font.DemiBold }
                    MouseArea { anchors.fill: parent; onClicked: root.next() } }
    }
}
