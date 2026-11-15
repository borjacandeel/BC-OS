pragma Singleton
import QtQuick

// Estado compartido del panel (las superficies layer-shell son ventanas distintas del mismo proceso).
QtObject {
    id: ui
    readonly property var scr: Qt.application.screens.length > 0 ? Qt.application.screens[0] : null
    property real sw: scr ? scr.width : 1280
    property real sh: scr ? scr.height : 800
    property bool splashing: false
    signal command(string kind, string arg)
    readonly property real u: Math.max(0.6, Math.min(1.25, Math.min(sw / 1586, sh / 992)))
    property bool classic: false                // sesión «BC clásico» (escritorio anterior); la fija Panel.qml
    readonly property real gs: Math.max(0.7, Math.min(2.0, sh / 1080))
    readonly property int barH: classic ? 41 : Math.round(30 * gs)

    property string style: "mac"               // "mac" (barra superior + Dock) o "win" (barra de tareas + menú Inicio)
    readonly property bool win: style === "win"
    readonly property bool minimal: style === "minimal"
    property bool welcomeOpen: false
    readonly property int taskH: 48
    readonly property int topInset: win ? 0 : barH
    property bool startOpen: false
    property bool clipboardOpen: false
    property string mode: ""                 // "", "relax", "focus" o "night"
    property bool widgets: true
    readonly property var pinned: [
        { kind: "archivos", name: qsTr("Archivos") }, { kind: "ajustes", name: qsTr("Configuración") },
        { kind: "monitor", name: qsTr("Monitor") }, { kind: "terminal", name: qsTr("Terminal") },
        { kind: "tienda", name: qsTr("Tienda") }, { kind: "navegador", name: qsTr("Navegador") },
        { kind: "musica", name: qsTr("Música") }, { kind: "papelera", name: qsTr("Papelera") }
    ]
    property bool centerOpen: false
    property string centerPanel: ""          // subpanel del Control Center abierto («wifi», «bluetooth», «sound»…)
    property bool notifCenterOpen: false
    property bool spotlightOpen: false
    property bool missionOpen: false
    property bool switcherOpen: false
    property bool stackOpen: false
    property bool widgetGalleryOpen: false
    property var contextItems: []
    property point contextPos: Qt.point(0, 0)
    readonly property bool dockMenuOpen: contextItems.length > 0 || stackOpen
    property bool launcherOpen: false
    property string menu: ""          // "", "system" o "m<índice>" (menús de la barra)
    property real menuX: 12
    property bool locked: false
    property string powerAction: ""
    readonly property bool popupOpen: !locked && (centerOpen || launcherOpen || startOpen || clipboardOpen || menu !== "" || powerAction !== ""
                                                  || notifCenterOpen || spotlightOpen || stackOpen || widgetGalleryOpen || contextItems.length > 0)
    readonly property bool dim: launcherOpen || powerAction !== ""

    function closePopups() { centerOpen = false; centerPanel = ""; launcherOpen = false; startOpen = false; clipboardOpen = false; menu = ""; powerAction = ""
                             notifCenterOpen = false; spotlightOpen = false; stackOpen = false; widgetGalleryOpen = false; contextItems = [] }
    function toggleNotifCenter() { if (locked) return; const o = notifCenterOpen; closePopups(); notifCenterOpen = !o }
    function openCenterPanel(name) { if (locked) return; closePopups(); centerOpen = true; centerPanel = name }
    function toggleSpotlight() { if (locked) return; const o = spotlightOpen; closePopups(); spotlightOpen = !o }
    function toggleLaunchpad() { toggleLauncher() }
    function toggleStack() { if (locked) return; const o = stackOpen; closePopups(); stackOpen = !o }
    function toggleMission() { if (locked) return; closePopups(); missionOpen = !missionOpen }
    function openContextMenu(items, p) { if (locked) return; closePopups(); contextPos = p; contextItems = items }
    function toggleLauncher() {
        if (locked) return
        if (win) { const o = startOpen; closePopups(); startOpen = !o; return }
        const o = launcherOpen; closePopups(); launcherOpen = !o
    }
    function toggleClipboard() { if (locked) return; const o = clipboardOpen; closePopups(); clipboardOpen = !o }
    function toggleCenter() { if (locked) return; const o = centerOpen; closePopups(); centerOpen = !o }
    function openMenu(name, x) { if (locked) return; const same = menu === name; closePopups(); if (!same) { menu = name; menuX = x } }
    function openPower(action) { if (locked) return; closePopups(); powerAction = action }

    // cmd: "sway:<orden>" (sobre la ventana enfocada), "app:<acción>" (app de BC enfocada),
    //      "bc:<acción>" (panel): launcher, lock, center, tiling, about, power:<acción>.
    // Lo atiende Panel.qml (así este singleton no depende del resto del módulo).
    function run(cmd) {
        const i = cmd.indexOf(":")
        const kind = cmd.substring(0, i), arg = cmd.substring(i + 1)
        if (kind === "bc") {
            if (arg === "launcher") toggleLauncher()
            else if (arg === "lock") { closePopups(); locked = true }
            else if (arg === "center") toggleCenter()
            else if (arg === "mission") toggleMission()
            else if (arg === "spotlight") toggleSpotlight()
            else if (arg === "clipboard") toggleClipboard()
            else if (arg === "widgetGallery") { closePopups(); widgetGalleryOpen = true }
            else if (arg.indexOf("power:") === 0) openPower(arg.substring(6))
            else command(kind, arg)
        } else command(kind, arg)
    }
}
