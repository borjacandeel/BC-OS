import QtQuick
import BCShell

Rectangle {
    id: bar
    height: 41
    color: Theme.barFill
    signal controlCenterToggled()
    signal systemMenuRequested()

    property date now: new Date()
    readonly property var loc: Qt.locale(AppConfig.language)

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: bar.now = AppConfig.fixedTime !== "" ? new Date(AppConfig.fixedTime) : new Date()
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.hairline
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 22
        anchors.verticalCenter: parent.verticalCenter
        spacing: 26
        Item {
            width: brandLogo.implicitWidth + 16
            height: bar.height
            anchors.verticalCenter: parent.verticalCenter
            Brand { id: brandLogo; logoHeight: 15; anchors.centerIn: parent }
            MouseArea { anchors.fill: parent; onClicked: bar.systemMenuRequested() }
        }
        Repeater {
            model: [qsTr("Archivos"), qsTr("Editar"), qsTr("Ver"), qsTr("Ir"), qsTr("Ventana"), qsTr("Ayuda")]
            Text {
                text: modelData
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 15
                font.weight: index === 0 ? Font.DemiBold : Font.Normal
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 18
        Icon { name: Icons.networkIcon(SystemStatus.online, SystemStatus.wired, SystemStatus.signalBars(SystemStatus.signal))
               size: 22; anchors.verticalCenter: parent.verticalCenter }
        Icon { name: Icons.volumeIcon(SystemStatus.volume, SystemStatus.muted); size: 22
               visible: SystemStatus.audioAvailable; anchors.verticalCenter: parent.verticalCenter }
        Icon { name: Icons.batteryIcon(SystemStatus.batteryPercent, SystemStatus.batteryCharging); size: 26
               visible: SystemStatus.hasBattery; anchors.verticalCenter: parent.verticalCenter }
        Rectangle {
            width: 36; height: 28; radius: 9
            anchors.verticalCenter: parent.verticalCenter
            color: ccArea.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.12)
            Icon { anchors.centerIn: parent; name: Icons.toggles; size: 20; }
            MouseArea {
                id: ccArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: bar.controlCenterToggled()
            }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 15
            text: bar.now.toLocaleDateString(bar.loc, "ddd d MMM").replace(".", "")
                  + "  " + bar.now.toLocaleTimeString(bar.loc, "HH:mm")
        }
    }
}
