import QtQuick
import BCShell

// BC Centro de control.
Rectangle {
    id: cc
    width: 381
    height: 387
    radius: Theme.radiusPanel
    color: Theme.panelFill
    border.width: 1
    border.color: Theme.hairline

    readonly property bool wifiOn: SystemStatus.online
    readonly property int bars: SystemStatus.signalBars(SystemStatus.signal)

    component Tile: Rectangle {
        id: tile
        property string iconPath
        property string label
        property string status
        property color iconColor: Theme.accent
        property bool active: true
        property bool available: true
        signal clicked()
        width: 109; height: 127; radius: Theme.radiusTile
        opacity: tile.available ? 1 : 0.5
        color: ta.containsMouse ? Qt.rgba(1, 1, 1, 0.11) : Theme.tileFill
        Behavior on color { ColorAnimation { duration: Theme.dur(120) } }
        Icon { anchors.horizontalCenter: parent.horizontalCenter; y: 24; name: tile.iconPath; size: 38
               color: tile.active ? tile.iconColor : Theme.textSecondary }
        Text { anchors.horizontalCenter: parent.horizontalCenter; y: 68; text: tile.label
               color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 16 }
        Text { anchors.horizontalCenter: parent.horizontalCenter; y: 92; text: tile.status; width: parent.width - 12
               horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
               color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 14 }
        MouseArea { id: ta; anchors.fill: parent; hoverEnabled: true; enabled: tile.available; onClicked: tile.clicked() }
    }

    component SliderRow: Item {
        id: row
        property string iconPath
        property string label
        property real value: 0.5
        property bool available: true
        property string unavailableText: qsTr("No disponible")
        signal moved(real v)
        signal iconClicked()
        opacity: row.available ? 1 : 0.45
        x: 16; width: parent.width - 32; height: 57
        Rectangle { x: 0; y: 5; width: 49; height: 49; radius: 24.5; color: Qt.rgba(1, 1, 1, 0.08) }
        Icon { x: 12; y: 17; name: row.iconPath; size: 26; }
        MouseArea { x: 0; y: 5; width: 49; height: 49; enabled: row.available; onClicked: row.iconClicked() }
        Text { x: 64; y: 2; text: row.available ? row.label : row.label + " · " + row.unavailableText; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 16 }
        Rectangle { id: track; x: 65; y: 33; width: 227; height: 5; radius: 2.5; color: Qt.rgba(1, 1, 1, 0.14)
            Rectangle { width: row.value * parent.width; height: parent.height; radius: 2.5; color: Theme.accent
                        Behavior on width { NumberAnimation { duration: Theme.dur(90) } } }
            Rectangle { x: row.value * parent.width - 11; y: -8.5; width: 22; height: 22; radius: 11; color: "#e8eaf0"
                        border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.25) }
            MouseArea { x: -10; y: -14; width: parent.width + 20; height: 34; enabled: row.available
                onPositionChanged: (m) => { if (pressed) row.moved(Math.max(0, Math.min(1, (m.x - 10) / track.width))) }
                onPressed: (m) => row.moved(Math.max(0, Math.min(1, (m.x - 10) / track.width))) }
        }
        Icon { x: 324; y: 17; name: Icons.chevronRight; size: 24; color: Theme.textSecondary }
    }

    Row {
        x: 16; y: 14; spacing: 12
        Tile {
            iconPath: Icons.networkIcon(SystemStatus.online, SystemStatus.wired, cc.bars)
            label: SystemStatus.hasWifi ? qsTr("Wi-Fi") : qsTr("Red")
            status: SystemStatus.online ? (SystemStatus.connection !== "" ? SystemStatus.connection : qsTr("Conectado"))
                    : (SystemStatus.hasWifi && !SystemStatus.wifiEnabled ? qsTr("Desactivado") : qsTr("Sin conexión"))
            active: SystemStatus.online
            available: SystemStatus.hasWifi
            onClicked: SystemStatus.setWifi(!SystemStatus.wifiEnabled)
        }
        Tile {
            iconPath: Icons.bluetooth; label: qsTr("Bluetooth")
            status: !SystemStatus.bluetoothAvailable ? qsTr("No disponible") : (SystemStatus.bluetoothOn ? qsTr("Activado") : qsTr("Desactivado"))
            active: SystemStatus.bluetoothOn; available: SystemStatus.bluetoothAvailable
            onClicked: SystemStatus.setBluetooth(!SystemStatus.bluetoothOn)
        }
        Tile {
            iconPath: Icons.moon; label: qsTr("No molestar"); status: SystemStatus.dnd ? qsTr("Activado") : qsTr("Desactivado")
            iconColor: Theme.white; active: SystemStatus.dnd; onClicked: SystemStatus.dnd = !SystemStatus.dnd
        }
    }

    SliderRow {
        y: 167; iconPath: Icons.volumeIcon(SystemStatus.volume, SystemStatus.muted); label: qsTr("Sonido")
        value: SystemStatus.muted ? 0 : Math.min(1, SystemStatus.volume); available: SystemStatus.audioAvailable
        onMoved: (v) => SystemStatus.setVolume(v)
        onIconClicked: SystemStatus.toggleMute()
    }
    SliderRow {
        y: 240; iconPath: Icons.sun; label: qsTr("Brillo")
        value: SystemStatus.brightness; available: SystemStatus.hasBacklight
        onMoved: (v) => SystemStatus.setBrightness(v)
    }

    Rectangle {
        x: 16; y: 314; width: parent.width - 32; height: 57; radius: Theme.radiusTile
        color: Theme.tileFill
        Icon { x: 22; y: 16; name: SystemStatus.hasBattery ? Icons.batteryIcon(SystemStatus.batteryPercent, SystemStatus.batteryCharging) : Icons.bolt
               size: 26; color: Theme.white }
        Text { x: 64; anchors.verticalCenter: parent.verticalCenter
               text: SystemStatus.hasBattery
                     ? (SystemStatus.batteryCharging ? qsTr("Batería %1 % · cargando").arg(SystemStatus.batteryPercent)
                                                      : qsTr("Batería %1 %").arg(SystemStatus.batteryPercent))
                     : qsTr("Conectado a la corriente")
               color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 16 }
    }
}
