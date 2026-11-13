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
    property bool notifOpen: true
    property bool filesOpen: true
    property string notifHeading: qsTr("Actualizaciones")
    property string notifText: qsTr("BC OS está al día")

    // Escala única respecto al diseño (1586x992), acotada: el escritorio se adapta a cualquier tamaño.
    readonly property real u: Math.max(0.6, Math.min(1.25, Math.min(width / 1586, height / 992)))
    readonly property real margin: Math.round(14 * u)
    readonly property real topH: 41
    readonly property real dockTop: root.height - dock.height * u - Math.round(22 * u)
    readonly property real rightColW: (center.width > 0 ? center.width : 381) * u + margin * 2

    function showNotice(title, text) {
        notifHeading = title
        notifText = text
        notifOpen = true
        noticeTimer.restart()
    }
    function launch(kind, name) {
        const r = Launcher.launch(kind)
        if (kind === "archivos") filesOpen = true
        else if (r === "unavailable") showNotice(name, qsTr("En desarrollo"))
        else if (r === "failed") showNotice(name, qsTr("No se pudo abrir la aplicación"))
    }
    Timer { id: noticeTimer; interval: 4000; onTriggered: root.notifOpen = false }

    Loader { id: wallpaper; anchors.fill: parent; source: "Wallpaper.qml" }

    Loader {
        id: topbar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.topH
        source: "TopBar.qml"
        onLoaded: item.controlCenterToggled.connect(() => root.centerOpen = !root.centerOpen)
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
        id: notif
        active: root.notifOpen
        source: "NotificationCard.qml"
        scale: root.u
        transformOrigin: Item.TopRight
        x: root.width - root.margin - width
        y: root.topH + root.margin
        onLoaded: item.dismissed.connect(() => root.notifOpen = false)
        Binding { target: notif.item; property: "title"; value: root.notifHeading; when: notif.item }
        Binding { target: notif.item; property: "body"; value: root.notifText; when: notif.item }
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
        visible: x + width * root.u + root.margin < dock.x + dock.width * (1 - root.u) / 2
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
            item.running = Qt.binding(() => Launcher.running.concat(root.filesOpen ? ["archivos"] : []))
        }
    }
}
