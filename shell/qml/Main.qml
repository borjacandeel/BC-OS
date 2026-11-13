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

    Loader { id: wallpaper; anchors.fill: parent; source: "Wallpaper.qml" }

    Loader {
        id: topbar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 41
        source: "TopBar.qml"
        onLoaded: item.controlCenterToggled.connect(() => root.centerOpen = !root.centerOpen)
    }

    Loader {
        id: files
        x: 117
        y: 207
        source: "FilesWindow.qml"
    }

    Loader {
        id: notif
        anchors.right: parent.right
        anchors.rightMargin: 14
        y: 53
        source: "NotificationCard.qml"
        active: root.notifOpen
        onLoaded: item.dismissed.connect(() => root.notifOpen = false)
        opacity: active ? 1 : 0
    }

    Loader {
        id: center
        anchors.right: parent.right
        anchors.rightMargin: 14
        y: 151
        source: "ControlCenter.qml"
        opacity: root.centerOpen ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur(160); easing.type: Theme.easing } }
    }

    Loader {
        id: brand
        anchors.left: parent.left
        anchors.leftMargin: 41
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 134
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
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 22
        source: "Dock.qml"
    }
}
