import QtQuick
import BCShell

// Dock Golden Gate (captura): placa de vidrio centrada abajo, iconos uniformes, punto bajo las apps abiertas,
// separador fino y, tras él, ventanas minimizadas, pila de Descargas y Papelera.
// Ampliación por proximidad (coseno), rebote al abrir, reordenar arrastrando, menú contextual y ocultación automática.
Item {
    id: dock
    readonly property real s: Theme.s
    function px(v) { return Math.round(v * s) }
    readonly property real bs: px(Theme.dockIcon)                  // tamaño base del icono
    readonly property real gap: px(Theme.dockPitch - Theme.dockIcon)
    readonly property real padX: px(Theme.dockPadX)
    readonly property real padY: px(Theme.dockPadY)
    readonly property real plateH: bs + 2 * padY
    readonly property real sepW: px(Theme.dockSeparatorGap) * 2 + px(Theme.dockSeparatorW)
    readonly property real maxIcon: bs * (1 + Theme.dockMagnify)
    signal launch(string kind, string name)
    signal launchDesktop(string id, string name)

    // ---- Modelo ------------------------------------------------------------------------------
    readonly property var defaultApps: ["archivos", "lanzador", "navegador", "terminal", "tienda", "ajustes", "monitor"]
    readonly property var pinnedKinds: Settings.dockApps.length > 0 ? Settings.dockApps : defaultApps
    readonly property var kindNames: ({ archivos: qsTr("Archivos"), lanzador: qsTr("Aplicaciones"), navegador: qsTr("Firefox"),
                                        terminal: qsTr("Terminal"), tienda: qsTr("Tienda"), ajustes: qsTr("Ajustes del Sistema"),
                                        monitor: qsTr("Monitor de Actividad"), musica: qsTr("Música") })
    function appIdOf(kind) {
        if (kind.indexOf("app:") === 0) return kind.substring(4)
        if (kind === "terminal") return "com.mitchellh.ghostty"
        return Launcher.appIdFor(kind)
    }
    function isRunning(kind) {
        const ids = Sway.appIds
        if (kind === "terminal") return ids.indexOf("com.mitchellh.ghostty") >= 0 || ids.indexOf("Alacritty") >= 0 || ids.indexOf("foot") >= 0
        const id = appIdOf(kind)
        return id !== "" && ids.indexOf(id) >= 0
    }
    readonly property var items: {
        const out = [], seen = {}
        for (const k of pinnedKinds) {
            if (k.indexOf("app:") === 0) { const info = Apps.infoFor(k.substring(4)); out.push({ key: k, kind: "", appId: k.substring(4), icon: info.iconPath || "", name: info.name || k.substring(4), pinned: true }) }
            else out.push({ key: k, kind: k, appId: appIdOf(k), icon: "", name: kindNames[k] || k, pinned: true })
            seen[appIdOf(k)] = true
        }
        if (seen["com.mitchellh.ghostty"]) { seen["Alacritty"] = true; seen["foot"] = true }
        // Apps abiertas que no están en el Dock (como en macOS: a la derecha de las fijadas)
        for (const w of Sway.windows) {
            if (seen[w.appId] || w.appId === "") continue
            seen[w.appId] = true
            const info = Apps.infoFor(w.appId)
            out.push({ key: "app:" + w.appId, kind: "", appId: w.appId, icon: info.iconPath || "", name: info.name || AppMenus.nameFor(w.appId), pinned: false })
        }
        return out
    }
    readonly property var minimized: Sway.windows.filter(w => w.minimized)
    readonly property int nRight: minimized.length + 2            // minimizadas + Descargas + Papelera
    readonly property real baseW: 2 * padX + (items.length + nRight) * (bs + gap) - gap + sepW
    readonly property real baseLeft: (width - baseW) / 2

    // ---- Ampliación --------------------------------------------------------------------------
    property real hoverX: -1                                      // en coordenadas de la disposición base
    readonly property real range: px(Theme.dockMagnifyRange)
    function sizeAt(baseCenter) {
        if (hoverX < 0 || Theme.dockMagnify <= 0) return bs
        const t = Math.abs(hoverX - baseCenter) / range
        return t >= 1 ? bs : bs * (1 + Theme.dockMagnify * Math.cos(t * Math.PI / 2))
    }
    function baseCenter(i) { return padX + i * (bs + gap) + bs / 2 + (i >= items.length ? sepW : 0) }
    // Anchos reales con ampliación: la placa crece hacia ambos lados manteniendo el centro bajo el puntero
    readonly property var sizes: { const a = []; const n = items.length + nRight; for (let i = 0; i < n; ++i) a.push(sizeAt(baseCenter(i))); return a }
    readonly property real realW: { let w = 2 * padX + sepW - gap; for (const v of sizes) w += v + gap; return w }
    function realX(i) { let x = padX; for (let k = 0; k < i; ++k) x += sizes[k] + gap; return x + (i >= items.length ? sepW : 0) }

    // ---- Ocultación automática ---------------------------------------------------------------
    property bool revealed: !Settings.dockAutohide || hot.containsMouse || plateMa.containsMouse || UiState.dockMenuOpen
    property real hideShift: revealed ? 0 : plateH + px(Theme.dockBottom) + px(4)
    Behavior on hideShift { NumberAnimation { duration: Theme.d(Theme.durDockHide); easing.type: Theme.easeStandard } }
    MouseArea { id: hot; anchors.bottom: parent.bottom; width: parent.width; height: px(3); hoverEnabled: true; visible: Settings.dockAutohide }

    // Zona que recibe el puntero (el resto deja pasar los clics a las ventanas)
    readonly property rect inputRect: Settings.dockAutohide && !revealed
        ? Qt.rect(0, height - px(3), width, px(3))
        : Qt.rect((width - realW) / 2, height - plateH - px(Theme.dockBottom) - (hoverX >= 0 ? maxIcon - bs + px(30) : 0), realW, plateH + px(Theme.dockBottom) + (hoverX >= 0 ? maxIcon - bs + px(30) : 0))
    // Punto de destino del «genio» al minimizar (centro del primer hueco de minimizadas)
    readonly property point minimizeTarget: Qt.point((width - baseW) / 2 + baseCenter(items.length + minimized.length), height - plateH / 2 - px(Theme.dockBottom))

    Item {
        id: plateArea
        width: dock.realW; height: dock.plateH
        x: (dock.width - width) / 2
        y: dock.height - height - px(Theme.dockBottom) + dock.hideShift

        Glass { anchors.fill: parent; radius: px(Theme.dockRadius); tintBoost: 0.05 }
        MouseArea {
            id: plateMa
            anchors.fill: parent; anchors.topMargin: -(dock.maxIcon - dock.bs)
            hoverEnabled: true; acceptedButtons: Qt.NoButton
            onPositionChanged: (m) => dock.hoverX = m.x + plateArea.x - dock.baseLeft
            onExited: dock.hoverX = -1
        }
        // Separador vertical fino
        Rectangle {
            x: dock.realX(dock.items.length) - dock.sepW + px(Theme.dockSeparatorGap) - dock.gap / 2
            anchors.verticalCenter: parent.verticalCenter
            width: px(Theme.dockSeparatorW); height: dock.bs * 0.8; color: Theme.separator
        }

        // Apps
        Repeater {
            model: dock.items
            delegate: DockCell {
                required property var modelData
                required property int index
                cellIndex: index
                kind: modelData.kind; icon: modelData.icon; name: modelData.name
                running: modelData.kind !== "" ? dock.isRunning(modelData.kind) : true
                onActivated: {
                    if (modelData.kind === "lanzador") { UiState.toggleLaunchpad(); return }
                    if (!running) bounce()
                    if (modelData.kind !== "") dock.launch(modelData.kind, modelData.name)
                    else if (!Sway.focusApp(modelData.appId)) { const i = Apps.infoFor(modelData.appId); if (i.id) dock.launchDesktop(i.id, modelData.name) }
                }
                onContext: (p) => UiState.openContextMenu(dock.appMenu(modelData, running), p)
                dragEnabled: modelData.pinned
                onDropped: (dx) => dock.reorder(index, dx)
            }
        }
        // Minimizadas (miniatura = icono de la app con marca de ventana)
        Repeater {
            model: dock.minimized
            delegate: DockCell {
                required property var modelData
                required property int index
                cellIndex: dock.items.length + index
                readonly property var info: Apps.infoFor(modelData.appId)
                kind: modelData.appId.indexOf("bc-") === 0 ? ({ "bc-files": "archivos", "bc-settings": "ajustes", "bc-monitor": "monitor", "bc-store": "tienda" })[modelData.appId] || "" : ""
                icon: info.iconPath || ""; name: modelData.title; minimizedWindow: true
                onActivated: UiState.run("bc:restore:" + modelData.id)
            }
        }
        // Pila de Descargas
        DockCell {
            cellIndex: dock.items.length + dock.minimized.length
            stack: true; name: qsTr("Descargas")
            onActivated: UiState.toggleStack()
            onContext: (p) => UiState.openContextMenu([{ label: qsTr("Abrir Descargas"), cmd: "sway:exec bc-shell --app files --open " + Files.placePath("downloads") }], p)
        }
        // Papelera
        DockCell {
            cellIndex: dock.items.length + dock.minimized.length + 1
            kind: "papelera"; name: qsTr("Papelera"); trash: true
            onActivated: dock.launch("papelera", qsTr("Papelera"))
            onContext: (p) => UiState.openContextMenu([{ label: qsTr("Abrir"), cmd: "bc:trash:open" }, { label: qsTr("Vaciar papelera…"), cmd: "bc:trash:empty" }], p)
        }
    }

    // ---- Celda ------------------------------------------------------------------------------
    component DockCell: Item {
        id: cell
        property int cellIndex: 0
        property string kind: ""
        property string icon: ""
        property string name: ""
        property bool running: false
        property bool stack: false
        property bool trash: false
        property bool minimizedWindow: false
        property bool dragEnabled: false
        signal activated()
        signal context(point p)
        signal dropped(real dx)
        readonly property real sz: dock.sizes[cellIndex] || dock.bs
        x: dock.realX(cellIndex) + dragDx
        width: sz; height: dock.plateH
        property real jump: 0
        property real dragDx: 0
        z: ma.drag.active ? 10 : 0
        function bounce() { if (!Theme.reduced) bounceAnim.restart() }
        SequentialAnimation {
            id: bounceAnim
            loops: Theme.dockBounces
            NumberAnimation { target: cell; property: "jump"; to: dock.bs * 0.55; duration: Theme.durDockBounceUp; easing.type: Easing.OutQuad }
            NumberAnimation { target: cell; property: "jump"; to: 0; duration: Theme.durDockBounceDown * 0.6; easing.type: Easing.OutBounce }
        }
        Item {
            id: art
            width: cell.sz; height: cell.sz
            anchors.bottom: parent.bottom; anchors.bottomMargin: dock.padY + cell.jump
            AppIcon { visible: cell.kind !== "" && !cell.stack; anchors.fill: parent; kind: cell.kind; size: cell.sz
                      full: cell.trash && trashModel.count > 0 }
            Image { visible: cell.kind === "" && !cell.stack; anchors.fill: parent; smooth: true; fillMode: Image.PreserveAspectFit
                    sourceSize: Qt.size(dock.maxIcon * 2, dock.maxIcon * 2)
                    source: cell.icon !== "" ? "file://" + cell.icon : "qrc:/BCShell/apps/system-file-manager.svg" }
            // Pila de documentos: tres hojas apiladas con el archivo más reciente arriba
            Item {
                visible: cell.stack; anchors.fill: parent
                Repeater {
                    model: 3
                    Rectangle {
                        required property int index
                        width: parent.width * 0.62; height: parent.height * 0.78; radius: px(3)
                        x: parent.width * 0.19 + (index - 1) * parent.width * 0.06; y: parent.height * 0.12 - index * px(1)
                        rotation: (index - 1) * 7
                        color: index === 2 ? "#F5F6F8" : (index === 1 ? "#DADDE3" : "#BFC4CC")
                        border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.15)
                        Column { visible: index === 2; x: parent.width * 0.15; y: parent.height * 0.18; spacing: parent.height * 0.09
                                 Repeater { model: 4; Rectangle { width: (index % 2 ? 0.5 : 0.7) * art.width * 0.62 * 0.8; height: px(1.5); color: "#9AA1AD" } } }
                    }
                }
            }
            // Marca de ventana minimizada
            Rectangle { visible: cell.minimizedWindow; anchors.right: parent.right; anchors.bottom: parent.bottom; width: parent.width * 0.38; height: width * 0.75
                        radius: px(3); color: Theme.windowBg; border.width: 1; border.color: Theme.glassRim }
        }
        // Punto de app abierta
        Rectangle {
            visible: cell.running && !cell.stack && !cell.trash && !cell.minimizedWindow
            width: px(Theme.dockDot); height: width; radius: width / 2; color: Theme.label; opacity: 0.85
            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: px(Theme.dockDotY)
        }
        // Nombre sobre el icono al pasar (vidrio)
        Item {
            visible: ma.containsMouse && !ma.drag.active
            anchors.horizontalCenter: art.horizontalCenter; y: art.y - height - px(10)
            width: lbl.implicitWidth + px(20); height: px(26)
            Glass { anchors.fill: parent; radius: height / 2; tintBoost: 0.4; shadow: false }
            Text { id: lbl; anchors.centerIn: parent; text: cell.name; color: Theme.label; font.family: Theme.font; font.pixelSize: px(13) }
        }
        MouseArea {
            id: ma
            anchors.fill: parent; anchors.topMargin: -(dock.maxIcon - dock.bs)
            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            property real startX: 0
            property bool dragging: false
            onPressed: (m) => { startX = m.x; dragging = false }
            onPositionChanged: (m) => { if (pressed && cell.dragEnabled && Math.abs(m.x - startX) > px(8)) { dragging = true; cell.dragDx = m.x - startX } }
            onReleased: { if (dragging) { cell.dropped(cell.dragDx); cell.dragDx = 0 } }
            onClicked: (m) => { if (dragging) return; if (m.button === Qt.RightButton) cell.context(cell.mapToItem(null, m.x, m.y)); else cell.activated() }
            onPressAndHold: (m) => { if (!dragging) cell.context(cell.mapToItem(null, m.x, m.y)) }
        }
        Behavior on dragDx { enabled: !ma.pressed; NumberAnimation { duration: Theme.d(180); easing.type: Theme.easeStandard } }
    }

    FileModel { id: trashModel; Component.onCompleted: openTrash() }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: trashModel.reload() }

    // ---- Reordenar y menú contextual ----------------------------------------------------------
    function reorder(from, dx) {
        const list = pinnedKinds.slice()
        if (from >= list.length) return
        const to = Math.max(0, Math.min(list.length - 1, from + Math.round(dx / (bs + gap))))
        if (to === from) return
        const k = list.splice(from, 1)[0]
        list.splice(to, 0, k)
        Settings.dockApps = list
    }
    function appMenu(m, running) {
        const items = []
        const ws = Sway.windows.filter(w => w.appId === m.appId)
        for (const w of ws) items.push({ label: w.title || m.name, cmd: "sway:exec swaymsg '[con_id=" + w.id + "]' focus" })
        if (ws.length) items.push({ sep: true })
        items.push({ label: qsTr("Opciones"), items: [
            m.pinned ? { label: qsTr("Quitar del Dock"), cmd: "bc:dock:unpin:" + m.key } : { label: qsTr("Mantener en el Dock"), cmd: "bc:dock:pin:" + m.key },
            { label: qsTr("Mostrar en Archivos"), cmd: "sway:exec bc-shell --app files --open /usr/share/applications" } ] })
        items.push({ sep: true })
        if (running) {
            items.push({ label: qsTr("Ocultar"), cmd: "sway:exec swaymsg '[app_id=\"" + m.appId + "\"]' move scratchpad" })
            items.push({ label: qsTr("Salir"), cmd: "sway:exec swaymsg '[app_id=\"" + m.appId + "\"]' kill" })
        } else items.push({ label: qsTr("Abrir"), cmd: "bc:dock:open:" + m.key })
        return items
    }
    Connections {
        target: UiState
        function onCommand(kind, arg) {
            if (kind !== "bc" || arg.indexOf("dock:") !== 0) return
            const parts = arg.split(":"), act = parts[1], key = parts.slice(2).join(":")
            const list = dock.pinnedKinds.slice()
            if (act === "unpin") { const i = list.indexOf(key); if (i >= 0) { list.splice(i, 1); Settings.dockApps = list } }
            else if (act === "pin") { if (list.indexOf(key) < 0) { list.push(key); Settings.dockApps = list } }
            else if (act === "open") { if (key.indexOf("app:") !== 0) dock.launch(key, dock.kindNames[key] || key) }
        }
    }
}
