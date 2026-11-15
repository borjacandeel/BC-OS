import QtQuick
import BCShell

// Widgets de escritorio Golden Gate (captura): columna pegada a la izquierda bajo la barra, mismo ancho,
// vidrio oscuro tintado por el fondo. Baterías y Recordatorios con datos reales; el del medio aloja widgets
// de otras apps (WidgetHost: ~/.local/share/bc/widgets/*.json) o, si no hay, «Uso del equipo» de BC OS.
// Se pueden arrastrar a cualquier sitio (posición guardada) y volver a su columna desde el menú contextual.
Item {
    id: root
    anchors.fill: parent
    readonly property real s: Theme.s
    function px(v) { return Math.round(v * s) }

    Binding { target: Batteries; property: "active"; value: root.visible }
    Binding { target: Monitor; property: "active"; value: root.visible && WidgetHost.widgets.length === 0; when: root.visible }

    // Posiciones guardadas { id: [x, y] } relativas a 1080p
    property var layout: { try { return JSON.parse(Settings.widgetLayout || "{}") } catch (e) { return {} } }
    function savePos(id, x, y) {
        const l = Object.assign({}, layout); l[id] = [Math.round(x / s), Math.round(y / s)]
        Settings.widgetLayout = JSON.stringify(l)
    }
    function resetLayout() { Settings.widgetLayout = "{}" }
    function defY(i) {
        const hs = [Theme.widgetLargeH, Theme.widgetMediumH, Theme.widgetLargeH]
        let y = Theme.widgetY
        for (let k = 0; k < i; ++k) y += hs[k] + Theme.widgetGap
        return px(y)
    }

    // ---- Contenedor arrastrable --------------------------------------------------------------
    component Widget: Item {
        id: w
        property string wid
        property int order: 0
        property real baseH: Theme.widgetLargeH
        default property alias content: inner.data
        width: root.px(Theme.widgetW); height: root.px(baseH)
        x: root.layout[wid] ? root.layout[wid][0] * root.s : root.px(Theme.widgetX)
        y: root.layout[wid] ? root.layout[wid][1] * root.s : root.defY(order)
        Glass { anchors.fill: parent; radius: root.px(Theme.widgetRadius); tintBoost: 0.18 }
        Item { id: inner; anchors.fill: parent }
        // Arrastrar desde cualquier zona sin controles (como en macOS: se coge el widget entero)
        MouseArea {
            anchors.fill: parent; z: -1
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            drag.target: w; drag.threshold: 6
            drag.minimumX: 0; drag.maximumX: UiState.sw - w.width
            drag.minimumY: UiState.topInset; drag.maximumY: UiState.sh - w.height
            onReleased: if (drag.active || w.x !== (root.layout[w.wid] ? root.layout[w.wid][0] * root.s : root.px(Theme.widgetX))) root.savePos(w.wid, w.x, w.y)
            onClicked: (m) => { if (m.button === Qt.RightButton) UiState.openContextMenu([
                { label: qsTr("Volver a colocar los widgets"), cmd: "bc:widgetsReset" },
                { label: qsTr("Ocultar widgets"), cmd: "bc:toggleWidgets" }, { sep: true },
                { label: qsTr("Ajustes de widgets…"), cmd: "sway:exec bc-shell --app settings" } ], w.mapToItem(null, m.x, m.y)) }
        }
        Behavior on x { enabled: !Theme.reduced; NumberAnimation { duration: Theme.d(Theme.durPopover); easing.type: Theme.easeStandard } }
        Behavior on y { enabled: !Theme.reduced; NumberAnimation { duration: Theme.d(Theme.durPopover); easing.type: Theme.easeStandard } }
    }
    Connections { target: UiState; function onCommand(kind, arg) { if (kind === "bc" && arg === "widgetsReset") root.resetLayout() } }

    component Label: Text {
        color: Theme.label; font.family: Theme.font; font.pixelSize: root.px(Theme.widgetBodyPx)
        font.letterSpacing: Theme.letterSpacing; elide: Text.ElideRight
    }
    // Mini batería (captura: 20×10 a la derecha de cada fila)
    component MiniBattery: Item {
        property int percent: 0
        width: root.px(21); height: root.px(10)
        Rectangle { id: b; width: parent.width - root.px(2); height: parent.height; radius: root.px(2.5); color: "transparent"
                    border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.55)
                    Rectangle { x: root.px(2); y: root.px(2); height: parent.height - root.px(4); radius: 1
                                width: Math.max(1, (parent.width - root.px(4)) * percent / 100)
                                color: percent <= 15 ? "#FF453A" : Theme.label } }
        Rectangle { anchors.left: b.right; anchors.verticalCenter: parent.verticalCenter; width: root.px(1.5); height: root.px(4); color: Qt.rgba(1, 1, 1, 0.55) }
    }

    // ---- 1. Baterías ------------------------------------------------------------------------
    Widget {
        id: batW
        wid: "baterias"; order: 0
        readonly property var devs: Batteries.devices.length > 0 ? Batteries.devices
                                   : [{ name: qsTr("Este equipo"), percent: -1, kind: "laptop", charging: false }]
        Repeater {
            model: 5
            delegate: Item {
                required property int index
                readonly property var dev: index < batW.devs.length ? batW.devs[index] : null
                y: root.px(Theme.batteryRowH * index); width: parent.width; height: root.px(Theme.batteryRowH)
                Icon {
                    visible: dev !== null
                    x: root.px(Theme.batteryIconX) - width / 2; anchors.verticalCenter: parent.verticalCenter; size: root.px(17); color: Theme.label
                    name: !dev ? "" : ({ laptop: "computer-symbolic", mouse: "input-mouse-symbolic", keyboard: "input-keyboard-symbolic",
                                        headphones: "audio-headphones-symbolic", phone: "phone-symbolic" })[dev.kind] || "battery-level-80-symbolic"
                }
                Label { visible: dev !== null; x: root.px(Theme.batteryTextX); anchors.verticalCenter: parent.verticalCenter
                        width: root.px(200); text: dev ? dev.name : ""; font.weight: Font.Medium; font.pixelSize: root.px(Theme.widgetSmallPx) }
                Label { visible: dev !== null; anchors.right: mini.left; anchors.rightMargin: root.px(13); anchors.verticalCenter: parent.verticalCenter
                        text: !dev ? "" : (dev.percent < 0 ? qsTr("Corriente") : dev.percent + " %"); font.weight: Font.Medium; font.pixelSize: root.px(Theme.widgetSmallPx) }
                MiniBattery { id: mini; visible: dev !== null && dev.percent >= 0; percent: dev ? dev.percent : 0
                              anchors.right: parent.right; anchors.rightMargin: root.px(20); anchors.verticalCenter: parent.verticalCenter }
                Rectangle { x: root.px(Theme.batteryTextX); anchors.bottom: parent.bottom; width: parent.width - x; height: 1; color: Theme.separator }
            }
        }
    }

    // ---- 2. Widget de app (o «Uso del equipo») --------------------------------------------------
    Widget {
        id: appW
        wid: "app"; order: 1; baseH: Theme.widgetMediumH
        readonly property var info: WidgetHost.widgets.length > 0 ? WidgetHost.widgets[0] : {
            title: qsTr("Uso del equipo"), icon: "power-profile-performance-symbolic",
            rows: [ { label: qsTr("CPU"), detail: Monitor.cpu.toFixed(0) + " %", value: Monitor.cpu / 100, hasValue: true, right: (100 - Monitor.cpu).toFixed(0) + qsTr("% libre") },
                    { label: qsTr("Memoria"), detail: (Monitor.memUsed / 1073741824).toFixed(1) + " GB", value: Monitor.memTotal > 0 ? Monitor.memUsed / Monitor.memTotal : 0, hasValue: true,
                      right: Monitor.memTotal > 0 ? (100 - 100 * Monitor.memUsed / Monitor.memTotal).toFixed(0) + qsTr("% libre") : "" },
                    { label: qsTr("Disco"), detail: (Monitor.diskUsed / 1073741824).toFixed(0) + " GB", value: Monitor.diskTotal > 0 ? Monitor.diskUsed / Monitor.diskTotal : 0, hasValue: true,
                      right: Monitor.diskTotal > 0 ? (100 - 100 * Monitor.diskUsed / Monitor.diskTotal).toFixed(0) + qsTr("% libre") : "" } ] }
        Row {
            x: root.px(Theme.widgetPad); y: root.px(20); spacing: root.px(8)
            Icon { name: "power-profile-performance-symbolic"; size: root.px(18); color: Theme.label; anchors.verticalCenter: parent.verticalCenter }
            Label { text: appW.info.title; font.pixelSize: root.px(Theme.widgetTitlePx); font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
        }
        Repeater {
            model: appW.info.rows
            delegate: Item {
                required property var modelData
                required property int index
                x: root.px(Theme.widgetPad); y: root.px(50 + index * 34); width: parent.width - 2 * root.px(Theme.widgetPad); height: root.px(30)
                Row {
                    spacing: root.px(4)
                    Label { text: modelData.label; font.weight: Font.DemiBold; font.pixelSize: root.px(Theme.widgetSmallPx) }
                    Label { visible: modelData.detail !== ""; text: "·  " + modelData.detail; color: Theme.labelSecondary; font.pixelSize: root.px(Theme.widgetSmallPx) }
                }
                Label { anchors.right: parent.right; text: modelData.right; font.weight: Font.DemiBold; font.pixelSize: root.px(Theme.widgetSmallPx) }
                Rectangle {
                    visible: modelData.hasValue; y: root.px(19); width: parent.width; height: root.px(4); radius: height / 2; color: Qt.rgba(1, 1, 1, 0.16)
                    Rectangle { width: parent.width * Math.max(0, Math.min(1, modelData.value)); height: parent.height; radius: parent.radius; color: Theme.label
                                Behavior on width { NumberAnimation { duration: Theme.d(300) } } }
                }
            }
        }
    }

    // ---- 3. Recordatorios ---------------------------------------------------------------------
    Widget {
        id: remW
        wid: "recordatorios"; order: 2
        property bool adding: false
        Label { x: root.px(Theme.widgetPad); y: root.px(16); text: Reminders.pending; font.pixelSize: root.px(Theme.reminderCountPx); font.weight: Font.Bold }
        Label { x: root.px(Theme.widgetPad); y: root.px(50); text: qsTr("Recordatorios"); font.pixelSize: root.px(Theme.widgetTitlePx - 1); font.weight: Font.Bold }
        // Botón circular de lista: añadir un recordatorio
        Rectangle {
            id: listBtn
            x: parent.width - root.px(Theme.widgetPad) - width; y: root.px(26)
            width: root.px(34); height: width; radius: width / 2; color: lbMa.containsMouse ? Theme.fillHover : Theme.fill
            Icon { anchors.centerIn: parent; name: remW.adding ? "window-close-symbolic" : "view-list-symbolic"; size: root.px(16); color: Theme.label }
            MouseArea { id: lbMa; anchors.fill: parent; hoverEnabled: true; onClicked: { remW.adding = !remW.adding; if (remW.adding) input.forceActiveFocus() } }
        }
        Rectangle { x: root.px(Theme.widgetPad); y: root.px(82); width: parent.width - 2 * root.px(Theme.widgetPad); height: 1; color: Theme.separator }
        Column {
            x: root.px(Theme.widgetPad); y: root.px(90); width: parent.width - 2 * root.px(Theme.widgetPad)
            Item {
                visible: remW.adding; width: parent.width; height: root.px(Theme.reminderRowH)
                Rectangle { x: root.px(10) - width / 2 + root.px(0); anchors.verticalCenter: parent.verticalCenter; width: root.px(Theme.reminderCircle); height: width; radius: width / 2
                            color: "transparent"; border.width: 1.5; border.color: Theme.labelTertiary }
                TextInput {
                    id: input; x: root.px(32); anchors.verticalCenter: parent.verticalCenter; width: parent.width - x
                    color: Theme.label; font.family: Theme.font; font.pixelSize: root.px(13); clip: true
                    Text { visible: !parent.text; text: qsTr("Nuevo recordatorio"); color: Theme.labelTertiary; font: parent.font }
                    onAccepted: { Reminders.add(text); text = ""; remW.adding = false }
                    Keys.onEscapePressed: { text = ""; remW.adding = false }
                }
            }
            Repeater {
                model: Reminders.items.slice(0, remW.adding ? 6 : 7)
                delegate: Item {
                    required property var modelData
                    width: parent.width; height: root.px(Theme.reminderRowH)
                    Rectangle {
                        x: root.px(10) - width / 2; anchors.verticalCenter: parent.verticalCenter
                        width: root.px(Theme.reminderCircle); height: width; radius: width / 2
                        color: modelData.done ? Theme.selection : "transparent"; border.width: 1.5
                        border.color: modelData.done ? Theme.selection : Theme.labelTertiary
                        Text { anchors.centerIn: parent; visible: modelData.done; text: "✓"; color: "white"; font.pixelSize: root.px(11); font.weight: Font.Bold }
                        MouseArea { anchors.fill: parent; anchors.margins: -root.px(6); onClicked: { Reminders.toggle(modelData.id); purge.restart() } }
                    }
                    Label { x: root.px(32); anchors.verticalCenter: parent.verticalCenter; width: parent.width - x
                            text: modelData.title; font.pixelSize: root.px(13); color: modelData.done ? Theme.labelSecondary : Theme.label }
                }
            }
            Label { visible: Reminders.items.length === 0 && !remW.adding; topPadding: root.px(8); text: qsTr("Sin recordatorios"); color: Theme.labelSecondary; font.pixelSize: root.px(13) }
        }
        // Como en macOS, los completados desaparecen al poco
        Timer { id: purge; interval: 2500; onTriggered: Reminders.clearDone() }
    }
}
