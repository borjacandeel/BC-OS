import QtQuick
import BCShell

// Barra de tareas estilo Windows: Inicio, apps fijadas/abiertas al centro; bandeja y reloj a la derecha.
Rectangle {
    id: bar
    color: Theme.barFill
    signal launched(string kind, string name)
    property var running: []
    property date now: new Date()
    readonly property var loc: Qt.locale(AppConfig.language)

    Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.hairline }
    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true
            onTriggered: bar.now = AppConfig.fixedTime !== "" ? new Date(AppConfig.fixedTime) : new Date() }

    // Centro: Inicio + fijadas
    Row {
        id: center
        anchors.centerIn: parent
        spacing: 4
        Item {
            width: 44; height: 40
            Rectangle { anchors.fill: parent; radius: 8; color: UiState.startOpen ? Qt.rgba(1, 1, 1, 0.18) : (startMa.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent") }
            Brand { logoHeight: 15; anchors.centerIn: parent }
            MouseArea { id: startMa; anchors.fill: parent; hoverEnabled: true; onClicked: UiState.toggleLauncher() }
            Accessible.name: qsTr("Inicio")
        }
        Repeater {
            model: UiState.pinned
            delegate: Item {
                id: cell
                required property var modelData
                readonly property bool isRunning: bar.running.indexOf(modelData.kind) >= 0
                width: 44; height: 40
                Rectangle { anchors.fill: parent; radius: 8; color: ma.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent" }
                AppIcon { kind: cell.modelData.kind; size: 30; anchors.centerIn: parent; anchors.verticalCenterOffset: -2 }
                Rectangle { visible: cell.isRunning; width: 14; height: 3; radius: 1.5; color: Theme.accent
                            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 1 }
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: bar.launched(cell.modelData.kind, cell.modelData.name) }
                Accessible.name: cell.modelData.name
            }
        }
    }

    // Bandeja y reloj
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14
        Rectangle {
            width: 32; height: 28; radius: 8; anchors.verticalCenter: parent.verticalCenter
            color: tileMa.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : (Sway.tiling ? Qt.rgba(0.18, 0.48, 0.96, 0.55) : Qt.rgba(1, 1, 1, 0.12))
            Icon { anchors.centerIn: parent; name: Sway.tiling ? "view-grid-symbolic" : "window-restore-symbolic"; size: 18 }
            MouseArea { id: tileMa; anchors.fill: parent; hoverEnabled: true; onClicked: Sway.toggleTiling() }
        }
        Icon { name: Icons.networkIcon(SystemStatus.online, SystemStatus.wired, SystemStatus.signalBars(SystemStatus.signal)); size: 20; anchors.verticalCenter: parent.verticalCenter }
        Icon { name: Icons.volumeIcon(SystemStatus.volume, SystemStatus.muted); size: 20; visible: SystemStatus.audioAvailable; anchors.verticalCenter: parent.verticalCenter }
        Icon { name: Icons.batteryIcon(SystemStatus.batteryPercent, SystemStatus.batteryCharging); size: 24; visible: SystemStatus.hasBattery; anchors.verticalCenter: parent.verticalCenter }
        Rectangle {
            width: 36; height: 28; radius: 9; anchors.verticalCenter: parent.verticalCenter
            color: ccMa.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.12)
            Icon { anchors.centerIn: parent; name: Icons.toggles; size: 20 }
            MouseArea { id: ccMa; anchors.fill: parent; hoverEnabled: true; onClicked: UiState.toggleCenter() }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Text { anchors.right: parent.right; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 14
                   text: bar.now.toLocaleTimeString(bar.loc, "HH:mm") }
            Text { anchors.right: parent.right; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12
                   text: bar.now.toLocaleDateString(bar.loc, "d/M/yyyy") }
        }
    }
}
