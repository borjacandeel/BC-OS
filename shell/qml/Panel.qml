import QtQuick
import QtQuick.Window
import BCShell

// Panel de BC Shell: fondo, barra superior, Dock, notificaciones y capa de ventanas emergentes,
// cada uno como superficie wlr-layer-shell (el compositor es sway; las apps son procesos aparte).
LayerWindow {
    id: root
    // Capa «bottom» (encima del fondo de sway, debajo de las ventanas): al cambiar de fondo o de aspecto sway lanza
    // un swaybg nuevo en «background» que, si el escritorio estuviera ahí, taparía los widgets
    layer: "bottom"
    edges: ["top", "bottom", "left", "right"]
    scope: "bc-desktop"
    width: UiState.sw
    height: UiState.sh
    title: qsTr("BC Shell")
    keyboard: UiState.classic ? "none" : "ondemand"     // los widgets (recordatorios) aceptan texto
    onWidthChanged: if (width > 0) UiState.sw = width
    onHeightChanged: if (height > 0) UiState.sh = height

    readonly property real u: UiState.u
    readonly property int loadErrors: [bar, dockLoader, popLoader].filter(l => l.status === Loader.Error).length
    readonly property string notifTitle: qsTr("Actualizaciones")

    // Bajo sway el fondo lo pinta swaybg con la misma imagen (sin parpadeos); aquí solo en modo ventana (pruebas).
    Wallpaper { id: wall; anchors.fill: parent; visible: !Layer.supported
                source: Settings.wallpaper !== "" ? "file://" + Settings.wallpaper : "file:///usr/share/bc/wallpapers/dunas-noche.jpg" }
    Loader {
        id: brand
        scale: root.u
        transformOrigin: Item.BottomLeft
        x: Math.round(41 * root.u)
        y: root.height - height - Math.round(22 * root.u)
        visible: !Layer.supported && !wall.ready
        sourceComponent: Column {
            spacing: 22
            Brand { logoHeight: 31; withOs: true }
            Text { text: qsTr("LIGERO. POTENTE. FLUIDO."); color: Theme.white; font.family: Theme.fontMono
                   font.pixelSize: 16; font.letterSpacing: 3.6 }
        }
    }

    // Widgets (reloj, calendario, uso): columna derecha del fondo, bajo la barra superior
    // Golden Gate: widgets de escritorio a la izquierda (captura de referencia)
    DesktopIcons { visible: !UiState.classic }
    DesktopWidgets { visible: !UiState.classic && UiState.widgets }
    Widgets {
        visible: UiState.classic && UiState.widgets && !UiState.minimal
        scale: root.u
        transformOrigin: Item.TopRight
        x: root.width - Math.round(24 * root.u) - width
        y: UiState.topInset + Math.round(28 * root.u)
    }

    function launch(kind, name) {
        if (kind === "lanzador") { UiState.toggleLauncher(); return }
        const appId = Launcher.appIdFor(kind)
        if (kind === "papelera") {
            if (Sway.hasApp("bc-files")) { Shell.invokeApp("files", "trash"); Sway.focusApp("bc-files") }
            else Launcher.launch("archivos", "trash")
            return
        }
        if (Sway.focusApp(appId) || (kind === "terminal" && (Sway.focusApp("bc-terminal") || Sway.focusApp("com.mitchellh.ghostty") || Sway.focusApp("foot") || Sway.focusApp("Alacritty")))) return
        const r = Launcher.launch(kind)
        if (r === "failed") Notifications.push("BC OS", name, qsTr("No se pudo abrir la aplicación"), "", 4000)
    }
    // ---- Minimizar al Dock con efecto genio ----------------------------------------------------
    property var genieShots: ({})       // id de ventana → { path, rect }
    property var geniePending: null
    function minimizeGenie(id) {
        if (id === undefined || id < 0 || isNaN(id)) id = Sway.focusedId
        const w = Sway.windows.find(x => x.id === id)
        // Sin GPU (máquinas virtuales) sin genio: capturar la ventana y dibujar una capa a pantalla completa cuesta tanto
        // que VirtualBox enseñaba fotogramas a medias (cortes). Se minimiza al instante, como «Reducir movimiento».
        if (!w || UiState.classic || Theme.reduced || !Render.genie || w.rectW <= 0) { if (w) Sway.minimizeWindow(w.id); return }
        geniePending = { id: w.id, rect: Qt.rect(w.decoX, w.decoY, w.rectW, w.rectH), back: false }
        Quick.capture("genie-" + w.id, w.decoX + "," + w.decoY + " " + w.rectW + "x" + w.rectH)
    }
    // Abrir ventanas externas: aparecen con un fundido rápido (sway no escala ventanas; la opacidad sí)
    property var seenWins: null
    property var fading: ({})
    Connections {
        target: Sway
        function onWindowsChanged() {
            const now = {}
            for (const w of Sway.windows) now[w.id] = true
            if (root.seenWins !== null && !UiState.classic && !Theme.reduced)
                for (const w of Sway.windows)
                    if (!root.seenWins[w.id] && !(w.appId || "").startsWith("bc-")) root.fadeIn(w.id)
            root.seenWins = now
        }
    }
    function fadeIn(id) {
        if (Sway.hyprland) return   // Hyprland anima la apertura
        fading[id] = 0.35
        Sway.command("[con_id=" + id + "] opacity 0.35")
        fadeTick.start()
    }
    Timer {
        id: fadeTick; interval: 30; repeat: true
        onTriggered: {
            let any = false
            for (const k of Object.keys(root.fading)) {
                const v = Math.min(1, root.fading[k] + 0.13)
                Sway.command("[con_id=" + k + "] opacity " + v.toFixed(2))
                if (v >= 1) delete root.fading[k]; else { root.fading[k] = v; any = true }
            }
            if (!any) stop()
        }
    }
    // Cerrar con la animación de macOS: la ventana se encoge un poco y se desvanece (captura con grim)
    property var closePending: null
    function closeAnimated(id) {
        if (id === undefined || id < 0 || isNaN(id)) id = Sway.focusedId
        const w = Sway.windows.find(x => x.id === id)
        // Hyprland ya anima el cierre (encoger + desvanecer) en el compositor
        if (!w || Sway.hyprland || UiState.classic || Theme.reduced || !Render.genie || w.rectW <= 0 || w.minimized) { if (w) Sway.closeWindow(w.id); return }
        closePending = { id: w.id, rect: Qt.rect(w.decoX, w.decoY, w.rectW, w.rectH) }
        Quick.capture("close-" + w.id, w.decoX + "," + w.decoY + " " + w.rectW + "x" + w.rectH)
    }
    function restoreGenie(id) {
        const shot = genieShots[id]
        if (!shot || UiState.classic || Theme.reduced || !Render.genie) { Sway.command("[con_id=" + id + "] scratchpad show"); return }
        geniePending = { id: id, rect: shot.rect, back: true }
        fxBox(shot.rect, Qt.point(dockGG.minimizeTarget.x + dockWin.originX, dockGG.minimizeTarget.y + dockWin.originY), dockGG.bs)
        genieWin.shown = true
        genie.run("file://" + shot.path, shot.rect, Qt.point(dockGG.minimizeTarget.x + dockWin.originX, dockGG.minimizeTarget.y + dockWin.originY), dockGG.bs, true)
    }
    Connections {
        target: Quick
        function onCaptured(tag, path, ok) {
            if (tag.indexOf("close-") === 0 && root.closePending) {
                const cp = root.closePending; root.closePending = null
                if (!ok) { Sway.closeWindow(cp.id); return }
                closeLater.wid = cp.id; closeLater.restart()
                fxBox(cp.rect, null, 0)
                genieWin.shown = true
                closeShot.source = ""; closeShot.source = "file://" + path
                closeShot.x = cp.rect.x - genieWin.box.x; closeShot.y = cp.rect.y - genieWin.box.y; closeShot.width = cp.rect.width; closeShot.height = cp.rect.height
                closeAnim.restart()
                return
            }
            if (tag.indexOf("genie-") !== 0 || !root.geniePending) return
            const g = root.geniePending
            // La ventana se oculta cuando el genio ya está encima (Genie.began), no antes
            if (!ok) { Sway.minimizeWindow(g.id); root.geniePending = null; return }
            const s = Object.assign({}, root.genieShots); s[g.id] = { path: path, rect: g.rect }; root.genieShots = s
            const ms = Object.assign({}, UiState.minShots); ms[g.id] = "file://" + path; UiState.minShots = ms
            fxBox(g.rect, Qt.point(dockGG.minimizeTarget.x + dockWin.originX, dockGG.minimizeTarget.y + dockWin.originY), dockGG.bs)
            genieWin.shown = true
            genie.run("file://" + path, g.rect, Qt.point(dockGG.minimizeTarget.x + dockWin.originX, dockGG.minimizeTarget.y + dockWin.originY), dockGG.bs, false)
        }
    }
    // Superficie del genio/cierre del tamaño justo (de la ventana al icono del Dock), no a pantalla completa: mucho menos
    // que dibujar y componer en cada fotograma (el genio iba a tirones en equipos con poca GPU)
    function fxBox(r, tgt, icon) {
        const has = icon > 0
        const x0 = Math.max(0, Math.floor(Math.min(r.x, has ? tgt.x - icon : r.x)) - 6)
        const y0 = Math.max(0, Math.floor(r.y) - 6)
        const x1 = Math.min(UiState.sw, Math.ceil(Math.max(r.x + r.width, has ? tgt.x + icon : 0)) + 6)
        const y1 = Math.min(UiState.sh, Math.ceil(Math.max(r.y + r.height, has ? tgt.y + icon : 0)) + 6)
        genieWin.box = Qt.rect(x0, y0, Math.max(8, x1 - x0), Math.max(8, y1 - y0))
        genie.offset = Qt.point(x0, y0)
    }
    // Cerrar con animación: la ventana real se cierra cuando la captura ya la tapa (sin parpadeo)
    Timer { id: closeLater; interval: 70; property int wid: -1; onTriggered: Sway.closeWindow(wid) }
    LayerWindow {
        id: genieWin
        layer: "overlay"; edges: ["top", "left"]; scope: "bc-genie"; passthrough: true; absolute: true
        property rect box: Qt.rect(0, 0, UiState.sw, UiState.sh)
        onBoxChanged: if (ready) Qt.callLater(apply)
        margins: [box.y, 0, 0, box.x]
        width: box.width; height: box.height
        shown: false
        Image {
            id: closeShot; visible: closeAnim.running; smooth: true; cache: false
            transformOrigin: Item.Center
        }
        ParallelAnimation {
            id: closeAnim
            NumberAnimation { target: closeShot; property: "scale"; from: 1; to: 0.92; duration: Theme.d(Theme.durWindowClose); easing.type: Easing.InCubic }
            NumberAnimation { target: closeShot; property: "opacity"; from: 1; to: 0; duration: Theme.d(Theme.durWindowClose); easing.type: Easing.InQuad }
            onFinished: if (!genie.source) genieWin.shown = false
        }
        Genie {
            id: genie
            onBegan: { const g = root.geniePending; if (g && !g.back) Sway.minimizeWindow(g.id) }
            onFinished: {
                genieWin.shown = false
                const g = root.geniePending
                if (g && g.back) Sway.command("[con_id=" + g.id + "] scratchpad show")
                root.geniePending = null
            }
        }
    }

    // ---- Esquinas activas (como en macOS): llevar el puntero a una esquina lanza su acción -------------
    function hotCorner(a) {
        if (a === "mission") UiState.toggleMission()
        else if (a === "desktop") Shell.Action("desktop")
        else if (a === "launchpad") UiState.toggleLaunchpad()
        else if (a === "notifications") UiState.toggleNotifCenter()
        else if (a === "lock") UiState.run("bc:lock")
        else if (a === "notes") Launcher.launch("notas")
    }
    Instantiator {
        model: UiState.classic ? 0 : 4
        delegate: LayerWindow {
            required property int index
            readonly property string action: Settings.hotCorners[index] || ""
            layer: "overlay"; scope: "bc-hotcorner"
            edges: [index < 2 ? "top" : "bottom", index % 2 === 0 ? "left" : "right"]
            width: 2; height: 2
            shown: action !== "" && !UiState.locked && !UiState.splashing
            MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: hcDelay.restart(); onExited: hcDelay.stop() }
            Timer { id: hcDelay; interval: 120; onTriggered: root.hotCorner(parent.action) }
        }
    }

    // ---- Mission Control y selector de aplicaciones --------------------------------------------
    LayerWindow {
        layer: "overlay"; edges: ["top", "bottom", "left", "right"]; scope: "bc-mission"
        keyboard: UiState.missionOpen ? "exclusive" : "none"
        width: UiState.sw; height: UiState.sh
        shown: !UiState.classic && (UiState.missionOpen || mission.t > 0)
        MissionControl { id: mission }
    }
    LayerWindow {
        layer: "overlay"; scope: "bc-switcher"
        keyboard: UiState.switcherOpen ? "exclusive" : "none"
        width: switcher.width; height: switcher.height
        shown: UiState.switcherOpen
        AppSwitcher { id: switcher }
    }
    Connections {
        target: Shell
        function onActionRequested(name) {
            if (UiState.locked) return
            if (name === "spotlight") UiState.toggleSpotlight()
            else if (name === "mission") UiState.toggleMission()
            else if (name === "switcher") switcher.step(1)
            else if (name === "switcher-back") switcher.step(-1)
            else if (name === "launchpad") UiState.toggleLaunchpad()
            else if (name === "notifications") UiState.toggleNotifCenter()
            else if (name === "minimize") root.minimizeGenie(Sway.focusedId)
            else if (name === "close") root.closeAnimated(Sway.focusedId)
            else if (name === "forcequit") UiState.run("bc:forcequit")
            else if (name === "emoji") UiState.run("bc:emoji")
            else if (name === "screenshot") { const o = UiState.screenshotOpen; UiState.closePopups(); UiState.screenshotOpen = !o }
            else if (name === "recording-on") UiState.recording = true
            else if (name === "recording-off") UiState.recording = false
            else if (name.indexOf("thumb:") === 0) shotThumb.show(name.substring(6))
            else if (name === "appearance") Settings.appearance = Theme.dark ? "light" : "dark"
            else if (name === "desktop") {
                const vis = Sway.windows.filter(w => !w.minimized)
                if (vis.length) for (const w of vis) Sway.minimizeWindow(w.id)
                else for (const w of Sway.windows) Sway.command("[con_id=" + w.id + "] scratchpad show")
            }
        }
    }

    // Sonidos del sistema (originales de BC OS)
    Connections { target: UiState; function onLockedChanged() { Quick.setLockFlag(UiState.locked); if (UiState.locked && !UiState.classic) Sounds.play("lock") } }
    property bool _notifWas: false
    property bool notifLeaving: false
    property bool _notifWasShown: false
    property bool _soundsReady: false
    Timer { interval: 6000; running: true; onTriggered: root._soundsReady = true }   // sin sonido para los avisos del arranque
    Connections { target: Notifications; function onChanged() { if (Notifications.visible && !root._notifWas && !UiState.classic && root._soundsReady) Sounds.play("notify"); root._notifWas = Notifications.visible } }

    // Mover y redimensionar (menú Ventana y menú del botón verde): mitades, rellenar y centrar
    function tile(how) {
        const id = Sway.focusedId
        if (id < 0) return
        const top = UiState.topInset, bottom = Settings.dockAutohide ? 0 : dockWin.exclusive
        const W = UiState.sw, H = UiState.sh - top - bottom, g = Theme.px(8)
        let r
        if (how === "left") r = [g, top + g, W / 2 - 1.5 * g, H - 2 * g]
        else if (how === "right") r = [W / 2 + 0.5 * g, top + g, W / 2 - 1.5 * g, H - 2 * g]
        else if (how === "fill") r = [g, top + g, W - 2 * g, H - 2 * g]
        else if (how === "top") r = [g, top + g, W - 2 * g, H / 2 - 1.5 * g]
        else if (how === "bottom") r = [g, top + H / 2 + 0.5 * g, W - 2 * g, H / 2 - 1.5 * g]
        else if (how === "leftq") r = [g, top + g, W / 3 - 1.5 * g, H - 2 * g]
        else if (how === "rightq") r = [W / 3 + 0.5 * g, top + g, W * 2 / 3 - 1.5 * g, H - 2 * g]
        else r = [W * 0.15, top + H * 0.1, W * 0.7, H * 0.8]
        Sway.command("[con_id=" + id + "] floating enable, resize set " + Math.round(r[2]) + " " + Math.round(r[3]) + ", move absolute position " + Math.round(r[0]) + " " + Math.round(r[1]))
    }
    function runningKinds() {
        const ids = Sway.windows.map(w => w.appId), out = []
        for (const k of ["archivos", "ajustes", "monitor", "terminal", "tienda", "navegador"]) {
            const id = Launcher.appIdFor(k)
            if (ids.indexOf(id) >= 0 || (k === "terminal" && (ids.indexOf("bc-terminal") >= 0 || ids.indexOf("foot") >= 0 || ids.indexOf("com.mitchellh.ghostty") >= 0 || ids.indexOf("Alacritty") >= 0))) out.push(k)
        }
        return out
    }

    Connections {
        target: UiState
        function onCommand(kind, arg) {
            if (kind === "sway") {
                const id = Sway.focusedId
                Sway.command(arg.indexOf("exec ") === 0 || id < 0 ? arg : "[con_id=" + id + "] " + arg)
            } else if (kind === "app") {
                Shell.invokeApp(Sway.focusedAppId.replace(/^bc-/, ""), arg)
            } else if (kind === "bc") {
                if (arg === "tiling") Sway.toggleTiling()
                else if (arg === "appearance") Settings.appearance = Theme.dark ? "light" : "dark"
                else if (arg === "trash:open") root.launch("papelera", qsTr("Papelera"))
                else if (arg === "trash:empty") { if (Files.emptyTrash()) Sounds.play("trash") }
                else if (arg === "hideOthers") { for (const w of Sway.windows) if (!w.focused && !w.minimized) Sway.minimizeWindow(w.id) }
                else if (arg === "showAll") { for (const w of Sway.windows) if (w.minimized) Sway.command("[con_id=" + w.id + "] scratchpad show") }
                else if (arg.indexOf("tile:") === 0) root.tile(arg.substring(5))
                else if (arg.indexOf("minimize:") === 0) root.minimizeGenie(parseInt(arg.substring(9)))
                else if (arg.indexOf("close:") === 0) root.closeAnimated(parseInt(arg.substring(6)))
                else if (arg.indexOf("restore:") === 0) root.restoreGenie(parseInt(arg.substring(8)))
                else if (arg === "about") { if (UiState.classic) Notifications.push("BC OS", qsTr("BC OS"), qsTr("Versión alpha · ARM64"), "", 4000)
                                            else Launcher.run("bc-shell", ["--app", "settings", "--open", "about"]) }
            }
        }
    }
    Connections {
        target: Shell
        function onOptionChanged(key, value) {
            if (key === "widgets") UiState.widgets = value === "1"
            else if (key === "mode") UiState.mode = value === "-" ? "" : value
            else if (key === "accent") AppConfig.setAccent(value)
            else if (key === "wallpaper") {
                const p = value === "-" ? "/usr/share/bc/wallpapers/dunas-noche.jpg" : value
                if (/^[^"\\$;,\n'`]+$/.test(p)) Sway.command("output * bg \"" + p + "\" fill #04111F")
            }
        }
        function onStyleChanged(st) { UiState.closePopups(); UiState.style = st === "win" ? "win" : "mac" }
        function onOsdRequested(kind) { SystemStatus.refresh(); osdDelay.kind = kind; osdDelay.restart(); if (kind === "volume") Sounds.play("volume") }
        function onWelcomeRequested() { UiState.closePopups(); UiState.welcomeOpen = true }
        function onLauncherToggled() { UiState.toggleLauncher() }
        function onClipboardToggled() { UiState.toggleClipboard() }
        function onControlCenterToggled() { UiState.toggleCenter() }
        function onLockRequested() { UiState.run("bc:lock") }
        function onTilingToggled() { Sway.toggleTiling() }
        function onPowerRequested(a) { UiState.openPower(a) }
    }

    // Modos: Relajación / Concentración dejan «No molestar»; Noche y Relajación tiñen la pantalla de ámbar suave
    Connections {
        target: UiState
        function onModeChanged() { SystemStatus.dnd = UiState.mode === "focus" || UiState.mode === "relax" }
    }
    LayerWindow {
        layer: "overlay"; edges: ["top", "bottom", "left", "right"]; scope: "bc-tint"; passthrough: true
        width: UiState.sw; height: UiState.sh
        shown: (UiState.mode === "night" || UiState.mode === "relax") && !UiState.locked
        Rectangle { anchors.fill: parent; color: "#ff8a2a"; opacity: UiState.mode === "night" ? 0.16 : 0.07 }
    }

    Timer { id: osdDelay; property string kind: "volume"; interval: 180; onTriggered: if (!UiState.locked) { osdWin.shown = true; osd.show(kind) } }
    // OSD de volumen y brillo
    LayerWindow {
        id: osdWin
        // Golden Gate (desde Tahoe): el indicador de volumen/brillo es una píldora de vidrio arriba a la derecha
        layer: "overlay"; edges: UiState.classic ? ["bottom"] : ["top", "right"]
        margins: UiState.classic ? [0, 0, Math.round(110 * root.u), 0] : [UiState.barH + Theme.px(6), Theme.px(10), 0, 0]
        scope: "bc-osd"; passthrough: true
        width: UiState.classic ? Math.round(260 * root.u) : Theme.px(300); height: UiState.classic ? Math.round(64 * root.u) : Theme.px(56)
        shown: false
        Osd { id: osd; scale: UiState.classic ? root.u : 1; transformOrigin: Item.TopLeft; onHidden: osdWin.shown = false
              width: UiState.classic ? 260 : osdWin.width; height: UiState.classic ? 64 : osdWin.height }
    }
    Timer { id: demoQ; interval: 300; onTriggered: spotlightRef.setText("a") }
    property var spotlightRef: null
    // Ventana recién abierta = ventana activa (como macOS). Si se abría mientras un menú, Spotlight o Aplicaciones
    // aún tenían el teclado (su fundido de salida), el compositor devolvía el foco a la ventana anterior.
    property var _knownWins: null
    Connections {
        target: typeof Sway !== "undefined" ? Sway : null
        function onWindowsChanged() {
            const ids = {}, fresh = []
            for (const w of Sway.windows) { ids[w.id] = true; if (root._knownWins && !root._knownWins[w.id] && !w.minimized) fresh.push(w) }
            root._knownWins = ids
            // (con Hyprland lo hace SwayControl al recibir «openwindow», al instante; esto queda para sway)
            if (!Sway.hyprland && fresh.length && !fresh[fresh.length - 1].focused) newFocus.restartWith(fresh[fresh.length - 1].id)
        }
    }
    Timer { id: newFocus; interval: 120; property int wid: -1
            function restartWith(i) { wid = i; restart() }
            onTriggered: if (wid >= 0) Sway.focusWindow(wid) }
    // Resultado de conectarse a una red Wi-Fi (antes no se avisaba: si fallaba, no se sabía por qué)
    Connections {
        target: Quick
        function onWifiResult(ok, ssid) {
            if (ok) Notifications.push("BC OS", qsTr("Wi-Fi"), qsTr("Conectado a «%1»").arg(ssid), "", 4000)
            else Notifications.push("BC OS", qsTr("Wi-Fi"), qsTr("No se pudo conectar a «%1». Revisa la contraseña.").arg(ssid), "", 8000)
        }
    }
    property var ccRef: null
    Timer { id: welcomeTimer; interval: 700; onTriggered: if (!UiState.locked) UiState.welcomeOpen = true }

    // Botones de ventana para las apps que no son de BC
    WindowChrome { }

    // Barra superior
    LayerWindow {
        layer: "top"; edges: ["top", "left", "right"]; exclusive: UiState.barH; scope: "bc-topbar"
        width: UiState.sw; height: UiState.barH
        shown: !UiState.splashing && !UiState.win && !UiState.locked
        Loader { id: bar; anchors.fill: parent; source: UiState.classic ? "TopBar.qml" : "MenuBar.qml" }
    }

    // Pantallas adicionales (conexión en caliente): barra de menús y Dock propios en cada monitor
    Instantiator {
        model: UiState.classic || UiState.win ? 0 : UiState.otherScreens.length
        delegate: QtObject {
            required property int index
            readonly property var modelData: UiState.otherScreens[index]
            property LayerWindow bar2: LayerWindow {
                screen: modelData
                layer: "top"; edges: ["top", "left", "right"]; exclusive: UiState.barH; scope: "bc-topbar"
                width: modelData.width; height: UiState.barH
                shown: !UiState.splashing && !UiState.locked
                MenuBar { anchors.fill: parent }
            }
            property LayerWindow mission2: LayerWindow {
                screen: modelData
                layer: "overlay"; edges: ["top", "bottom", "left", "right"]; scope: "bc-mission"
                width: modelData.width; height: modelData.height
                shown: !UiState.classic && (UiState.missionOpen || mc2.t > 0)
                MissionControl { id: mc2; outName: modelData.name; origin: Qt.point(modelData.virtualX, modelData.virtualY) }
            }
            property LayerWindow dock2: LayerWindow {
                id: d2
                screen: modelData
                layer: "top"; edges: ["bottom", "left", "right"]; scope: "bc-dock"
                exclusive: Settings.dockAutohide ? 0 : Math.round(dk2.plateH + Theme.px(Theme.dockBottom) + Theme.px(4))
                width: modelData.width; height: Math.round(dk2.plateH + dk2.maxIcon - dk2.bs + Theme.px(60))
                inputRect: dk2.inputRect
                shown: !UiState.splashing && !UiState.locked && !UiState.missionOpen
                DockGG { id: dk2; anchors.fill: parent; onLaunch: (k, n) => root.launch(k, n)
                         onLaunchDesktop: (id, n) => { if (!Apps.launch(id)) Notifications.push("BC OS", n, qsTr("No se pudo abrir la aplicación"), "", 4000) } }
            }
        }
    }

    // Barra de tareas (estilo Windows)
    LayerWindow {
        layer: "top"; edges: ["bottom", "left", "right"]; exclusive: UiState.taskH; scope: "bc-taskbar"
        width: UiState.sw; height: UiState.taskH
        shown: UiState.win && !UiState.splashing && !UiState.locked
        Taskbar {
            anchors.fill: parent
            running: root.runningKinds()
            onLaunched: (k, n) => { if (k !== "lanzador") UiState.closePopups(); root.launch(k, n) }
        }
    }

    // Dock
    LayerWindow {
        layer: "top"; edges: ["bottom"]; margins: [0, 0, Math.round(22 * root.u), 0]; scope: "bc-dock"
        width: Math.round(dockLoader.width * root.u); height: Math.round(dockLoader.height * root.u)
        shown: UiState.classic && !UiState.splashing && !UiState.locked && !UiState.win && !UiState.minimal
        Loader {
            id: dockLoader
            source: "Dock.qml"
            scale: root.u
            transformOrigin: Item.TopLeft
            onLoaded: {
                item.launched.connect((k, n) => root.launch(k, n))
                item.running = Qt.binding(() => root.runningKinds())
            }
        }
    }

    // Dock Golden Gate: superficie a todo lo ancho (para ampliar sin recortes) que solo recibe el puntero en la placa
    LayerWindow {
        id: dockWin
        layer: "top"; edges: ["bottom", "left", "right"]; scope: "bc-dock"
        exclusive: Settings.dockAutohide ? 0 : Math.round(dockGG.plateH + Theme.px(Theme.dockBottom) + Theme.px(4))
        width: UiState.sw; height: Math.round(dockGG.plateH + dockGG.maxIcon - dockGG.bs + Theme.px(60))
        inputRect: dockGG.inputRect
        shown: !UiState.classic && !UiState.splashing && !UiState.locked && !UiState.win && !UiState.missionOpen
        DockGG {
            id: dockGG
            anchors.fill: parent
            onLaunch: (k, n) => root.launch(k, n)
            onLaunchDesktop: (id, n) => { if (!Apps.launch(id)) Notifications.push("BC OS", n, qsTr("No se pudo abrir la aplicación"), "", 4000) }
        }
    }

    // Miniatura flotante de captura (como macOS): entra deslizándose abajo a la derecha, 5 s, pulsar = Vista previa
    LayerWindow {
        id: shotThumb
        layer: "overlay"; edges: ["bottom", "right"]; margins: [0, 16, Math.round(16 * root.u), 0]; scope: "bc-captura"
        width: Math.round(220 * root.u) + 20; height: Math.round(140 * root.u) + 20
        property string path: ""
        property real t: 0
        shown: path !== "" && !UiState.locked
        function show(p) { path = ""; path = p; slide.restart(); hideT.restart() }
        NumberAnimation { id: slide; target: shotThumb; property: "t"; from: 0; to: 1; duration: Theme.d(240); easing.type: Easing.OutCubic }
        NumberAnimation { id: slideOut; target: shotThumb; property: "t"; to: 0; duration: Theme.d(260); easing.type: Easing.InCubic; onFinished: shotThumb.path = "" }
        Timer { id: hideT; interval: 5000; onTriggered: slideOut.start() }
        Item {
            x: 10 + (1 - shotThumb.t) * (shotThumb.width); y: 10; width: shotThumb.width - 20; height: shotThumb.height - 20
            opacity: shotThumb.t
            Rectangle { anchors.fill: parent; anchors.margins: -3; radius: 12; color: Qt.rgba(1, 1, 1, 0.85) }
            Image { anchors.fill: parent; source: shotThumb.path !== "" ? "file://" + shotThumb.path : ""; fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 440; asynchronous: true; smooth: true }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { hideT.stop(); Launcher.run("bc-shell", ["--app", "preview", "--open", shotThumb.path]); slideOut.start() } }
        }
    }

    // Notificación emergente
    LayerWindow {
        layer: "top"; edges: ["top", "right"]; margins: [UiState.topInset + Math.round(14 * root.u) - 16, Math.round(14 * root.u) - 20, 0, 0]; scope: "bc-notify"
        width: Math.round(321 * root.u) + 40; height: Math.round(80 * root.u) + 36
        shown: (Notifications.visible || root.notifLeaving) && !UiState.locked && !UiState.splashing && !UiState.centerOpen && !UiState.notifCenterOpen   // sin encimarse al Centro de control ni al de notificaciones
        // Margen alrededor de la tarjeta: la sombra y el brillo del cristal no se cortan en el borde de la superficie
        Item { x: 20; y: 16
        NotificationCard {
            id: notifCard
            // Deslizar hacia la derecha para descartar (como en macOS); si no llega, vuelve a su sitio
            DragHandler {
                id: notifDrag; target: notifCard; yAxis.enabled: false; xAxis.minimum: 0; xAxis.maximum: notifCard.width
                onActiveChanged: if (!active) { if (notifCard.x > notifCard.width * 0.3) Notifications.dismiss(); else notifBack.restart() }
            }
            NumberAnimation on x { id: notifBack; running: false; to: 0; duration: Theme.dur(220); easing.type: Easing.OutCubic }
            scale: root.u
            transformOrigin: Item.TopLeft
            title: Notifications.title
            body: Notifications.body
            onDismissed: Notifications.dismiss()
        }
        }
        // La tarjeta vive en su propia superficie (siempre «visible»): la entrada se dispara con cada aviso
        Connections { target: Notifications; function onChanged() {
            if (Notifications.visible && !root._notifWasShown) { notifLeave.stop(); root.notifLeaving = false; notifCard.x = 0; notifCard.opacity = 1; notifSlide.play() }
            // Al irse (tiempo, cerrar o deslizar) sale hacia la derecha desvaneciéndose, en vez de desaparecer de golpe
            else if (!Notifications.visible && root._notifWasShown && !Theme.reducedMotion) { root.notifLeaving = true; notifLeave.restart() }
            root._notifWasShown = Notifications.visible } }
        ParallelAnimation {
            id: notifLeave
            NumberAnimation { target: notifCard; property: "x"; to: notifCard.width + 24; duration: Theme.durNotifyOut; easing.type: Easing.InCubic }
            NumberAnimation { target: notifCard; property: "opacity"; to: 0; duration: Theme.durNotifyOut; easing.type: Easing.InQuad }
            onFinished: { root.notifLeaving = false; notifCard.x = 0; notifCard.opacity = 1 }
        }
        SlideIn { id: notifSlide; target: notifCard; dx: UiState.classic ? 60 : 340; dy: 0; duration: UiState.classic ? 260 : Theme.durNotifyIn }   // Golden Gate: entra desde fuera por la derecha
    }

    // Pantalla completa (sin márgenes): bienvenida, bloqueo y pantalla de carga
    LayerWindow {
        layer: "overlay"; edges: ["top", "bottom", "left", "right"]; scope: "bc-full"
        keyboard: UiState.locked || UiState.welcomeOpen ? "exclusive" : "none"
        width: UiState.sw; height: UiState.sh
        shown: UiState.welcomeOpen || UiState.locked || UiState.splashing
        Item {
            anchors.fill: parent
            Welcome {
                id: welcomeView
                anchors.fill: parent
                visible: UiState.welcomeOpen
                onVisibleChanged: if (visible) { step = AppConfig.demo === "bienvenida-fondo" ? 2 : 0; forceActiveFocus() }
                onFinished: UiState.welcomeOpen = false
            }
            LockScreen { active: UiState.locked; onUnlocked: UiState.locked = false }
            Splash { }
        }
    }

    // Capa emergente: Centro de control, menús, lanzador, apagado, bloqueo y pantalla de carga
    LayerWindow {
        layer: "overlay"; edges: ["top", "bottom", "left", "right"]; scope: "bc-popups"
        margins: [UiState.topInset, 0, UiState.win ? UiState.taskH : 0, 0]
        keyboard: (UiState.centerOpen && UiState.centerPanel === "wifi") || UiState.launcherOpen || UiState.clipboardOpen || UiState.startOpen || UiState.spotlightOpen || UiState.emojiOpen || UiState.screenshotOpen || UiState.forceQuitOpen || UiState.powerAction !== "" ? "exclusive" : "ondemand"
        width: UiState.sw; height: UiState.sh
        // Al cerrar, la capa sigue visible un momento para que menús, Spotlight y paneles se desvanezcan
        shown: UiState.popupOpen || popHold.running
        Timer { id: popHold; interval: Theme.reduced ? 1 : Math.max(1, Theme.d(260)) }   // lo que dura el fundido de salida (sigue la escala de animación)
        Connections { target: UiState; function onPopupOpenChanged() { if (UiState.popupOpen) popHold.stop(); else popHold.restart() } }
        Loader {
            id: popLoader
            anchors.fill: parent
            sourceComponent: Item {
                id: pop
                focus: true
                Keys.onEscapePressed: UiState.closePopups()
                readonly property real m: Math.round(14 * root.u)

                Rectangle { anchors.fill: parent; color: "#000"; opacity: UiState.dim && UiState.classic ? 0.35 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.dur(160) } } }
                MouseArea { anchors.fill: parent; onClicked: UiState.closePopups() }

                Lazy {
                    id: lzCC; open: UiState.centerOpen && !UiState.classic
                    sourceComponent: Item {
                        width: pop.width; height: pop.height
                        ControlCenterGG {
                            id: centerGG
                            Component.onCompleted: root.ccRef = centerGG
                            visible: !UiState.classic && opacity > 0
                            x: pop.width - pop.m - width
                            y: Theme.px(6)
                            opacity: lzCC.on ? 1 : 0
                            scale: lzCC.on ? 1 : 0.96
                            transformOrigin: Item.TopRight
                            Behavior on opacity { NumberAnimation { duration: Theme.d(Theme.durControlCenter); easing.type: Theme.easeStandard } }
                            Behavior on scale { NumberAnimation { duration: Theme.d(Theme.durControlCenter); easing.type: Theme.easeSpring } }
                        }
                    }
                }
                Lazy {
                    id: lzNC; open: UiState.notifCenterOpen
                    sourceComponent: Item {
                        width: pop.width; height: pop.height
                        NotificationCenter {
                            id: notifCenter
                            // Solo se anima un desplazamiento corto desde la derecha. Antes se animaba «x», que también cambiaba
                            // al cargarse el panel (su ancho), y el panel cruzaba media pantalla desde la izquierda.
                            property real shift: lzNC.on ? 0 : Theme.px(48)
                            x: pop.width - width - Theme.px(16) + shift
                            y: Theme.px(6)
                            opacity: lzNC.on ? 1 : 0
                            visible: opacity > 0
                            // Como macOS: sale rápido y frena al final
                            Behavior on shift { NumberAnimation { duration: Theme.d(260); easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: Theme.d(180); easing.type: Easing.OutQuad } }
                        }
                    }
                }
                Spotlight {
                    id: spotlight
                    Component.onCompleted: root.spotlightRef = spotlight
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Math.round(pop.height * 0.22)
                    visible: opacity > 0
                    opacity: UiState.spotlightOpen ? 1 : 0
                    scale: UiState.spotlightOpen || !Render.scaleAnimations ? 1 : 0.97   // por software, sin escalar (CPU)
                    Behavior on opacity { NumberAnimation { duration: Theme.d(UiState.spotlightOpen ? Theme.durSpotlight : 150); easing.type: Theme.easeStandard } }
                    Behavior on scale { NumberAnimation { duration: Theme.d(Theme.durSpotlight); easing.type: Theme.easeStandard } }
                    onDone: UiState.closePopups()
                    Connections { target: UiState; function onSpotlightOpenChanged() { if (UiState.spotlightOpen) spotlight.reset() } }
                }
                SlideIn { target: spotlight; dy: -10; duration: Theme.durSpotlight; fade: false }
                Lazy {
                    id: lzStack; open: UiState.stackOpen
                    sourceComponent: Item {
                        width: pop.width; height: pop.height
                        // Pila de Descargas (en rejilla, sobre su icono del Dock)
                        Item {
                            id: stack
                            visible: opacity > 0
                            opacity: lzStack.on ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.d(lzStack.on ? Theme.durPopover : 160) } }
                            width: Theme.px(360); height: Theme.px(330)
                            x: Math.min(pop.width - width - Theme.px(10), dockGG.minimizeTarget.x + dockGG.bs - width / 2)
                            y: pop.height - height - dockGG.plateH - Theme.px(18)
                            FileModel { id: dl; Component.onCompleted: place("downloads") }
                            Connections { target: UiState; function onStackOpenChanged() { if (UiState.stackOpen) dl.reload() } }
                            Glass { anchors.fill: parent; radius: Theme.px(18); tintBoost: 0.35; originY: UiState.topInset }
                            Text { x: Theme.px(16); y: Theme.px(12); text: qsTr("Descargas"); color: Theme.label; font.family: Theme.font; font.pixelSize: Theme.px(13); font.weight: Font.Bold }
                            GridView {
                                x: Theme.px(8); y: Theme.px(38); width: parent.width - Theme.px(16); height: parent.height - Theme.px(80)
                                cellWidth: width / 4; cellHeight: Theme.px(82); clip: true; model: dl
                                delegate: Item {
                                    required property string name
                                    required property string filePath
                                    required property string kind
                                    width: GridView.view.cellWidth; height: GridView.view.cellHeight
                                    FileGlyph { anchors.horizontalCenter: parent.horizontalCenter; y: Theme.px(4); kind: parent.kind; path: parent.filePath; width: Theme.px(52); height: Theme.px(44) }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; y: Theme.px(54); width: parent.width - Theme.px(6); horizontalAlignment: Text.AlignHCenter
                                           elide: Text.ElideMiddle; text: parent.name; color: Theme.label; font.family: Theme.font; font.pixelSize: Theme.px(11) }
                                    MouseArea { anchors.fill: parent; onClicked: { UiState.closePopups(); Quick.open(parent.filePath) } }
                                }
                            }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: Theme.px(14)
                                   text: dl.count === 0 ? qsTr("La carpeta está vacía") : qsTr("Abrir en Archivos") + "  ›"; color: Theme.selection
                                   font.family: Theme.font; font.pixelSize: Theme.px(12)
                                   MouseArea { anchors.fill: parent; onClicked: { UiState.closePopups(); Launcher.launch("archivos", Files.placePath("downloads")) } } }
                        }
                        SlideIn { target: stack; dy: 14; duration: Theme.durPopover; fade: false }
                    }
                }
                Lazy {
                    id: lzGal; open: UiState.widgetGalleryOpen
                    sourceComponent: Item {
                        width: pop.width; height: pop.height
                        // Galería de widgets («Editar widgets…» de macOS): añadir y quitar widgets del escritorio
                        Item {
                            id: gallery
                            visible: opacity > 0
                            opacity: lzGal.on ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.d(lzGal.on ? Theme.durPopover : 180) } }
                            width: Math.min(pop.width - Theme.px(40), Theme.px(900)); height: Theme.px(230)
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: pop.height - height - Theme.px(90)
                            readonly property var lay: { try { return JSON.parse(Settings.widgetLayout || "{}") } catch (e) { return {} } }
                            readonly property var act: lay._activos || ["baterias", "app", "recordatorios"]
                            Glass { anchors.fill: parent; radius: Theme.px(24); tintBoost: 0.35; originY: UiState.topInset }
                            MouseArea { anchors.fill: parent }
                            Text { x: Theme.px(24); y: Theme.px(16); text: qsTr("Widgets"); color: Theme.label; font.family: Theme.font; font.pixelSize: Theme.px(18); font.weight: Font.Bold }
                            Rectangle { anchors.right: parent.right; anchors.rightMargin: Theme.px(18); y: Theme.px(14); width: Theme.px(64); height: Theme.px(26); radius: height / 2; color: Theme.selection
                                        Text { anchors.centerIn: parent; text: qsTr("Listo"); color: "white"; font.family: Theme.font; font.pixelSize: Theme.px(12); font.weight: Font.Bold }
                                        MouseArea { anchors.fill: parent; onClicked: UiState.closePopups() } }
                            Row {
                                x: Theme.px(24); y: Theme.px(56); spacing: Theme.px(14)
                                Repeater {
                                    model: [ { k: "baterias", t: qsTr("Baterías"), i: "battery-level-80-symbolic" }, { k: "app", t: qsTr("Uso del equipo"), i: "power-profile-performance-symbolic" },
                                             { k: "recordatorios", t: qsTr("Recordatorios"), i: "view-list-symbolic" }, { k: "calendario", t: qsTr("Calendario"), i: "office-calendar" },
                                             { k: "reloj", t: qsTr("Reloj"), i: "preferences-system-time" } ]
                                    Item {
                                        required property var modelData
                                        readonly property bool on: gallery.act.indexOf(modelData.k) >= 0
                                        width: (gallery.width - Theme.px(48) - 4 * Theme.px(14)) / 5; height: Theme.px(150)
                                        Rectangle { anchors.fill: parent; radius: Theme.px(18); color: Theme.fill; border.width: parent.on ? 2 : 1; border.color: parent.on ? Theme.selection : Theme.separator }
                                        Icon { anchors.horizontalCenter: parent.horizontalCenter; y: Theme.px(30); name: modelData.i; size: Theme.px(40); color: Theme.label }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; y: Theme.px(88); text: modelData.t; color: Theme.label; font.family: Theme.font; font.pixelSize: Theme.px(13); font.weight: Font.DemiBold }
                                        Rectangle {
                                            anchors.horizontalCenter: parent.horizontalCenter; y: Theme.px(114); width: Theme.px(26); height: width; radius: width / 2
                                            color: parent.on ? Theme.fill : Theme.selection
                                            Text { anchors.centerIn: parent; text: parent.parent.on ? "−" : "+"; color: parent.parent.on ? Theme.label : "white"; font.pixelSize: Theme.px(17); font.weight: Font.Bold }
                                        }
                                        MouseArea { anchors.fill: parent; onClicked: { if (!Settings.widgets) Settings.widgets = true; UiState.command("bc", (parent.on ? "widgetOff:" : "widgetOn:") + modelData.k) } }
                                    }
                                }
                            }
                        }
                        SlideIn { target: gallery; dy: 30; duration: Theme.durPopover; fade: false }
                    }
                }
                Lazy {
                    id: lzTile; open: UiState.tilePop !== null
                    sourceComponent: Item {
                        width: pop.width; height: pop.height
                        // Popover del botón verde (macOS 27): «Mover y redimensionar», «Rellenar y organizar», pantalla completa
                        Item {
                            id: tilePop
                            visible: UiState.tilePop !== null
                            width: Theme.px(232); height: tpCol.height + Theme.px(16)
                            x: UiState.tilePop ? Math.min(pop.width - width - 8, UiState.tilePop.x) : 0
                            y: UiState.tilePop ? UiState.tilePop.y - UiState.topInset + Theme.px(4) : 0
                            Glass { anchors.fill: parent; radius: Theme.px(14); tintBoost: 0.4 }
                            MouseArea { anchors.fill: parent }
                            component TileBtn: Rectangle {
                                property string how; property var cells: []   // [x, y, w, h] en fracciones del icono
                                width: Theme.px(40); height: Theme.px(32); radius: Theme.px(8); color: tb.containsMouse ? Theme.fillHover : "transparent"
                                Rectangle {
                                    anchors.centerIn: parent; width: Theme.px(26); height: Theme.px(20); radius: Theme.px(4); color: "transparent"
                                    border.width: Theme.px(2); border.color: Theme.label
                                    Repeater { model: parent.parent.cells
                                               Rectangle { required property var modelData; x: Theme.px(3) + modelData[0] * (parent.width - Theme.px(6)); y: Theme.px(3) + modelData[1] * (parent.height - Theme.px(6))
                                                           width: modelData[2] * (parent.width - Theme.px(6)); height: modelData[3] * (parent.height - Theme.px(6)); radius: Theme.px(1.5); color: Theme.label } }
                                }
                                MouseArea { id: tb; anchors.fill: parent; hoverEnabled: true; onClicked: { UiState.closePopups(); UiState.run("bc:tile:" + parent.how) } }
                            }
                            Column {
                                id: tpCol; x: Theme.px(12); y: Theme.px(10); spacing: Theme.px(4)
                                Text { text: qsTr("Mover y redimensionar"); color: Theme.labelSecondary; font.family: Theme.font; font.pixelSize: Theme.px(11); font.weight: Font.DemiBold }
                                Row { spacing: Theme.px(12)
                                      TileBtn { how: "left"; cells: [[0, 0, 0.5, 1]] }
                                      TileBtn { how: "right"; cells: [[0.5, 0, 0.5, 1]] }
                                      TileBtn { how: "top"; cells: [[0, 0, 1, 0.5]] }
                                      TileBtn { how: "bottom"; cells: [[0, 0.5, 1, 0.5]] } }
                                Rectangle { width: Theme.px(208); height: 1; color: Theme.separator }
                                Text { text: qsTr("Rellenar y organizar"); color: Theme.labelSecondary; font.family: Theme.font; font.pixelSize: Theme.px(11); font.weight: Font.DemiBold }
                                Row { spacing: Theme.px(12)
                                      TileBtn { how: "fill"; cells: [[0, 0, 1, 1]] }
                                      TileBtn { how: "center"; cells: [[0.2, 0.15, 0.6, 0.7]] }
                                      TileBtn { how: "leftq"; cells: [[0, 0, 0.33, 1]] }
                                      TileBtn { how: "rightq"; cells: [[0.33, 0, 0.67, 1]] } }
                                Rectangle { width: Theme.px(208); height: 1; color: Theme.separator }
                                Rectangle {
                                    width: Theme.px(208); height: Theme.px(26); radius: Theme.px(6); color: fsm.containsMouse ? Theme.accent : "transparent"
                                    Text { x: Theme.px(8); anchors.verticalCenter: parent.verticalCenter; text: qsTr("Pantalla completa"); color: fsm.containsMouse ? "white" : Theme.label
                                           font.family: Theme.font; font.pixelSize: Theme.px(13) }
                                    MouseArea { id: fsm; anchors.fill: parent; hoverEnabled: true; onClicked: { UiState.closePopups(); Sway.toggleFullscreen(Sway.focusedId) } }
                                }
                            }
                        }
                        SlideIn { target: tilePop; dy: -4; duration: Theme.durMenuOpen }
                    }
                }
                // Menú contextual (Dock, escritorio, widgets…)
                MenuPopup {
                    id: ctx
                    // Se guardan los elementos para que el menú se desvanezca al cerrarse
                    property var keep: []
                    readonly property bool opened: UiState.contextItems.length > 0
                    onOpenedChanged: if (opened) keep = UiState.contextItems
                    Connections { target: UiState; function onContextItemsChanged() { if (UiState.contextItems.length) ctx.keep = UiState.contextItems } }
                    visible: opacity > 0
                    opacity: opened ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.d(ctx.opened ? Theme.durMenuOpen : Theme.durMenuClose) } }
                    items: keep
                    x: Math.max(8, Math.min(pop.width - width - 8, UiState.contextPos.x))
                    y: Math.max(4, Math.min(pop.height - height - 8, UiState.contextPos.y - UiState.topInset - (UiState.contextPos.y > pop.height * 0.7 ? height : 0)))
                    onActivated: (cmd) => { UiState.closePopups(); UiState.run(cmd) }
                }
                SlideIn { target: ctx; dy: -4; duration: Theme.durMenuOpen; fade: false }
                Lazy {
                    id: lzCCc; open: UiState.centerOpen && UiState.classic
                    sourceComponent: Item {
                        width: pop.width; height: pop.height
                        ControlCenter {
                            id: center
                            scale: root.u
                            transformOrigin: Item.TopRight
                            x: pop.width - pop.m - width
                            y: UiState.win ? pop.height - center.height * root.u - pop.m : pop.m + (Notifications.visible ? (80 + 10) * root.u : 0)
                            opacity: lzCCc.on ? 1 : 0
                            visible: opacity > 0
                            Behavior on opacity { NumberAnimation { duration: Theme.dur(160); easing.type: Theme.easing } }
                        }
        SlideIn { target: center; dy: -12; fade: false }
                    }
                }
                SlideIn { target: menu; dy: -6; duration: 150; fade: false }
                MenuPopup {
                    id: menu
                    readonly property var all: UiState.menu === "system" ? AppMenus.systemItems
                        : UiState.menu === "app" ? AppMenus.appMenu(Sway.focusedAppId)
                        : (UiState.menu.indexOf("m") === 0 ? (AppMenus.menusFor(Sway.focusedAppId)[parseInt(UiState.menu.substring(1))] || {items: []}).items : [])
                    property var keep: []
                    readonly property bool opened: UiState.menu !== "" && all.length > 0
                    onAllChanged: if (all.length) keep = all
                    items: keep
                    visible: opacity > 0
                    opacity: opened ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.d(menu.opened ? Theme.durMenuOpen : Theme.durMenuClose) } }
                    x: Math.max(8, Math.min(pop.width - width - 8, UiState.menuX))
                    y: 4
                    onActivated: (cmd) => { UiState.closePopups(); UiState.run(cmd) }
                }
                Lazy {
                    id: lzLP; open: UiState.launcherOpen && !UiState.classic
                    sourceComponent: Item {
                        width: pop.width; height: pop.height
                        Launchpad {
                            id: launchpad
                            visible: opacity > 0 && !UiState.classic
                            opacity: lzLP.on ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.d(lzLP.on ? Theme.durLaunchpad : 220); easing.type: Theme.easeStandard } }
                            Component.onCompleted: launchpad.reset()
                            onDone: UiState.closePopups()
                            onLaunch: (id, name) => { UiState.closePopups(); if (!Apps.launch(id)) Notifications.push("BC OS", name, qsTr("No se pudo abrir la aplicación"), "", 4000) }
                            Connections { target: UiState; function onLauncherOpenChanged() { if (UiState.classic) return; if (UiState.launcherOpen) launchpad.reset(); else launchpad.leave() } }
                        }
                    }
                }
                Lazy {
                    id: lzLW; open: UiState.launcherOpen && UiState.classic
                    sourceComponent: Item {
                        width: pop.width; height: pop.height
                        Item {
                            id: launcherWrap
                            visible: UiState.launcherOpen && UiState.classic
                            anchors.fill: parent
                            LauncherPanel {
                                id: launcher
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: Math.round(pop.height * 0.16)
                                onLaunchRequested: (id, name) => {
                                    UiState.closePopups()
                                    if (!Apps.launch(id)) Notifications.push("BC OS", name, qsTr("No se pudo abrir la aplicación"), "", 4000)
                                }
                                onCloseRequested: UiState.closePopups()
                                Component.onCompleted: launcher.reset()
                            }
                            Connections { target: UiState; function onLauncherOpenChanged() { if (UiState.launcherOpen) launcher.reset() } }
                        }
        SlideIn { target: launcherWrap; dy: -14; duration: 220 }
                    }
                }
                Lazy {
                    id: lzClip; open: UiState.clipboardOpen
                    sourceComponent: Item {
                        width: pop.width; height: pop.height
                        Item {
                            id: clipWrap
                            visible: UiState.clipboardOpen
                            anchors.fill: parent
                            ClipboardPopup {
                                id: clipboardPopup
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: Math.round(pop.height * 0.14)
                                onCloseRequested: UiState.closePopups()
                                Component.onCompleted: clipboardPopup.reset()
                            }
                            Connections { target: UiState; function onClipboardOpenChanged() { if (UiState.clipboardOpen) clipboardPopup.reset() } }
                        }
                        SlideIn { target: clipWrap; dy: -14; duration: 220 }
                    }
                }
                Lazy {
                    id: lzStart; open: UiState.startOpen
                    sourceComponent: Item {
                        width: pop.width; height: pop.height
                        StartMenu {
                            id: startMenu
                            visible: UiState.startOpen
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: pop.height - height - 12
                            onLaunchPinned: (k, n) => { UiState.closePopups(); root.launch(k, n) }
                            onLaunchApp: (id, n) => { UiState.closePopups(); if (!Apps.launch(id)) Notifications.push("BC OS", n, qsTr("No se pudo abrir la aplicación"), "", 4000) }
                            onCloseRequested: UiState.closePopups()
                            Connections { target: UiState; function onStartOpenChanged() { if (UiState.startOpen) startMenu.reset() } }
                            Component.onCompleted: startMenu.reset()
                        }
        SlideIn { target: startMenu; dy: 28; duration: 240 }
                    }
                }
                Lazy { id: lzFQ; open: UiState.forceQuitOpen
                       sourceComponent: Item { width: pop.width; height: pop.height; ForceQuit { opacity: lzFQ.on ? 1 : 0 } } }
                Lazy { id: lzShot; open: UiState.screenshotOpen
                       sourceComponent: Item { width: pop.width; height: pop.height; ScreenshotPanel { on: lzShot.on } } }
                Lazy { id: lzEmoji; open: UiState.emojiOpen
                       sourceComponent: Item { width: pop.width; height: pop.height; EmojiPicker { opacity: lzEmoji.on ? 1 : 0 } } }
                Lazy {
                    id: lzPower; open: UiState.powerAction !== ""
                    sourceComponent: Item {
                        width: pop.width; height: pop.height
                        PowerDialog {
                            id: powerDialog
                            Component.onCompleted: Qt.callLater(() => { if (UiState.powerAction !== "") powerDialog.open(UiState.powerAction) })
                            onCancelled: UiState.powerAction = ""
                            onConfirmed: (a) => {
                                UiState.powerAction = ""
                                if (a === "poweroff") Power.poweroff()
                                else if (a === "reboot") Power.reboot()
                                else if (a === "suspend") Power.suspend()
                                else if (a === "logout") Power.logout()
                            }
                        }
                    }
                }
            }
        }
    }

    Timer { id: liveInstall; interval: 2500; onTriggered: Launcher.run("bc-shell", ["--app", "installer"]) }
    Component.onCompleted: {
        UiState.classic = AppConfig.classic
        UiState.splashing = AppConfig.splash
        // El panel se reinició con la pantalla bloqueada (fallo): sigue bloqueada
        if (AppConfig.demo === "" && Quick.lockFlag()) UiState.locked = true
        // Sistema live (ISO): como el instalador de macOS, «Instalar BC OS» se abre solo al entrar
        if (AppConfig.demo === "" && Installer.live && !UiState.locked) liveInstall.start()
        UiState.style = Settings.desktopStyle === "win" ? "win" : "mac"
        UiState.widgets = Settings.widgets
        UiState.mode = Settings.mode
        // En la ISO live no hay bienvenida (taparía el instalador): se abre «Instalar BC OS»
        if (AppConfig.splash && !Settings.welcomed && !Installer.live) welcomeTimer.start()
        if (AppConfig.demo === "win") UiState.style = "win"
        if (!AppConfig.splash && AppConfig.demo === "") Notifications.push("BC OS", qsTr("Actualizaciones"), qsTr("BC OS está al día"), "", 600000)
        const d = AppConfig.demo
        if (d === "lock") UiState.locked = true
        else if (d === "center") UiState.centerOpen = true
        else if (d === "tile") UiState.tilePop = { x: 300, y: 90 }
        else if (d === "center-edit") { UiState.centerOpen = true; if (ccRef) ccRef.editing = true }
        else if (d === "notif") UiState.notifCenterOpen = true
        else if (d === "spotlight") UiState.spotlightOpen = true
        else if (d === "spotlight-q") { UiState.spotlightOpen = true; demoQ.start() }
        else if (d === "launchpad") UiState.launcherOpen = true
        else if (d === "menu") UiState.menu = "system"
        else if (d === "light") Settings.appearance = "light"
        else if (d === "widgets") UiState.widgetGalleryOpen = true
        else if (d === "menu") UiState.openMenu("system", 12)
        else if (d === "power") UiState.openPower("poweroff")
        else if (d === "forzar") UiState.run("bc:forcequit")
        else if (d === "emoji") UiState.run("bc:emoji")
        else if (d === "captura") UiState.screenshotOpen = true
        else if (d === "grabando") UiState.recording = true
        else if (d === "launcher") UiState.toggleLauncher()
        else if (d === "centro") UiState.centerOpen = true
        else if (d === "bienvenida" || d === "bienvenida-fondo") UiState.welcomeOpen = true
        else if (d === "contexto") UiState.openContextMenu([{ label: qsTr("Abrir"), cmd: "" }, { label: qsTr("Vaciar papelera…"), cmd: "" }, { sep: true },
                                                             { label: qsTr("Obtener información"), cmd: "" }, { label: qsTr("Renombrar"), cmd: "" }], Qt.point(UiState.sw * 0.6, UiState.sh - 160))
        else if (d === "inicio") { UiState.style = "win"; UiState.toggleLauncher() }
        else if (d === "tienda" || d === "monitor" || d === "ajustes") launch(d, "")
    }
}
