import QtQuick
import QtQuick.Window
import BCShell

Window {
    id: root
    visible: true
    width: 1586
    height: 992
    minimumWidth: 1024
    minimumHeight: 640
    title: qsTr("BC Shell")
    color: Theme.midnight

    // Cada componente va en su Loader: si uno falla, el resto del escritorio sigue vivo.
    readonly property int loadErrors: [wallpaper, topbar, files, notif, center, dock, brand]
        .filter(l => l.status === Loader.Error).length
    readonly property string notifTitle: qsTr("Actualizaciones")
    property bool centerOpen: true
    property bool filesOpen: true
    property bool locked: false
    property bool monitorOpen: false
    property bool settingsOpen: false
    property int zTop: 100
    readonly property bool notifOpen: Notifications.visible

    // Escala única respecto al diseño (1586x992), acotada: el escritorio se adapta a cualquier tamaño.
    readonly property real u: Math.max(0.6, Math.min(1.25, Math.min(width / 1586, height / 992)))
    readonly property real margin: Math.round(14 * u)
    readonly property real topH: 41
    readonly property real dockTop: root.height - dock.height * u - Math.round(22 * u)
    readonly property real rightColW: (center.width > 0 ? center.width : 381) * u + margin * 2

    function showNotice(title, text) { Notifications.push("BC OS", title, text, "", 4000) }
    function openInternal(loader, flag) {
        root[flag] = true
        if (loader.item) { loader.item.shown = true; loader.z = ++root.zTop }
    }
    function place(item, n) {
        item.bounds = Qt.binding(() => Qt.size(root.width, root.height))
        item.freeArea = Qt.binding(() => Qt.rect(root.margin, root.topH + root.margin, root.width - 2 * root.margin, root.dockTop - root.topH - 2 * root.margin))
        item.x = Math.max(root.margin, Math.min(root.width - item.width - root.margin, root.margin + 50 + n * 60))
        item.y = Math.max(root.topH + 4, Math.min(root.dockTop - item.height - 6, root.topH + root.margin + 24 + n * 40))
        item.shown = false
        Qt.callLater(() => item.shown = true)
    }
    function launch(kind, name) {
        const r = Launcher.launch(kind)
        if (kind === "monitor") { openInternal(monitorWin, "monitorOpen"); return }
        if (kind === "ajustes") { openInternal(settingsWin, "settingsOpen"); return }
        if (kind === "archivos") filesOpen = true
        else if (r === "unavailable") showNotice(name, qsTr("En desarrollo"))
        else if (r === "failed") showNotice(name, qsTr("No se pudo abrir la aplicación"))
    }

    Loader { id: wallpaper; anchors.fill: parent; source: "Wallpaper.qml" }

    Loader {
        id: topbar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.topH
        source: "TopBar.qml"
        onLoaded: {
            item.controlCenterToggled.connect(() => root.centerOpen = !root.centerOpen)
            item.systemMenuRequested.connect(() => sysMenu.open = !sysMenu.open)
        }
    }

    // Archivos: centrado en el hueco libre a la izquierda del panel derecho, sobre el Dock.
    Loader {
        id: files
        readonly property real freeW: root.width - root.rightColW - root.margin
        readonly property real freeH: root.dockTop - root.margin - root.topH - root.margin
        active: root.filesOpen
        source: "FilesWindow.qml"
        scale: Math.min(root.u, freeW / Math.max(1, width), freeH / Math.max(1, height))
        transformOrigin: Item.TopLeft
        x: root.margin + Math.max(0, (freeW - width * scale) / 2)
        y: root.topH + root.margin + Math.max(0, (freeH - height * scale) / 2)
        onLoaded: item.closeRequested.connect(() => root.filesOpen = false)
    }

    Loader {
        id: monitorWin
        active: root.monitorOpen
        source: "MonitorApp.qml"
        onLoaded: { root.place(item, 1); z = ++root.zTop
                    item.activated.connect(() => monitorWin.z = ++root.zTop)
                    item.closeRequested.connect(() => { item.shown = false; monitorClose.restart() }) }
    }
    Timer { id: monitorClose; interval: 230; onTriggered: root.monitorOpen = false }

    Loader {
        id: settingsWin
        active: root.settingsOpen
        source: "SettingsApp.qml"
        onLoaded: { root.place(item, 0); z = ++root.zTop
                    item.activated.connect(() => settingsWin.z = ++root.zTop)
                    item.closeRequested.connect(() => { item.shown = false; settingsClose.restart() }) }
    }
    Timer { id: settingsClose; interval: 230; onTriggered: root.settingsOpen = false }

    Loader {
        id: notif
        active: root.notifOpen
        source: "NotificationCard.qml"
        scale: root.u
        transformOrigin: Item.TopRight
        x: root.width - root.margin - width
        y: root.topH + root.margin
        onLoaded: item.dismissed.connect(() => Notifications.dismiss())
        Binding { target: notif.item; property: "title"; value: Notifications.title; when: notif.item }
        Binding { target: notif.item; property: "body"; value: Notifications.body; when: notif.item }
    }

    Loader {
        id: center
        source: "ControlCenter.qml"
        scale: root.u
        transformOrigin: Item.TopRight
        x: root.width - root.margin - width
        y: root.topH + root.margin + (root.notifOpen ? (80 + 10) * root.u : 0)
        Behavior on y { NumberAnimation { duration: Theme.dur(160); easing.type: Theme.easing } }
        opacity: root.centerOpen ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur(160); easing.type: Theme.easing } }
    }

    // Marca y lema: abajo a la izquierda; el lema se oculta si chocaría con el Dock.
    Loader {
        id: brand
        scale: root.u
        transformOrigin: Item.BottomLeft
        x: Math.round(41 * root.u)
        y: root.height - height - Math.round(22 * root.u)
        visible: !(wallpaper.item && wallpaper.item.ready) && x + width * root.u + root.margin < dock.x + dock.width * (1 - root.u) / 2
        sourceComponent: Component {
            Column {
                spacing: 22
                Brand { logoHeight: 31; withOs: true }
                Text {
                    text: qsTr("LIGERO. POTENTE. FLUIDO.")
                    color: Theme.white
                    font.family: Theme.fontMono
                    font.pixelSize: 16
                    font.letterSpacing: 3.6
                }
            }
        }
    }

    Loader {
        id: dock
        source: "Dock.qml"
        scale: root.u
        transformOrigin: Item.Bottom
        x: (root.width - width) / 2
        y: root.height - height - Math.round(22 * root.u)
        onLoaded: {
            item.launched.connect((kind, name) => root.launch(kind, name))
            item.running = Qt.binding(() => Launcher.running.concat(root.filesOpen ? ["archivos"] : [])
                .concat(root.monitorOpen ? ["monitor"] : []).concat(root.settingsOpen ? ["ajustes"] : []))
        }
    }

    Shortcut { sequence: "Ctrl+Meta+Q"; onActivated: root.locked = true }

    SystemMenu {
        id: sysMenu
        onAboutRequested: root.showNotice(qsTr("BC OS"), qsTr("Versión alpha · ARM64"))
        onSettingsRequested: root.launch("ajustes", qsTr("Configuración"))
        onLockRequested: root.locked = true
        onPowerRequested: (action) => powerDialog.open(action)
    }

    PowerDialog {
        id: powerDialog
        onConfirmed: (a) => {
            if (a === "poweroff") Power.poweroff()
            else if (a === "reboot") Power.reboot()
            else if (a === "suspend") Power.suspend()
            else if (a === "logout") Power.logout()
        }
    }

    LockScreen {
        id: lockScreen
        active: root.locked
        onUnlocked: root.locked = false
    }

    Splash { }

    Component.onCompleted: {
        if (!AppConfig.splash && AppConfig.demo === "") Notifications.push("BC OS", qsTr("Actualizaciones"), qsTr("BC OS está al día"), "", 600000)
        if (AppConfig.demo === "lock") locked = true
        else if (AppConfig.demo === "menu") sysMenu.open = true
        else if (AppConfig.demo === "power") powerDialog.open("poweroff")
        else if (AppConfig.demo === "monitor") launch("monitor", "")
        else if (AppConfig.demo === "ajustes") launch("ajustes", "")
    }
}
