import QtQuick
import BCShell

// Mission Control (Ctrl+↑, F3, 3 dedos hacia arriba): las ventanas del escritorio actual se despliegan desde su
// posición real a una rejilla sin solaparse; arriba, la barra de Spaces (escritorios) con «+» para crear otro.
// Clic en una ventana: se enfoca; arrastrarla a un escritorio: se mueve allí. Las miniaturas salen de una captura
// de la pantalla con grim tomada al abrir.
Item {
    id: mc
    anchors.fill: parent
    readonly property real s: Theme.s
    function px(v) { return Math.round(v * s) }
    property bool open: UiState.missionOpen
    property real t: 0                         // 0 = ventanas en su sitio · 1 = rejilla
    property string shot: ""
    property var wins: []
    signal closed()
    // Multipantalla: cada pantalla adicional tiene su propio Mission Control con sus escritorios y ventanas
    property string outName: ""                 // vacío = pantalla principal (escritorio enfocado)
    property point origin: Qt.point(0, 0)       // posición de la pantalla en el escritorio global
    readonly property string tag: "mission" + (outName ? "-" + outName : "")

    readonly property var spaces: Sway.workspaces.filter(w => w.name !== "__i3_scratch" && (outName === "" || w.output === outName))
    readonly property var current: (outName === "" ? spaces.find(w => w.focused) : spaces.find(w => w.visible)) || null

    onOpenChanged: {
        if (open) {
            wins = Sway.windows.filter(w => !w.minimized && current && w.workspace === current.name && w.rectW > 0)
            shot = ""
            Quick.capture(tag, outName === "" ? "" : origin.x + "," + origin.y + " " + Math.round(width) + "x" + Math.round(height))
            t = 0
            inAnim.restart()
        } else if (t > 0) outAnim.restart()
    }
    Connections { target: Quick; function onCaptured(tag, path, ok) { if (tag === mc.tag && ok) { mc.shot = ""; mc.shot = "file://" + path } } }
    NumberAnimation { id: inAnim; target: mc; property: "t"; to: 1; duration: Theme.d(Theme.durMissionControl); easing.type: Theme.easeEmphasized }
    NumberAnimation { id: outAnim; target: mc; property: "t"; to: 0; duration: Theme.d(Theme.durMissionControl * 0.8); easing.type: Theme.easeInOut; onFinished: mc.closed() }

    function close(focusId) {
        if (focusId !== undefined && focusId >= 0) Sway.focusWindow(focusId)
        UiState.missionOpen = false
    }

    // Fondo: escritorio desenfocado y oscurecido
    Glass { anchors.fill: parent; radius: 0; shadow: false; rim: false; tintBoost: 0.15; opacity: mc.t }
    Rectangle { anchors.fill: parent; color: "black"; opacity: 0.25 * mc.t }
    MouseArea { anchors.fill: parent; onClicked: mc.close() }
    focus: mc.open
    Keys.onEscapePressed: mc.close()

    // ---- Barra de Spaces ---------------------------------------------------------------------
    Row {
        id: spacesRow
        anchors.horizontalCenter: parent.horizontalCenter
        y: px(18) - (1 - mc.t) * px(140)
        spacing: px(18)
        Repeater {
            model: mc.spaces
            delegate: Column {
                required property var modelData
                spacing: px(6)
                Rectangle {
                    id: thumb
                    width: px(192); height: width * UiState.sh / UiState.sw; radius: px(8); clip: true
                    color: "transparent"
                    border.width: modelData.focused ? px(3) : 1
                    border.color: modelData.focused ? "white" : Qt.rgba(1, 1, 1, 0.3)
                    Wallpaper { anchors.fill: parent; anchors.margins: parent.border.width }
                    Text { anchors.centerIn: parent; text: Sway.windows.filter(w => w.workspace === modelData.name && !w.minimized).length || ""
                           color: "white"; font.family: Theme.font; font.pixelSize: px(22); font.weight: Font.Bold; style: Text.Raised; styleColor: "#40000000" }
                    DropArea { anchors.fill: parent; keys: ["bc-window"]
                               onDropped: (d) => { Sway.moveToWorkspace(d.source.winId, modelData.name) } }
                    MouseArea { anchors.fill: parent; onClicked: { Sway.switchWorkspace(modelData.name); mc.close() } }
                }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: qsTr("Escritorio %1").arg(modelData.num >= 0 ? modelData.num : modelData.name)
                       color: "white"; font.family: Theme.font; font.pixelSize: px(12); font.weight: modelData.focused ? Font.DemiBold : Font.Normal }
            }
        }
        // Añadir escritorio
        Rectangle {
            width: px(56); height: px(108); radius: px(8); color: Qt.rgba(1, 1, 1, addMa.containsMouse || addDrop.containsDrag ? 0.22 : 0.12)
            Text { anchors.centerIn: parent; text: "+"; color: "white"; font.pixelSize: px(30); font.weight: Font.Light }
            // Soltar una ventana aquí crea un escritorio nuevo con ella (como arrastrarla arriba en macOS)
            DropArea { id: addDrop; anchors.fill: parent; keys: ["bc-window"]
                       onDropped: (d) => { let n = 1; for (const w of mc.spaces) n = Math.max(n, w.num + 1); Sway.moveToWorkspace(d.source.winId, String(n)) } }
            scale: addDrop.containsDrag ? 1.15 : 1
            Behavior on scale { NumberAnimation { duration: Theme.d(160); easing.type: Easing.OutCubic } }
            MouseArea { id: addMa; anchors.fill: parent; hoverEnabled: true
                        onClicked: { let n = 1; for (const w of mc.spaces) n = Math.max(n, w.num + 1); Sway.switchWorkspace(String(n)); mc.close() } }
        }
    }

    // ---- Ventanas ----------------------------------------------------------------------------
    readonly property rect area: Qt.rect(px(80), px(190), width - px(160), height - px(260))
    readonly property int cols: Math.max(1, Math.ceil(Math.sqrt(wins.length * area.width / area.height / 1.6)))
    readonly property int rows: Math.max(1, Math.ceil(wins.length / cols))
    function slot(i, w) {
        const cw = area.width / cols, ch = area.height / rows
        const r = Math.floor(i / cols), c = i % cols
        const inRow = Math.min(cols, wins.length - r * cols)
        const sc = Math.min(1, (cw - px(40)) / w.rectW, (ch - px(50)) / w.rectH)
        const ww = w.rectW * sc, hh = w.rectH * sc
        const rowOffset = (cols - inRow) * cw / 2
        return Qt.rect(area.x + rowOffset + c * cw + (cw - ww) / 2, area.y + r * ch + (ch - hh) / 2, ww, hh)
    }
    Repeater {
        model: mc.wins
        delegate: Item {
            id: wd
            required property var modelData
            required property int index
            readonly property int winId: modelData.id
            readonly property rect a: Qt.rect(modelData.decoX - mc.origin.x, modelData.decoY - mc.origin.y, modelData.rectW, modelData.rectH)
            readonly property rect b: mc.slot(index, modelData)
            x: a.x + (b.x - a.x) * mc.t; y: a.y + (b.y - a.y) * mc.t
            width: a.width + (b.width - a.width) * mc.t; height: a.height + (b.height - a.height) * mc.t
            Drag.active: dma.drag.active; Drag.keys: ["bc-window"]; Drag.source: wd; Drag.hotSpot: Qt.point(width / 2, height / 2)
            Rectangle { anchors.fill: parent; anchors.margins: -px(4); radius: px(12); color: "transparent"; border.width: px(3)
                        border.color: Theme.selection; visible: dma.containsMouse }
            Rectangle { anchors.fill: parent; radius: px(10); color: Theme.windowBg; visible: mc.shot === "" }
            Image {
                anchors.fill: parent; source: mc.shot; smooth: true; cache: false
                sourceClipRect: Qt.rect(wd.a.x, wd.a.y, wd.a.width, wd.a.height)
            }
            Rectangle {
                visible: dma.containsMouse; anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.bottom; anchors.topMargin: px(10)
                width: lbl.implicitWidth + px(20); height: px(24); radius: height / 2; color: Qt.rgba(0, 0, 0, 0.55)
                Text { id: lbl; anchors.centerIn: parent; text: modelData.title || AppMenus.nameFor(modelData.appId); color: "white"
                       font.family: Theme.font; font.pixelSize: px(12); elide: Text.ElideRight; width: Math.min(implicitWidth, px(300)) }
            }
            MouseArea {
                id: dma; anchors.fill: parent; hoverEnabled: true
                drag.target: mc.t >= 1 ? wd : null
                onReleased: { if (drag.active) { wd.Drag.drop(); x = Qt.binding(() => a.x + (b.x - a.x) * mc.t); y = Qt.binding(() => a.y + (b.y - a.y) * mc.t) } }
                onClicked: mc.close(modelData.id)
            }
        }
    }
    Text {
        visible: mc.wins.length === 0 && mc.t > 0.5
        anchors.centerIn: parent; text: qsTr("No hay ventanas en este escritorio"); color: Qt.rgba(1, 1, 1, 0.8)
        font.family: Theme.font; font.pixelSize: px(16)
    }
}
