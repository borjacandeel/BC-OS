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
    Widgets {
        visible: UiState.widgets && !UiState.minimal
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
                const p = value === "-" ? "/usr/share/bc/wallpapers/medianoche.jpg" : value
                if (/^[^"\\$;,\n'`]+$/.test(p)) Sway.command("output * bg \"" + p + "\" fill #04111F")
            }
        }
        function onStyleChanged(st) { UiState.closePopups(); UiState.style = (st === "win" || st === "minimal") ? st : "mac" }
        function onWelcomeRequested() { UiState.closePopups(); UiState.welcomeOpen = true }
        function onLauncherToggled() { UiState.toggleLauncher() }
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

    Timer { id: welcomeTimer; interval: 3500; onTriggered: if (!UiState.locked) UiState.welcomeOpen = true }

    // Barra superior
    LayerWindow {
        layer: "top"; edges: ["top", "left", "right"]; exclusive: UiState.barH; scope: "bc-topbar"
        width: UiState.sw; height: UiState.barH
        shown: !UiState.splashing && !UiState.win && !UiState.locked
        Loader { id: bar; anchors.fill: parent; source: "TopBar.qml" }
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
        shown: !UiState.splashing && !UiState.locked && !UiState.win && !UiState.minimal
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

    // Notificación emergente
    LayerWindow {
        layer: "top"; edges: ["top", "right"]; margins: [UiState.topInset + Math.round(14 * root.u), Math.round(14 * root.u), 0, 0]; scope: "bc-notify"
        width: Math.round(321 * root.u); height: Math.round(80 * root.u)
        shown: Notifications.visible && !UiState.locked && !UiState.splashing
        NotificationCard {
            scale: root.u
            transformOrigin: Item.TopLeft
            title: Notifications.title
            body: Notifications.body
            onDismissed: Notifications.dismiss()
        }
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
        keyboard: UiState.launcherOpen || UiState.startOpen || UiState.powerAction !== "" ? "exclusive" : "ondemand"
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

                Rectangle { anchors.fill: parent; color: "#000"; opacity: UiState.dim ? 0.35 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.dur(160) } } }
                MouseArea { anchors.fill: parent; onClicked: UiState.closePopups() }

                ControlCenter {
                    id: center
                    scale: root.u
                    transformOrigin: Item.TopRight
                    x: pop.width - pop.m - width
                    y: UiState.win ? pop.height - center.height * root.u - pop.m : pop.m + (Notifications.visible ? (80 + 10) * root.u : 0)
                    opacity: UiState.centerOpen ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Theme.dur(160); easing.type: Theme.easing } }
                }
                MenuPopup {
                    id: menu
                    readonly property var all: UiState.menu === "system" ? AppMenus.systemItems
                        : (UiState.menu.indexOf("m") === 0 ? (AppMenus.menusFor(Sway.focusedAppId)[parseInt(UiState.menu.substring(1))] || {items: []}).items : [])
                    items: all
                    visible: UiState.menu !== "" && items.length > 0
                    x: Math.max(8, Math.min(pop.width - width - 8, UiState.menuX))
                    y: 4
                    onActivated: (cmd) => { UiState.closePopups(); UiState.run(cmd) }
                }
                Item {
                    visible: UiState.launcherOpen
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
        UiState.splashing = AppConfig.splash
        UiState.style = Settings.desktopStyle
        UiState.widgets = Settings.widgets
        UiState.mode = Settings.mode
        if (AppConfig.splash && !Settings.welcomed) welcomeTimer.start()
        if (AppConfig.demo === "win") UiState.style = "win"
        if (!AppConfig.splash && AppConfig.demo === "") Notifications.push("BC OS", qsTr("Actualizaciones"), qsTr("BC OS está al día"), "", 600000)
        const d = AppConfig.demo
        if (d === "lock") UiState.locked = true
        else if (d === "menu") UiState.openMenu("system", 12)
        else if (d === "power") UiState.openPower("poweroff")
        else if (d === "launcher") UiState.toggleLauncher()
        else if (d === "centro") UiState.centerOpen = true
        else if (d === "bienvenida") UiState.welcomeOpen = true
        else if (d === "inicio") { UiState.style = "win"; UiState.toggleLauncher() }
        else if (d === "tienda" || d === "monitor" || d === "ajustes") launch(d, "")
    }
}
