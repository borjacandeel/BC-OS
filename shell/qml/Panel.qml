import QtQuick
import QtQuick.Window
import BCShell

// Panel de BC Shell: fondo, barra superior, Dock, notificaciones y capa de ventanas emergentes,
// cada uno como superficie wlr-layer-shell (el compositor es sway; las apps son procesos aparte).
LayerWindow {
    id: root
    layer: "background"
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
    Wallpaper { id: wall; anchors.fill: parent; visible: !Layer.supported }
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
        if (kind === "musica") { Notifications.push("BC OS", name, qsTr("En desarrollo"), "", 4000); return }
        const appId = Launcher.appIdFor(kind)
        if (kind === "papelera") {
            if (Sway.hasApp("bc-files")) { Shell.invokeApp("files", "trash"); Sway.focusApp("bc-files") }
            else Launcher.launch("archivos", "trash")
            return
        }
        if (Sway.focusApp(appId) || (kind === "terminal" && Sway.focusApp("foot"))) return
        const r = Launcher.launch(kind)
        if (r === "failed") Notifications.push("BC OS", name, qsTr("No se pudo abrir la aplicación"), "", 4000)
    }
    // ---- Minimizar al Dock con efecto genio ----------------------------------------------------
    property var genieShots: ({})       // id de ventana → { path, rect }
    property var geniePending: null
    function minimizeGenie(id) {
        if (id === undefined || id < 0 || isNaN(id)) id = Sway.focusedId
        const w = Sway.windows.find(x => x.id === id)
        if (!w || UiState.classic || Theme.reduced || w.rectW <= 0) { if (w) Sway.minimizeWindow(w.id); return }
        geniePending = { id: w.id, rect: Qt.rect(w.decoX, w.decoY, w.rectW, w.rectH), back: false }
        Quick.capture("genie-" + w.id, w.decoX + "," + w.decoY + " " + w.rectW + "x" + w.rectH)
    }
    function restoreGenie(id) {
        const shot = genieShots[id]
        if (!shot || UiState.classic || Theme.reduced) { Sway.command("[con_id=" + id + "] scratchpad show"); return }
        genieWin.shown = true
        geniePending = { id: id, rect: shot.rect, back: true }
        genie.run("file://" + shot.path, shot.rect, Qt.point(dockGG.minimizeTarget.x + dockWin.originX, dockGG.minimizeTarget.y + dockWin.originY), dockGG.bs, true)
    }
    Connections {
        target: Quick
        function onCaptured(tag, path, ok) {
            if (tag.indexOf("genie-") !== 0 || !root.geniePending) return
            const g = root.geniePending
            Sway.minimizeWindow(g.id)
            if (!ok) { root.geniePending = null; return }
            const s = Object.assign({}, root.genieShots); s[g.id] = { path: path, rect: g.rect }; root.genieShots = s
            genieWin.shown = true
            genie.run("file://" + path, g.rect, Qt.point(dockGG.minimizeTarget.x + dockWin.originX, dockGG.minimizeTarget.y + dockWin.originY), dockGG.bs, false)
        }
    }
    LayerWindow {
        id: genieWin
        layer: "overlay"; edges: ["top", "bottom", "left", "right"]; scope: "bc-genie"; passthrough: true
        width: UiState.sw; height: UiState.sh
        shown: false
        Genie {
            id: genie
            onFinished: {
                genieWin.shown = false
                const g = root.geniePending
                if (g && g.back) Sway.command("[con_id=" + g.id + "] scratchpad show")
                root.geniePending = null
            }
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
            else if (name === "appearance") Settings.appearance = Theme.dark ? "light" : "dark"
            else if (name === "desktop") {
                const vis = Sway.windows.filter(w => !w.minimized)
                if (vis.length) for (const w of vis) Sway.minimizeWindow(w.id)
                else for (const w of Sway.windows) Sway.command("[con_id=" + w.id + "] scratchpad show")
            }
        }
    }

    // Sonidos del sistema (originales de BC OS)
    Connections { target: UiState; function onLockedChanged() { if (UiState.locked && !UiState.classic) Sounds.play("lock") } }
    property bool _notifWas: false
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
        else r = [W * 0.15, top + H * 0.1, W * 0.7, H * 0.8]
        Sway.command("[con_id=" + id + "] floating enable, resize set " + Math.round(r[2]) + " " + Math.round(r[3]) + ", move absolute position " + Math.round(r[0]) + " " + Math.round(r[1]))
    }
    function runningKinds() {
        const ids = Sway.windows.map(w => w.appId), out = []
        for (const k of ["archivos", "ajustes", "monitor", "terminal", "tienda", "navegador"]) {
            const id = Launcher.appIdFor(k)
            if (ids.indexOf(id) >= 0 || (k === "terminal" && ids.indexOf("foot") >= 0)) out.push(k)
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
                else if (arg.indexOf("restore:") === 0) root.restoreGenie(parseInt(arg.substring(8)))
                else if (arg === "about") Notifications.push("BC OS", qsTr("BC OS"), qsTr("Versión alpha · ARM64"), "", 4000)
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
                const p = value === "-" ? "/usr/share/bc/wallpapers/ondas.jpg" : value
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
    Timer { id: welcomeTimer; interval: 3500; onTriggered: if (!UiState.locked) UiState.welcomeOpen = true }

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
        model: UiState.classic || UiState.win ? 0 : Math.max(0, Qt.application.screens.length - 1)
        delegate: QtObject {
            required property int index
            readonly property var modelData: Qt.application.screens[index + 1]
            property LayerWindow bar2: LayerWindow {
                screen: modelData
                layer: "top"; edges: ["top", "left", "right"]; exclusive: UiState.barH; scope: "bc-topbar"
                width: modelData.width; height: UiState.barH
                shown: !UiState.splashing && !UiState.locked
                MenuBar { anchors.fill: parent }
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

    // Notificación emergente
    LayerWindow {
        layer: "top"; edges: ["top", "right"]; margins: [UiState.topInset + Math.round(14 * root.u), Math.round(14 * root.u), 0, 0]; scope: "bc-notify"
        width: Math.round(321 * root.u); height: Math.round(80 * root.u)
        shown: Notifications.visible && !UiState.locked && !UiState.splashing
        NotificationCard {
            id: notifCard
            scale: root.u
            transformOrigin: Item.TopLeft
            title: Notifications.title
            body: Notifications.body
            onDismissed: Notifications.dismiss()
        }
        SlideIn { target: notifCard; dx: 60; dy: 0; duration: 260 }
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
                anchors.fill: parent
                visible: UiState.welcomeOpen
                onVisibleChanged: if (visible) { step = 0; forceActiveFocus() }
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
        keyboard: UiState.launcherOpen || UiState.clipboardOpen || UiState.startOpen || UiState.spotlightOpen || UiState.powerAction !== "" ? "exclusive" : "ondemand"
        width: UiState.sw; height: UiState.sh
        shown: UiState.popupOpen
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

                ControlCenterGG {
                    id: centerGG
                    visible: !UiState.classic && opacity > 0
                    x: pop.width - pop.m - width
                    y: Theme.px(6)
                    opacity: UiState.centerOpen ? 1 : 0
                    scale: UiState.centerOpen ? 1 : 0.96
                    transformOrigin: Item.TopRight
                    Behavior on opacity { NumberAnimation { duration: Theme.d(Theme.durControlCenter); easing.type: Theme.easeStandard } }
                    Behavior on scale { NumberAnimation { duration: Theme.d(Theme.durControlCenter); easing.type: Theme.easeSpring } }
                }
                NotificationCenter {
                    id: notifCenter
                    x: pop.width - width - Theme.px(10) + (UiState.notifCenterOpen ? 0 : width / 3)
                    y: Theme.px(6)
                    opacity: UiState.notifCenterOpen ? 1 : 0
                    visible: opacity > 0
                    Behavior on x { NumberAnimation { duration: Theme.d(Theme.durNotifyIn); easing.type: Theme.easeEmphasized } }
                    Behavior on opacity { NumberAnimation { duration: Theme.d(Theme.durNotifyOut) } }
                }
                Spotlight {
                    id: spotlight
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Math.round(pop.height * 0.22)
                    visible: UiState.spotlightOpen
                    onDone: UiState.closePopups()
                    Connections { target: UiState; function onSpotlightOpenChanged() { if (UiState.spotlightOpen) spotlight.reset() } }
                }
                SlideIn { target: spotlight; dy: -10; duration: Theme.durSpotlight }
                // Pila de Descargas (en rejilla, sobre su icono del Dock)
                Item {
                    id: stack
                    visible: UiState.stackOpen
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
                            FileGlyph { anchors.horizontalCenter: parent.horizontalCenter; y: Theme.px(4); kind: parent.kind; width: Theme.px(52); height: Theme.px(44) }
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
                SlideIn { target: stack; dy: 14; duration: Theme.durPopover }
                // Menú contextual (Dock, escritorio, widgets…)
                MenuPopup {
                    id: ctx
                    visible: UiState.contextItems.length > 0
                    items: UiState.contextItems
                    x: Math.max(8, Math.min(pop.width - width - 8, UiState.contextPos.x))
                    y: Math.max(4, Math.min(pop.height - height - 8, UiState.contextPos.y - UiState.topInset - (UiState.contextPos.y > pop.height * 0.7 ? height : 0)))
                    onActivated: (cmd) => { UiState.closePopups(); UiState.run(cmd) }
                }
                SlideIn { target: ctx; dy: -4; duration: Theme.durMenuOpen }
                ControlCenter {
                    id: center
                    scale: root.u
                    transformOrigin: Item.TopRight
                    x: pop.width - pop.m - width
                    y: UiState.win ? pop.height - center.height * root.u - pop.m : pop.m + (Notifications.visible ? (80 + 10) * root.u : 0)
                    opacity: UiState.centerOpen && UiState.classic ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Theme.dur(160); easing.type: Theme.easing } }
                }
                SlideIn { target: center; dy: -12; fade: false }
                SlideIn { target: menu; dy: -6; duration: 150 }
                SlideIn { target: launcherWrap; dy: -14; duration: 220 }
                SlideIn { target: startMenu; dy: 28; duration: 240 }
                MenuPopup {
                    id: menu
                    readonly property var all: UiState.menu === "system" ? AppMenus.systemItems
                        : UiState.menu === "app" ? AppMenus.appMenu(Sway.focusedAppId)
                        : (UiState.menu.indexOf("m") === 0 ? (AppMenus.menusFor(Sway.focusedAppId)[parseInt(UiState.menu.substring(1))] || {items: []}).items : [])
                    items: all
                    visible: UiState.menu !== "" && items.length > 0
                    x: Math.max(8, Math.min(pop.width - width - 8, UiState.menuX))
                    y: 4
                    onActivated: (cmd) => { UiState.closePopups(); UiState.run(cmd) }
                }
                Launchpad {
                    id: launchpad
                    visible: UiState.launcherOpen && !UiState.classic
                    opacity: visible ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.d(Theme.durLaunchpad); easing.type: Theme.easeStandard } }
                    onDone: UiState.closePopups()
                    onLaunch: (id, name) => { UiState.closePopups(); if (!Apps.launch(id)) Notifications.push("BC OS", name, qsTr("No se pudo abrir la aplicación"), "", 4000) }
                    Connections { target: UiState; function onLauncherOpenChanged() { if (UiState.launcherOpen && !UiState.classic) launchpad.reset() } }
                }
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
                    }
                    Connections { target: UiState; function onLauncherOpenChanged() { if (UiState.launcherOpen) launcher.reset() } }
                }
                Item {
                    id: clipWrap
                    visible: UiState.clipboardOpen
                    anchors.fill: parent
                    ClipboardPopup {
                        id: clipboardPopup
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: Math.round(pop.height * 0.14)
                        onCloseRequested: UiState.closePopups()
                    }
                    Connections { target: UiState; function onClipboardOpenChanged() { if (UiState.clipboardOpen) clipboardPopup.reset() } }
                }
                SlideIn { target: clipWrap; dy: -14; duration: 220 }
                StartMenu {
                    id: startMenu
                    visible: UiState.startOpen
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: pop.height - height - 12
                    onLaunchPinned: (k, n) => { UiState.closePopups(); root.launch(k, n) }
                    onLaunchApp: (id, n) => { UiState.closePopups(); if (!Apps.launch(id)) Notifications.push("BC OS", n, qsTr("No se pudo abrir la aplicación"), "", 4000) }
                    onCloseRequested: UiState.closePopups()
                    Connections { target: UiState; function onStartOpenChanged() { if (UiState.startOpen) startMenu.reset() } }
                }
                PowerDialog {
                    id: powerDialog
                    onCancelled: UiState.powerAction = ""
                    onConfirmed: (a) => {
                        UiState.powerAction = ""
                        if (a === "poweroff") Power.poweroff()
                        else if (a === "reboot") Power.reboot()
                        else if (a === "suspend") Power.suspend()
                        else if (a === "logout") Power.logout()
                    }
                }
                Connections { target: UiState; function onPowerActionChanged() { if (UiState.powerAction !== "") powerDialog.open(UiState.powerAction) } }
            }
        }
    }

    Component.onCompleted: {
        UiState.classic = AppConfig.classic
        UiState.splashing = AppConfig.splash
        UiState.style = Settings.desktopStyle === "win" ? "win" : "mac"
        UiState.widgets = Settings.widgets
        UiState.mode = Settings.mode
        if (AppConfig.splash && !Settings.welcomed) welcomeTimer.start()
        if (AppConfig.demo === "win") UiState.style = "win"
        if (!AppConfig.splash && AppConfig.demo === "") Notifications.push("BC OS", qsTr("Actualizaciones"), qsTr("BC OS está al día"), "", 600000)
        const d = AppConfig.demo
        if (d === "lock") UiState.locked = true
        else if (d === "center") UiState.centerOpen = true
        else if (d === "notif") UiState.notifCenterOpen = true
        else if (d === "spotlight") UiState.spotlightOpen = true
        else if (d === "launchpad") UiState.launcherOpen = true
        else if (d === "menu") UiState.menu = "system"
        else if (d === "light") Settings.appearance = "light"
        else if (d === "menu") UiState.openMenu("system", 12)
        else if (d === "power") UiState.openPower("poweroff")
        else if (d === "launcher") UiState.toggleLauncher()
        else if (d === "centro") UiState.centerOpen = true
        else if (d === "bienvenida") UiState.welcomeOpen = true
        else if (d === "inicio") { UiState.style = "win"; UiState.toggleLauncher() }
        else if (d === "tienda" || d === "monitor" || d === "ajustes") launch(d, "")
    }
}
