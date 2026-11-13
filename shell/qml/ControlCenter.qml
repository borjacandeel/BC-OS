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

    property bool wifiOn: true
    property bool btOn: true
    property bool dnd: false
    property real volume: 0.66
    property real brightness: 0.6

    component Tile: Rectangle {
        id: tile
        property string iconPath
        property string label
        property string status
        property color iconColor: Theme.accent
        property bool active: true
        signal clicked()
        width: 109; height: 127; radius: Theme.radiusTile
        color: ta.containsMouse ? Qt.rgba(1, 1, 1, 0.11) : Theme.tileFill
        Behavior on color { ColorAnimation { duration: Theme.dur(120) } }
        Icon { anchors.horizontalCenter: parent.horizontalCenter; y: 24; name: tile.iconPath; size: 38
               color: tile.active ? tile.iconColor : Theme.textSecondary }
        Text { anchors.horizontalCenter: parent.horizontalCenter; y: 68; text: tile.label
               color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 16 }
        Text { anchors.horizontalCenter: parent.horizontalCenter; y: 92; text: tile.status
               color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 14 }
        MouseArea { id: ta; anchors.fill: parent; hoverEnabled: true; onClicked: tile.clicked() }
    }

    component SliderRow: Item {
        id: row
        property string iconPath
        property string label
        property real value: 0.5
        signal moved(real v)
        x: 16; width: parent.width - 32; height: 57
        Rectangle { x: 0; y: 5; width: 49; height: 49; radius: 24.5; color: Qt.rgba(1, 1, 1, 0.08) }
        Icon { x: 12; y: 17; name: row.iconPath; size: 26; }
        Text { x: 64; y: 2; text: row.label; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 16 }
        Rectangle { id: track; x: 65; y: 33; width: 227; height: 5; radius: 2.5; color: Qt.rgba(1, 1, 1, 0.14)
            Rectangle { width: row.value * parent.width; height: parent.height; radius: 2.5; color: Theme.accent
                        Behavior on width { NumberAnimation { duration: Theme.dur(90) } } }
            Rectangle { x: row.value * parent.width - 11; y: -8.5; width: 22; height: 22; radius: 11; color: "#e8eaf0"
                        border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.25) }
            MouseArea { x: -10; y: -14; width: parent.width + 20; height: 34
                onPositionChanged: (m) => { if (pressed) row.moved(Math.max(0, Math.min(1, (m.x - 10) / track.width))) }
                onPressed: (m) => row.moved(Math.max(0, Math.min(1, (m.x - 10) / track.width))) }
        }
        Icon { x: 324; y: 17; name: Icons.chevronRight; size: 24; color: Theme.textSecondary }
    }

    Row {
        x: 16; y: 14; spacing: 12
        Tile { iconPath: Icons.wifi; label: qsTr("Wi-Fi"); status: cc.wifiOn ? qsTr("Conectado") : qsTr("Desactivado")
               active: cc.wifiOn; onClicked: cc.wifiOn = !cc.wifiOn }
        Tile { iconPath: Icons.bluetooth; label: qsTr("Bluetooth"); status: cc.btOn ? qsTr("Activado") : qsTr("Desactivado")
               active: cc.btOn; onClicked: cc.btOn = !cc.btOn }
        Tile { iconPath: Icons.moon; label: qsTr("No molestar"); status: cc.dnd ? qsTr("Activado") : qsTr("Desactivado")
               iconColor: Theme.white; active: cc.dnd; onClicked: cc.dnd = !cc.dnd }
    }

    SliderRow { y: 167; iconPath: Icons.volume; label: qsTr("Sonido"); value: cc.volume; onMoved: (v) => cc.volume = v }
    SliderRow { y: 240; iconPath: Icons.sun; label: qsTr("Brillo"); value: cc.brightness; onMoved: (v) => cc.brightness = v }

    Rectangle {
        x: 16; y: 314; width: parent.width - 32; height: 57; radius: Theme.radiusTile
        color: Theme.tileFill
        Icon { x: 22; y: 16; name: Icons.bolt; size: 26; color: Theme.white }
        Text { x: 64; anchors.verticalCenter: parent.verticalCenter; text: qsTr("Energía")
               color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 16 }
        Icon { x: 320; y: 16; name: Icons.chevronRight; size: 24; color: Theme.textSecondary }
    }
}
