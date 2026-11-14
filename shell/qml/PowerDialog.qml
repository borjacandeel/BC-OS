import QtQuick
import BCShell

// Confirmación de apagar / reiniciar / suspender / cerrar sesión, con cuenta atrás.
Item {
    id: root
    property string action: ""
    property int remaining: 60
    signal confirmed(string action)
    signal cancelled()
    visible: opacity > 0
    opacity: 0
    anchors.fill: parent
    z: 900

    readonly property var texts: ({
        poweroff: { title: qsTr("¿Quieres apagar el equipo ahora?"), button: qsTr("Apagar"), icon: Icons.shutdown, countdown: true },
        reboot: { title: qsTr("¿Quieres reiniciar el equipo ahora?"), button: qsTr("Reiniciar"), icon: Icons.reboot, countdown: true },
        suspend: { title: qsTr("¿Quieres suspender el equipo?"), button: qsTr("Suspender"), icon: Icons.suspend, countdown: false },
        logout: { title: qsTr("¿Quieres cerrar la sesión?"), button: qsTr("Cerrar sesión"), icon: Icons.logout, countdown: true }
    })
    readonly property var current: texts[action] || texts.poweroff

    function open(a) {
        action = a
        remaining = 60
        opacity = 1
        card.forceActiveFocus()
        if (current.countdown) tick.restart()
    }
    function close() { tick.stop(); opacity = 0 }

    Behavior on opacity { NumberAnimation { duration: Theme.dur(180); easing.type: Theme.easing } }

    Timer {
        id: tick
        interval: 1000
        repeat: true
        onTriggered: {
            root.remaining -= 1
            if (root.remaining <= 0) { stop(); root.confirmed(root.action); root.close() }
        }
    }

    Rectangle { anchors.fill: parent; color: Theme.scrim }
    MouseArea { anchors.fill: parent; onClicked: { root.close(); root.cancelled() } }

    Rectangle {
        id: card
        width: 400; height: 250
        radius: 24
        anchors.centerIn: parent
        color: Qt.rgba(0.10, 0.15, 0.30, 0.96)
        border.width: 1
        border.color: Theme.hairline
        scale: root.opacity > 0.5 ? 1 : 0.92
        Behavior on scale { NumberAnimation { duration: Theme.dur(220); easing.type: Easing.OutBack } }
        focus: true
        Keys.onEscapePressed: { root.close(); root.cancelled() }
        Keys.onReturnPressed: { root.close(); root.confirmed(root.action) }
        MouseArea { anchors.fill: parent }

        Rectangle {
            id: badge
            width: 64; height: 64; radius: 32
            anchors.horizontalCenter: parent.horizontalCenter
            y: 26
            color: Qt.rgba(1, 1, 1, 0.12)
            Icon { anchors.centerIn: parent; name: root.current.icon; size: 32 }
        }
        Text {
            id: title
            anchors.top: badge.bottom
            anchors.topMargin: 16
            width: parent.width - 48
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.current.title
            color: Theme.white
            font.family: Theme.fontFamily
            font.pixelSize: 19
            font.weight: Font.DemiBold
        }
        Text {
            anchors.top: title.bottom
            anchors.topMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.current.countdown
            text: qsTr("Se hará automáticamente en %1 s.").arg(root.remaining)
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 14
        }
        Row {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 22
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14
            Rectangle {
                width: 150; height: 40; radius: 12
                color: cancelArea.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.14)
                Text { anchors.centerIn: parent; text: qsTr("Cancelar"); color: Theme.white
                       font.family: Theme.fontFamily; font.pixelSize: 16 }
                MouseArea { id: cancelArea; anchors.fill: parent; hoverEnabled: true
                            onClicked: { root.close(); root.cancelled() } }
            }
            Rectangle {
                width: 150; height: 40; radius: 12
                color: okArea.containsMouse ? Theme.accentSelected : Theme.accent
                Text { anchors.centerIn: parent; text: root.current.button; color: Theme.white
                       font.family: Theme.fontFamily; font.pixelSize: 16; font.weight: Font.DemiBold }
                MouseArea { id: okArea; anchors.fill: parent; hoverEnabled: true
                            onClicked: { root.close(); root.confirmed(root.action) } }
            }
        }
    }
}
