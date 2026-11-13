import QtQuick
import BCShell

Rectangle {
    id: card
    width: 321
    height: 80
    radius: 22
    color: Theme.panelFill
    border.width: 1
    border.color: Theme.hairline

    property string title: qsTr("Actualizaciones")
    property string body: qsTr("BC OS está al día")
    signal dismissed()

    Icon { x: 18; y: 22; name: Icons.refresh; size: 38; color: Theme.accent }
    Column {
        x: 75; anchors.verticalCenter: parent.verticalCenter; spacing: 3
        Text { text: card.title; color: Theme.textPrimary; font.family: Theme.fontFamily
               font.pixelSize: 15; font.weight: Font.DemiBold }
        Text { text: card.body; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 14 }
    }
    Item {
        x: parent.width - 46; y: 10; width: 36; height: 36
        Icon { anchors.centerIn: parent; name: Icons.closeX; size: 18; }
        MouseArea { anchors.fill: parent; onClicked: card.dismissed() }
    }
}
