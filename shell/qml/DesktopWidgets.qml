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
    // Solo si el widget «Uso del equipo» está puesto: antes leía todos los procesos cada 2 s aunque no se viera (tirones)
    Binding { target: Monitor; property: "active"; value: root.visible && root.isOn("app") && WidgetHost.widgets.length === 0 }

    // Posiciones guardadas { id: [x, y] } relativas a 1080p
    property var layout: { try { return JSON.parse(Settings.widgetLayout || "{}") } catch (e) { return {} } }
    function savePos(id, x, y) {
        const l = Object.assign({}, layout); l[id] = [Math.round(x / s), Math.round(y / s)]
        Settings.widgetLayout = JSON.stringify(l)
    }
    function resetLayout() { const l = {}; if (layout._activos) l._activos = layout._activos; Settings.widgetLayout = JSON.stringify(l) }
    function setOn(id, on) {
        const l = Object.assign({}, layout); let a = active.slice()
        if (on && a.indexOf(id) < 0) a.push(id)
        if (!on) { a = a.filter(x => x !== id); delete l[id] }
        l._activos = a; Settings.widgetLayout = JSON.stringify(l)
    }
    // Widgets activos (Editar widgets…): orden de la columna. Por defecto, los de la captura de referencia.
    readonly property var heights: ({ baterias: Theme.widgetLargeH, app: Theme.widgetMediumH, recordatorios: Theme.widgetMediumH,
                                      calendario: Theme.widgetSmall, reloj: Theme.widgetSmall })
    readonly property var smalls: ["calendario", "reloj"]
    // Sin baterías (máquina virtual, sobremesa) el widget de baterías no aparece: en su lugar, calendario y reloj
    readonly property bool hayBaterias: Batteries.devices.length > 0
    readonly property var active: (layout._activos || (hayBaterias ? ["baterias", "app", "recordatorios"] : ["calendario", "reloj", "recordatorios"]))
                                  .filter(k => k !== "baterias" || hayBaterias)
    function isOn(id) { return active.indexOf(id) >= 0 }
    // Colocación por defecto: de arriba abajo; si no cabe, columna siguiente (como el escritorio de macOS)
    function defPos(id) {
        // Como macOS: los pequeños (164×164) van de dos en dos en una fila; medianos y grandes ocupan el ancho
        let x = Theme.widgetX, y = Theme.widgetY, rowY = y, half = false
        const maxY = UiState.sh / s - Theme.dockIcon - 40
        for (const k of active) {
            const h = heights[k] || Theme.widgetMediumH, small = smalls.indexOf(k) >= 0
            if (small && half) {
                if (k === id) return Qt.point(px(x + Theme.widgetSmall + Theme.widgetGap), px(rowY))
                half = false; y = rowY + h + Theme.widgetGap; continue
            }
            if (half) { half = false; y = rowY + Theme.widgetSmall + Theme.widgetGap }
            if (y + h > maxY && y > Theme.widgetY) { x += Theme.widgetW + Theme.widgetGap; y = Theme.widgetY }
            if (k === id) return Qt.point(px(x), px(y))
            if (small) { half = true; rowY = y } else y += h + Theme.widgetGap
        }
        return Qt.point(px(Theme.widgetX), px(Theme.widgetY))
    }
    function defY(i) { return defPos(active[i] || "").y }

    // ---- Contenedor arrastrable --------------------------------------------------------------
    component Widget: Item {
        id: w
        property string wid
        property int order: 0
        property real baseH: root.heights[wid] || Theme.widgetMediumH
        property real baseW: Theme.widgetW
        default property alias content: inner.data
        width: root.px(baseW); height: root.px(baseH)
        visible: root.isOn(wid)
        x: root.layout[wid] ? root.layout[wid][0] * root.s : root.defPos(wid).x
        y: root.layout[wid] ? root.layout[wid][1] * root.s : root.defPos(wid).y
        Glass { anchors.fill: parent; radius: root.px(Theme.widgetRadius); tintBoost: 0.18 }
        Item { id: inner; anchors.fill: parent }
        // Arrastrar desde cualquier zona sin controles (como en macOS: se coge el widget entero)
        MouseArea {
            anchors.fill: parent; z: -1
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            drag.target: w; drag.threshold: 6
            drag.minimumX: 0; drag.maximumX: UiState.sw - w.width
            drag.minimumY: UiState.topInset; drag.maximumY: UiState.sh - w.height
            onReleased: if (drag.active || w.x !== (root.layout[w.wid] ? root.layout[w.wid][0] * root.s : root.defPos(w.wid).x)) root.savePos(w.wid, w.x, w.y)
            onClicked: (m) => { if (m.button === Qt.RightButton) UiState.openContextMenu([
                { label: qsTr("Editar widgets…"), cmd: "bc:widgetGallery" },
                { label: qsTr("Eliminar widget"), cmd: "bc:widgetOff:" + w.wid }, { sep: true },
                { label: qsTr("Volver a colocar los widgets"), cmd: "bc:widgetsReset" },
                { label: qsTr("Ocultar widgets"), cmd: "bc:toggleWidgets" } ], w.mapToItem(null, m.x, m.y)) }
        }
        Behavior on x { enabled: !Theme.reduced; NumberAnimation { duration: Theme.d(Theme.durPopover); easing.type: Theme.easeStandard } }
        Behavior on y { enabled: !Theme.reduced; NumberAnimation { duration: Theme.d(Theme.durPopover); easing.type: Theme.easeStandard } }
    }
    Connections { target: UiState; function onCommand(kind, arg) {
        if (kind !== "bc") return
        if (arg === "widgetsReset") root.resetLayout()
        else if (arg.indexOf("widgetOff:") === 0) root.setOn(arg.substring(10), false)
        else if (arg.indexOf("widgetOn:") === 0) root.setOn(arg.substring(9), true) } }

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
                                Behavior on width { NumberAnimation { duration: Theme.d(220) } } }
                }
            }
        }
    }

    // ---- 3. Recordatorios ---------------------------------------------------------------------
    Widget {
        id: remW
        wid: "recordatorios"; order: 2
        property bool adding: false
        // Filas que caben (si no caben todas, se deja sitio para «y N más»)
        readonly property real rowsSpace: height - root.px(92) - root.px(6) - (adding ? root.px(Theme.reminderRowH) : 0)
        readonly property int fitAll: Math.max(0, Math.floor(rowsSpace / root.px(Theme.reminderRowH)))
        readonly property int shown: Reminders.items.length <= fitAll ? Reminders.items.length
                                     : Math.max(0, Math.floor((rowsSpace - root.px(16)) / root.px(Theme.reminderRowH)))
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
        Text {
            readonly property int more: Reminders.items.length - remW.shown
            visible: more > 0
            x: root.px(Theme.widgetPad) + root.px(32); y: remW.height - root.px(8) - height
            text: qsTr("y %1 más").arg(more); color: Theme.labelSecondary; font.family: Theme.font; font.pixelSize: root.px(12)
        }
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
                // Solo los que caben en el alto del widget (el resto: «y N más»), nunca se salen
                model: Reminders.items.slice(0, remW.shown)
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

    // ---- 4. Calendario (pequeño, 164×164, calcado del de macOS 27) ------------------------------
    Widget {
        id: calW
        wid: "calendario"; baseH: Theme.widgetSmall; baseW: Theme.widgetSmall
        property date now: new Date()
        Timer { interval: 60000; running: calW.visible; repeat: true; triggeredOnStart: true; onTriggered: calW.now = new Date() }
        readonly property int first: (new Date(now.getFullYear(), now.getMonth(), 1).getDay() + 6) % 7
        readonly property int days: new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate()
        readonly property real colW: root.px(19.4)
        Label { x: root.px(17); y: root.px(12); text: calW.now.toLocaleDateString(Qt.locale(AppConfig.language), "MMMM").toUpperCase()
                color: "#FF3B30"; font.pixelSize: root.px(11); font.weight: Font.Bold; font.letterSpacing: 0.2 }
        Grid {
            x: root.px(14); y: root.px(28); columns: 7; rowSpacing: root.px(0)
            Repeater { model: ["L", "M", "X", "J", "V", "S", "D"]
                Label { required property string modelData; required property int index; width: calW.colW; height: root.px(17.5); horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter; text: modelData; font.pixelSize: root.px(10.5); font.weight: Font.DemiBold
                        color: index >= 5 ? Theme.labelSecondary : Theme.label } }
            Repeater { model: 7 * 6
                Item { required property int index; readonly property int d: index - calW.first + 1
                       readonly property bool hoy: d === calW.now.getDate()
                       width: calW.colW; height: root.px(17.5)
                       Rectangle { visible: parent.hoy; anchors.centerIn: parent; width: root.px(17); height: width; radius: width / 2; color: "#FF3B30" }
                       Label { anchors.centerIn: parent; text: parent.d >= 1 && parent.d <= calW.days ? parent.d : ""
                               font.pixelSize: root.px(11.5); font.weight: Font.DemiBold
                               color: parent.hoy ? "white" : (index % 7 >= 5 ? Theme.labelSecondary : Theme.label) } } }
        }
    }
    // ---- 5. Reloj (pequeño) -------------------------------------------------------------------
    Widget {
        id: clockW
        wid: "reloj"; baseH: Theme.widgetSmall; baseW: Theme.widgetSmall
        property date now: new Date()
        Timer { interval: 60050 - (Date.now() % 60000); running: clockW.visible; repeat: true; triggeredOnStart: true; onTriggered: { clockW.now = new Date(); interval = 60050 - (Date.now() % 60000) } }   // al minuto (antes cada segundo)
        Label { x: root.px(17); y: root.px(14)
                text: { const s = clockW.now.toLocaleDateString(Qt.locale(AppConfig.language), "dddd"); return s.charAt(0).toUpperCase() + s.slice(1) }
                color: "#FF3B30"; font.pixelSize: root.px(13); font.weight: Font.DemiBold }
        Label { x: root.px(16); y: root.px(30); text: clockW.now.getDate(); font.pixelSize: root.px(40); font.weight: Font.Normal }
        Label { x: root.px(17); anchors.bottom: parent.bottom; anchors.bottomMargin: root.px(14)
                text: clockW.now.toLocaleTimeString(Qt.locale(AppConfig.language), "H:mm"); font.pixelSize: root.px(28); font.weight: Font.DemiBold }
    }
}
