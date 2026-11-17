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
    onUserIndexChanged: if (userList.length > 0) Sessions.selectFor(current.name)
    Component.onCompleted: Sessions.selectFor(current.name)
    readonly property var current: userList.length > 0 ? userList[Math.min(userIndex, userList.length - 1)] : ({ name: "bc", display: "BC" })

    Wallpaper { anchors.fill: parent; visible: !Theme.gg; source: "qrc:/BCShell/assets/wallpaper-login.png" }
    // Golden Gate: el fondo del usuario (copia en /var/lib/bc-greeter), desenfocado como el login de macOS.
    // Desenfoque barato: la imagen se carga diminuta y se amplía con filtrado suave (dos pasadas)
    Item {
        anchors.fill: parent; visible: Theme.gg
        Image {
            anchors.fill: parent; fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true
            sourceSize: Qt.size(Math.max(640, win.width), Math.max(400, win.height))
            source: "image://blur/" + encodeURIComponent("/var/lib/bc-greeter/fondo-" + win.current.name)
        }
        Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.18) }
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.01, 0.04, 0.10, Theme.gg ? 0.05 : 0.10) }
            GradientStop { position: 1.0; color: Qt.rgba(0.01, 0.04, 0.10, Theme.gg ? 0.40 : 0.55) }
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
        y: Math.round(win.height * (Theme.gg ? 0.60 : 0.42)) + (1 - win.enter) * 30
        opacity: win.enter
        userName: win.current.name
        displayName: win.current.display
        scale: Math.min(1, win.height / 800)
        transformOrigin: Item.Top
        onSubmitted: (password) => Greetd.login(win.current.name, password)
        Component.onCompleted: focusField()
    }

    // Entorno de escritorio: pastilla discreta bajo la contraseña (pulsar alterna BC OS / Dotfiles), como el menú de
    // sesión de los logins de macOS con varias opciones
    Rectangle {
        visible: Sessions.sessions.length > 1
        x: parent.width - width - 24; y: parent.height - height - 24
        height: 26; width: sesT.implicitWidth + 34; radius: 13
        color: sesM.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.12)
        border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.16)
        opacity: win.enter
        Text { id: sesT; anchors.centerIn: parent; anchors.horizontalCenterOffset: -5
               text: Sessions.sessions.length ? Sessions.sessions[Math.max(0, Sessions.current)].name : ""
               color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: Font.Medium }
        Text { anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; anchors.rightMargin: 10
               text: "⌄"; color: Qt.rgba(1, 1, 1, 0.7); font.pixelSize: 11 }
        MouseArea { id: sesM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { Sessions.current = (Sessions.current + 1) % Sessions.sessions.length; panel.focusField() } }
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

    // macOS: Reposo, Reiniciar y Apagar abajo, con iconos redondos de vidrio y su nombre
    Row {
        visible: Theme.gg
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: Math.round(34 * Math.min(1, win.height / 800))
        spacing: 34
        opacity: win.enter
        Repeater {
            model: [ { i: Icons.suspend, t: qsTr("Reposo"), a: "suspend" }, { i: Icons.reboot, t: qsTr("Reiniciar"), a: "reboot" },
                     { i: Icons.shutdown, t: qsTr("Apagar"), a: "poweroff" } ]
            Column {
                required property var modelData
                spacing: 6
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 40; height: 40; radius: 20
                    color: pbm.containsMouse ? Qt.rgba(1, 1, 1, 0.26) : Qt.rgba(1, 1, 1, 0.14)
                    border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.18)
                    Behavior on color { ColorAnimation { duration: Theme.dur(140) } }
                    Icon { anchors.centerIn: parent; name: modelData.i; size: 18; color: Theme.white }
                    MouseArea { id: pbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: dialog.open(modelData.a) }
                }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.t; color: Qt.rgba(1, 1, 1, 0.85)
                       font.family: Theme.fontFamily; font.pixelSize: 12 }
            }
        }
    }
    Rectangle {
        visible: false
        x: parent.width - width - 14; y: 9; width: 28; height: 28; radius: 14
        color: pwm.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : "transparent"; opacity: win.enter
        Icon { anchors.centerIn: parent; name: Icons.shutdown; size: 16; color: Theme.white }
        MouseArea { id: pwm; anchors.fill: parent; hoverEnabled: true; onClicked: pwMenu.visible = !pwMenu.visible }
    }
    Column {
        id: pwMenu; visible: false
        x: parent.width - width - 14; y: 42; width: 170
        Repeater {
            model: [ { t: qsTr("Suspender"), a: "suspend" }, { t: qsTr("Reiniciar…"), a: "reboot" }, { t: qsTr("Apagar…"), a: "poweroff" } ]
            Rectangle {
                required property var modelData
                width: 170; height: 30; radius: 8; color: mi.containsMouse ? Theme.accent : Qt.rgba(0.12, 0.12, 0.16, 0.86)
                Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: modelData.t; color: "white"; font.family: Theme.fontFamily; font.pixelSize: 13 }
                MouseArea { id: mi; anchors.fill: parent; hoverEnabled: true; onClicked: { pwMenu.visible = false; dialog.open(modelData.a) } }
            }
        }
    }
    Row {
        visible: !Theme.gg
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
