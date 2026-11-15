import QtQuick
import BCShell

// Aviso emergente. Golden Gate: vidrio, icono de la app a la izquierda, título en negrita, hora y cierre al pasar.
// En la sesión «BC clásico» conserva el aspecto anterior.
Item {
    id: card
    width: 321
    height: 80
    property string title: qsTr("Actualizaciones")
    property string body: qsTr("BC OS está al día")
    property string app: "BC OS"
    signal dismissed()

    Glass { visible: !UiState.classic; anchors.fill: parent; radius: 20; tintBoost: 0.3 }
    Rectangle { visible: UiState.classic; anchors.fill: parent; radius: 22; color: Theme.panelFill; border.width: 1; border.color: Theme.hairline }

    Rectangle {
        visible: !UiState.classic
        x: 14; anchors.verticalCenter: parent.verticalCenter; width: 38; height: 38; radius: 9; color: Theme.fill
        Brand { anchors.centerIn: parent; logoHeight: 11 }
    }
    Icon { visible: UiState.classic; x: 18; y: 22; name: Icons.refresh; size: 38; color: Theme.accent }
    Column {
        x: UiState.classic ? 75 : 64; anchors.verticalCenter: parent.verticalCenter; spacing: 2; width: parent.width - x - 40
        Text { text: card.title; textFormat: Text.PlainText; color: UiState.classic ? Theme.textPrimary : Theme.label
               font.family: UiState.classic ? Theme.fontFamily : Theme.font; font.pixelSize: UiState.classic ? 15 : 13; font.weight: Font.Bold
               width: parent.width; elide: Text.ElideRight }
        Text { text: card.body; textFormat: Text.PlainText; color: UiState.classic ? Theme.textPrimary : Theme.label
               font.family: UiState.classic ? Theme.fontFamily : Theme.font; font.pixelSize: UiState.classic ? 14 : 13
               width: parent.width; elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.Wrap }
    }
    Text { visible: !UiState.classic; anchors.right: parent.right; anchors.rightMargin: 14; y: 14; text: qsTr("ahora")
           color: Theme.labelSecondary; font.family: Theme.font; font.pixelSize: 11 }
    Rectangle {
        visible: !UiState.classic && hov.containsMouse
        x: -6; y: -6; width: 20; height: 20; radius: 10; color: Theme.windowBg; border.width: 1; border.color: Theme.separator
        Text { anchors.centerIn: parent; text: "×"; color: Theme.label; font.pixelSize: 13 }
        MouseArea { anchors.fill: parent; onClicked: card.dismissed() }
    }
    Item {
        visible: UiState.classic
        x: parent.width - 46; y: 10; width: 36; height: 36
        Icon { anchors.centerIn: parent; name: Icons.closeX; size: 18; }
        MouseArea { anchors.fill: parent; onClicked: card.dismissed() }
    }
    MouseArea { id: hov; anchors.fill: parent; hoverEnabled: true; z: -1; onClicked: if (!UiState.classic) { card.dismissed(); UiState.toggleNotifCenter() } }
}
