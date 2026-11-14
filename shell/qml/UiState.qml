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
    readonly property int barH: 41

    property string style: "mac"               // "mac" (barra superior + Dock) o "win" (barra de tareas + menú Inicio)
    readonly property bool win: style === "win"
    readonly property int taskH: 48
    readonly property int topInset: win ? 0 : barH
    property bool startOpen: false
    readonly property var pinned: [
        { kind: "archivos", name: qsTr("Archivos") }, { kind: "ajustes", name: qsTr("Configuración") },
        { kind: "monitor", name: qsTr("Monitor") }, { kind: "terminal", name: qsTr("Terminal") },
        { kind: "tienda", name: qsTr("Tienda") }, { kind: "navegador", name: qsTr("Navegador") },
        { kind: "musica", name: qsTr("Música") }, { kind: "papelera", name: qsTr("Papelera") }
    ]
    property bool centerOpen: false
    property bool launcherOpen: false
    property string menu: ""          // "", "system" o "m<índice>" (menús de la barra)
    property real menuX: 12
    property bool locked: false
    property string powerAction: ""
    readonly property bool popupOpen: centerOpen || launcherOpen || startOpen || menu !== "" || powerAction !== ""
    readonly property bool dim: launcherOpen || powerAction !== ""

    function closePopups() { centerOpen = false; launcherOpen = false; startOpen = false; menu = ""; powerAction = "" }
    function toggleLauncher() {
        if (win) { const o = startOpen; closePopups(); startOpen = !o; return }
        const o = launcherOpen; closePopups(); launcherOpen = !o
    }
    function toggleCenter() { const o = centerOpen; closePopups(); centerOpen = !o }
    function openMenu(name, x) { const same = menu === name; closePopups(); if (!same) { menu = name; menuX = x } }
    function openPower(action) { closePopups(); powerAction = action }

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
            else if (arg.indexOf("power:") === 0) openPower(arg.substring(6))
            else command(kind, arg)
        } else command(kind, arg)
    }
}
