import QtQuick
import QtQuick.Window
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
    readonly property var defaultApps: ["archivos", "lanzador", "navegador", "notas", "calculadora", "vista", "musica", "terminal", "monitor", "tienda", "ajustes"]
    readonly property var pinnedKinds: Settings.dockApps.length > 0 ? Settings.dockApps : defaultApps
    // Arrastre para reordenar (como macOS): los demás iconos se apartan al hueco; soltar muy arriba lo quita del Dock
    property int dragFrom: -1
    property int dragTo: -1
    property bool dragOut: false
    readonly property var kindNames: ({ archivos: qsTr("Archivos"), lanzador: qsTr("Aplicaciones"), navegador: qsTr("Firefox"),
                                        terminal: qsTr("Terminal"), tienda: qsTr("Tienda"), ajustes: qsTr("Ajustes del Sistema"),
                                        monitor: qsTr("Monitor de Actividad"), musica: qsTr("Música"), notas: qsTr("Notas"),
                                        calculadora: qsTr("Calculadora"), vista: qsTr("Vista previa") })
    function appIdOf(kind) {
        if (kind.indexOf("app:") === 0) return kind.substring(4)
        if (kind === "terminal") return "bc-terminal"
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
        return out.concat(recents)
    }
    readonly property int recentStart: items.length - recents.length
    // Apps recientes (como «Mostrar apps sugeridas y recientes en el Dock» de macOS): las 3 últimas no fijadas
    property var _seenIds: []
    Connections {
        target: Sway
        function onWindowsChanged() {
            if (!Settings.dockShowRecent) return
            const pinnedIds = dock.pinnedKinds.map(k => dock.appIdOf(k))
            let rec = Settings.dockRecent.slice(), changed = false
            for (const w of Sway.windows) {
                if (!w.appId || pinnedIds.indexOf(w.appId) >= 0 || w.appId.indexOf("bc-") === 0) continue
                if (rec[0] !== w.appId) { rec = [w.appId].concat(rec.filter(x => x !== w.appId)).slice(0, 3); changed = true }
            }
            if (changed) Settings.dockRecent = rec
        }
    }
    readonly property var recents: !Settings.dockShowRecent ? [] : Settings.dockRecent.filter(id => Sway.appIds.indexOf(id) < 0).map(id => {
        const info = Apps.infoFor(id)
        return { key: "app:" + id, kind: "", appId: id, icon: info.iconPath || "", name: info.name || AppMenus.nameFor(id), pinned: false, recent: true }
    }).filter(r => r.icon !== "")
    readonly property var minimized: Sway.windows.filter(w => w.minimized)
    readonly property int nRight: minimized.length + 2            // minimizadas + Descargas + Papelera
    readonly property real sep2: recents.length > 0 ? sepW : 0      // separador de la sección de recientes
    readonly property real baseW: 2 * padX + (items.length + nRight) * (bs + gap) - gap + sepW + sep2
    readonly property real baseLeft: (width - baseW) / 2

    // Punto del menú contextual en coordenadas de pantalla (la superficie del Dock está pegada abajo):
    // centrado sobre el icono y justo encima, como en macOS
    function menuPoint(cell) {
        const p = cell.mapToItem(null, cell.width / 2, 0)
        return Qt.point(p.x - px(110), p.y + (UiState.sh - dock.height) - px(6))
    }

    // ---- Ampliación --------------------------------------------------------------------------
    property real hoverX: -1
    // Intensidad de la ampliación (0–1): sube rápido al entrar y baja suave al salir, como macOS
    property real mag: 0
    Behavior on mag { NumberAnimation { duration: Theme.dur(dock.mag > 0.5 ? 240 : 110); easing.type: Easing.OutCubic } }
    // ¿El puntero sigue sobre el Dock? (HoverHandler pasivo: no lo «roban» los iconos)
    HoverHandler { id: dockHover }
    function pointerOnDock() {
        if (!dockHover.hovered) return false
        const p = dockHover.point.position, top = plateArea.y - (maxIcon - bs) - px(10)
        return p.x >= plateArea.x - px(4) && p.x <= plateArea.x + plateArea.width + px(4) && p.y >= top
    }                                      // en coordenadas de la disposición base
    readonly property real range: px(Theme.dockMagnifyRange)
    function sizeAt(baseCenter) {
        if (hoverX < 0 || mag <= 0.001 || Theme.dockMagnify <= 0) return bs
        const t = Math.abs(hoverX - baseCenter) / range
        return t >= 1 ? bs : bs * (1 + Theme.dockMagnify * mag * Math.cos(t * Math.PI / 2))
    }
    function sepBefore(i) { return (i >= items.length ? sepW : 0) + (recents.length > 0 && i >= recentStart ? sep2 : 0) }
    function baseCenter(i) { return padX + i * (bs + gap) + bs / 2 + sepBefore(i) }
    // Anchos reales con ampliación: la placa crece hacia ambos lados manteniendo el centro bajo el puntero
    readonly property var sizes: { const a = []; const n = items.length + nRight; for (let i = 0; i < n; ++i) a.push(sizeAt(baseCenter(i))); return a }
    readonly property real realW: { let w = 2 * padX + sepW + sep2 - gap; for (const v of sizes) w += v + gap; return w }
    function realX(i) { let x = padX; for (let k = 0; k < i; ++k) x += sizes[k] + gap; return x + sepBefore(i) }

    // ---- Ocultación automática ---------------------------------------------------------------
    property bool revealed: !Settings.dockAutohide || hot.containsMouse || plateMa.containsMouse || UiState.dockMenuOpen
    property real hideShift: revealed ? 0 : plateH + px(Theme.dockBottom) + px(4)
    Behavior on hideShift { NumberAnimation { duration: Theme.d(Theme.durDockHide); easing.type: Theme.easeStandard } }
    MouseArea { id: hot; anchors.bottom: parent.bottom; width: parent.width; height: px(3); hoverEnabled: true; visible: Settings.dockAutohide }

    // Zona que recibe el puntero (el resto deja pasar los clics a las ventanas)
    readonly property rect inputRect: Settings.dockAutohide && !revealed
        ? Qt.rect(0, height - px(3), width, px(3))
        : Qt.rect((width - realW) / 2, height - plateH - px(Theme.dockBottom) - (mag > 0 ? maxIcon - bs + px(30) : 0), realW, plateH + px(Theme.dockBottom) + (mag > 0 ? maxIcon - bs + px(30) : 0))
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
            onPositionChanged: (m) => { hoverOff.stop(); dock.hoverX = m.x + plateArea.x - dock.baseLeft; dock.mag = 1 }
            // Al pasar a un icono, su MouseArea se queda el puntero y esta «sale»: solo se apaga si de verdad salió del Dock
            onExited: hoverOff.restart()
        }
        // Al salir del Dock la ampliación se desvanece (no salta); si el puntero sigue encima, se comprueba de nuevo
        Timer { id: hoverOff; interval: 60; onTriggered: if (!dock.pointerOnDock()) dock.mag = 0; else restart() }
        // Separador vertical fino
        Rectangle {
            x: dock.realX(dock.items.length) - dock.sepW + px(Theme.dockSeparatorGap) - dock.gap / 2
            anchors.verticalCenter: parent.verticalCenter
            width: px(Theme.dockSeparatorW); height: dock.bs * 0.8; color: Theme.separator
        }

        // Separador de recientes
        Rectangle {
            visible: dock.recents.length > 0
            x: dock.realX(dock.recentStart) - dock.sep2 + px(Theme.dockSeparatorGap) - dock.gap / 2
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
                running: modelData.kind !== "" ? dock.isRunning(modelData.kind) : Sway.appIds.indexOf(modelData.appId) >= 0
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
                kind: modelData.appId.indexOf("bc-") === 0 ? ({ "bc-files": "archivos", "bc-settings": "ajustes", "bc-monitor": "monitor", "bc-store": "tienda", "bc-notes": "notas", "bc-calculator": "calculadora", "bc-preview": "vista", "bc-music": "musica" })[modelData.appId] || "" : ""
                icon: info.iconPath || ""; name: modelData.title; minimizedWindow: true
                thumb: UiState.minShots[modelData.id] || ""
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
            // Posición en pantalla para soltar archivos del escritorio encima (el Dock está abajo y centrado)
            readonly property var winRef: Window.window
            function pub() { const p = mapToItem(null, 0, 0); const w = Window.window
                             if (w) UiState.trashRect = Qt.rect(p.x + (w.originX || 0), p.y + (w.originY || 0), width, height) }
            onXChanged: pub(); onWidthChanged: pub()
            Component.onCompleted: pub()
            scale: UiState.trashHover ? 1.18 : 1
            Behavior on scale { NumberAnimation { duration: Theme.d(140) } }
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
        property string thumb: ""
        property bool dragEnabled: false
        signal activated()
        signal context(point p)
        signal dropped(real dx)
        readonly property real sz: dock.sizes[cellIndex] || dock.bs
        readonly property real shift: {
            if (dock.dragFrom < 0 || cellIndex === dock.dragFrom || !dragEnabled) return 0
            const f = dock.dragFrom, t = dock.dragTo, step = dock.bs + dock.gap
            if (f < t && cellIndex > f && cellIndex <= t) return -step
            if (f > t && cellIndex >= t && cellIndex < f) return step
            return 0
        }
        property real shiftA: shift
        Behavior on shiftA { NumberAnimation { duration: Theme.d(200); easing.type: Easing.OutCubic } }
        x: dock.realX(cellIndex) + dragDx + shiftA
        // Las ventanas minimizadas entran creciendo (no aparecen de golpe)
        property real grow: minimizedWindow ? 0 : 1
        Component.onCompleted: if (minimizedWindow) growIn.start()
        NumberAnimation { id: growIn; target: cell; property: "grow"; to: 1; duration: Theme.d(320); easing.type: Easing.OutBack }
        scale: grow; opacity: 0.4 + 0.6 * grow; transformOrigin: Item.Bottom
        width: sz; height: dock.plateH
        property real jump: 0
        property real dragDx: 0
        property real dragDy: 0
        z: ma.dragging ? 10 : 0
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
            anchors.bottom: parent.bottom; anchors.bottomMargin: dock.padY + cell.jump - cell.dragDy
            opacity: ma.dragging && dock.dragOut ? 0.45 : 1
            // Ventana minimizada: su miniatura real (captura) y el icono de la app pequeño en la esquina, como macOS
            Image { id: thumbImg; visible: cell.minimizedWindow && cell.thumb !== ""; anchors.fill: parent; anchors.margins: parent.width * 0.04
                    source: cell.thumb; fillMode: Image.PreserveAspectFit; smooth: true; mipmap: true; asynchronous: true
                    sourceSize.width: Math.round(dock.maxIcon * 2 * Screen.devicePixelRatio) }
            AppIcon { visible: cell.kind !== "" && !cell.stack && !thumbImg.visible; anchors.fill: parent; kind: cell.kind; size: cell.sz
                      full: cell.trash && trashModel.count > 0 }
            Image { visible: cell.kind === "" && !cell.stack && !thumbImg.visible; anchors.fill: parent; smooth: true; fillMode: Image.PreserveAspectFit
                    sourceSize: Qt.size(Math.ceil(dock.maxIcon * Screen.devicePixelRatio / 16) * 16, Math.ceil(dock.maxIcon * Screen.devicePixelRatio / 16) * 16); mipmap: true
                    source: cell.icon !== "" ? "file://" + cell.icon : (Quick.iconPath("application-x-executable") !== "" ? "file://" + Quick.iconPath("application-x-executable") : "qrc:/BCShell/apps/text-x-script.svg") }
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
            // Icono de la app en la esquina de la miniatura
            Item {
                visible: thumbImg.visible
                anchors.right: parent.right; anchors.bottom: parent.bottom; width: parent.width * 0.42; height: width
                AppIcon { visible: cell.kind !== ""; anchors.fill: parent; kind: cell.kind; size: parent.width }
                Image { visible: cell.kind === ""; anchors.fill: parent; smooth: true; mipmap: true; fillMode: Image.PreserveAspectFit
                        sourceSize: Qt.size(128, 128); source: cell.icon !== "" ? "file://" + cell.icon : "" }
            }
        }
        // Punto de app abierta
        Rectangle {
            visible: cell.running && !cell.stack && !cell.trash && !cell.minimizedWindow
            width: px(Theme.dockDot); height: width; radius: width / 2; color: Theme.label; opacity: 0.85
            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: px(Theme.dockDotY)
        }
        // Nombre sobre el icono al pasar (vidrio)
        Item {
            visible: ma.containsMouse && !ma.dragging
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
            property real startY: 0
            onPressed: (m) => { startX = m.x; startY = m.y; dragging = false }
            onPositionChanged: (m) => {
                // La ampliación sigue al puntero también encima de los iconos (antes solo en el fondo del Dock)
                if (!pressed) { hoverOff.stop(); dock.hoverX = cell.mapToItem(plateArea, m.x, 0).x + plateArea.x - dock.baseLeft; dock.mag = 1 }
                if (pressed && cell.dragEnabled && (dragging || Math.abs(m.x - startX) > px(8) || Math.abs(m.y - startY) > px(8))) {
                    dragging = true; cell.dragDx = m.x - startX; cell.dragDy = Math.min(0, m.y - startY)
                    dock.dragFrom = cell.cellIndex
                    dock.dragOut = m.y - startY < -dock.bs * 1.4
                    dock.dragTo = Math.max(0, Math.min(dock.pinnedKinds.length - 1, cell.cellIndex + Math.round(cell.dragDx / (dock.bs + dock.gap))))
                } }
            onContainsMouseChanged: if (!containsMouse) hoverOff.restart()
            onReleased: { if (dragging) { const out = dock.dragOut; dock.finishDrag(cell.cellIndex, out); cell.dragDx = 0; cell.dragDy = 0 } }
            onClicked: (m) => { if (dragging) return; if (m.button === Qt.RightButton) cell.context(dock.menuPoint(cell)); else cell.activated() }
            onPressAndHold: (m) => { if (!dragging) cell.context(dock.menuPoint(cell)) }
        }
        Behavior on dragDy { enabled: !ma.pressed; NumberAnimation { duration: Theme.d(180); easing.type: Theme.easeStandard } }
    }

    FileModel { id: trashModel; Component.onCompleted: openTrash() }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: trashModel.reload() }

    // ---- Reordenar y menú contextual ----------------------------------------------------------
    function finishDrag(from, out) {
        const list = pinnedKinds.slice()
        const to = dragTo
        dragFrom = -1; dragTo = -1; dragOut = false
        if (from < 0 || from >= list.length) return
        if (out) { list.splice(from, 1); Settings.dockApps = list; return }   // soltar fuera: quitar del Dock
        if (to < 0 || to === from) return
        const k = list.splice(from, 1)[0]
        list.splice(to, 0, k)
        Settings.dockApps = list
    }
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
        if (m.pinned) items.push({ label: qsTr("Quitar del Dock"), cmd: "bc:dock:unpin:" + m.key })
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
