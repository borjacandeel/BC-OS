import QtQuick
import QtQuick.Window
import BCShell

Window {
    id: win
    visible: true
    flags: Qt.FramelessWindowHint
    visibility: Qt.platform.pluginName === "wayland" ? Window.FullScreen : Window.Windowed
    width: 1280
    height: 800
    title: qsTr("Inicio de sesión de BC OS")
    color: Theme.midnight

    property int userIndex: 0
    readonly property var userList: Users.users
    readonly property var current: userList.length > 0 ? userList[Math.min(userIndex, userList.length - 1)] : ({ name: "bc", display: "BC" })

    Wallpaper { anchors.fill: parent; source: "qrc:/BCShell/assets/wallpaper-login.png" }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.01, 0.04, 0.10, 0.10) }
            GradientStop { position: 1.0; color: Qt.rgba(0.01, 0.04, 0.10, 0.55) }
        }
    }

    // Entrada suave del contenido.
    property real enter: 0
    NumberAnimation on enter { from: 0; to: 1; duration: Theme.dur(700); easing.type: Easing.OutCubic; running: true }

    BigClock {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(win.height * 0.07) - (1 - win.enter) * 20
        opacity: win.enter
        scale: Math.min(1, win.height / 800)
        transformOrigin: Item.Top
    }

    LoginPanel {
        id: panel
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(win.height * 0.42) + (1 - win.enter) * 30
        opacity: win.enter
        userName: win.current.name
        displayName: win.current.display
        scale: Math.min(1, win.height / 800)
        transformOrigin: Item.Top
        onSubmitted: (password) => Greetd.login(win.current.name, password)
        Component.onCompleted: focusField()
    }

    // Selector de usuario (solo si hay más de uno).
    Row {
        visible: win.userList.length > 1
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: panel.bottom
        anchors.topMargin: 8 * panel.scale
        spacing: 12
        opacity: win.enter
        Repeater {
            model: win.userList
            Rectangle {
                width: 38; height: 38; radius: 19
                color: index === win.userIndex ? Qt.rgba(1, 1, 1, 0.9) : Qt.rgba(1, 1, 1, 0.18)
                Text { anchors.centerIn: parent; text: modelData.display.charAt(0).toUpperCase()
                       color: index === win.userIndex ? Theme.midnight : Theme.white
                       font.family: Theme.fontFamily; font.pixelSize: 17; font.weight: Font.DemiBold }
                MouseArea { anchors.fill: parent; onClicked: { win.userIndex = index; panel.clear(); panel.focusField() } }
            }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(36 * Math.min(1, win.height / 800))
        spacing: 26
        opacity: win.enter
        PowerButton { icon: Icons.suspend; label: qsTr("Suspender"); onClicked: dialog.open("suspend") }
        PowerButton { icon: Icons.reboot; label: qsTr("Reiniciar"); onClicked: dialog.open("reboot") }
        PowerButton { icon: Icons.shutdown; label: qsTr("Apagar"); onClicked: dialog.open("poweroff") }
    }

    PowerDialog {
        id: dialog
        onConfirmed: (a) => { if (a === "poweroff") Power.poweroff(); else if (a === "reboot") Power.reboot(); else Power.suspend() }
        onCancelled: panel.focusField()
    }

    Rectangle {
        id: fade
        anchors.fill: parent
        color: Theme.midnight
        opacity: 0
        visible: opacity > 0
        z: 1000
        Brand { anchors.centerIn: parent; logoHeight: 56; opacity: fade.opacity }
    }
    SequentialAnimation {
        id: leave
        NumberAnimation { target: fade; property: "opacity"; to: 1; duration: Theme.dur(450); easing.type: Easing.InOutCubic }
        PauseAnimation { duration: Theme.dur(150) }
        ScriptAction { script: Qt.quit() }
    }

    Connections {
        target: Greetd
        function onAuthFailed(message) { panel.fail(message) }
        function onErrorOccurred(message) { panel.fail(message) }
        function onSucceeded() { leave.start() }
    }
}
