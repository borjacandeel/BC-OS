import QtQuick
import BCShell

// Pantalla de bloqueo del escritorio: misma estética que el login; verifica con PAM.
Item {
    id: root
    property bool active: false
    readonly property var me: Users.users.find(u => u.name === PamAuth.currentUser)
    property string displayName: me ? me.display : PamAuth.currentUser
    signal unlocked()
    anchors.fill: parent
    z: 5000
    opacity: active ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Theme.d(active ? Theme.durLock : Theme.durUnlock); easing.type: Easing.InOutCubic } }
    // Golden Gate: al desbloquear el reloj sube y se desvanece; al bloquear baja a su sitio
    property real lift: active ? 0 : -60
    Behavior on lift { NumberAnimation { duration: Theme.d(Theme.durUnlock); easing.type: Theme.easeEmphasized } }

    onActiveChanged: if (active) { panel.clear(); panel.busy = false; panel.focusField() }

    Rectangle { anchors.fill: parent; color: Theme.midnight }
    Wallpaper { anchors.fill: parent; source: Theme.gg ? "qrc:/BCShell/assets/wallpaper-default.png" : "qrc:/BCShell/assets/wallpaper-login.png" }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.01, 0.04, 0.10, 0.20) }
            GradientStop { position: 1.0; color: Qt.rgba(0.01, 0.04, 0.10, 0.65) }
        }
    }
    MouseArea { anchors.fill: parent; hoverEnabled: true; onClicked: panel.focusField() }

    BigClock {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(root.height * 0.07) + root.lift
        scale: Math.min(1, root.height / 800)
        transformOrigin: Item.Top
    }

    LoginPanel {
        id: panel
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(root.height * (Theme.gg ? 0.70 : 0.42))
        userName: PamAuth.currentUser
        displayName: root.displayName
        placeholder: qsTr("Introduce la contraseña")
        scale: Math.min(1, root.height / 800)
        transformOrigin: Item.Top
        onSubmitted: (password) => PamAuth.verify(password)
    }

    Connections {
        target: PamAuth
        function onFinished(ok) {
            if (!root.active) return
            if (ok) { panel.busy = false; root.unlocked() }
            else panel.fail(qsTr("Contraseña incorrecta"))
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 36
        text: qsTr("Pantalla bloqueada")
        color: Qt.rgba(1, 1, 1, 0.6)
        font.family: Theme.fontFamily
        font.pixelSize: 14
    }
}
