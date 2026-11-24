import QtQuick
import BCShell

// Historial del portapapeles (Súper+V): elegir un elemento lo vuelve a copiar.
Rectangle {
    id: card
    signal closeRequested()
    width: Math.min(460, UiState.sw - 40)
    height: Math.min(440, UiState.sh - 120)
    radius: 20
    // Golden Gate: cristal como el resto de paneles (antes, caja gris plana)
    color: Theme.gg ? "transparent" : Theme.popupFill
    border.width: Theme.gg ? 0 : 1; border.color: Theme.hairline
    Glass { visible: Theme.gg; anchors.fill: parent; radius: card.radius; tintBoost: 0.3; z: -1 }

    function reset() { Clipboard.refresh(); list.currentIndex = 0; list.forceActiveFocus() }

    Text { x: 22; y: 16; text: qsTr("Portapapeles"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 16; font.weight: Font.DemiBold }
    Rectangle {
        anchors.right: parent.right; anchors.rightMargin: 16; y: 12; width: clr.implicitWidth + 24; height: 28; radius: 14
        color: ma0.containsMouse ? Theme.fillHover : Theme.fill; visible: Clipboard.items.length > 0
        Text { id: clr; anchors.centerIn: parent; text: qsTr("Borrar todo"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13 }
        MouseArea { id: ma0; anchors.fill: parent; hoverEnabled: true; onClicked: Clipboard.clear() }
    }
    ListView {
        id: list
        x: 12; y: 52; width: parent.width - 24; height: parent.height - 64
        clip: true; spacing: 2
        model: Clipboard.items
        keyNavigationEnabled: true
        Keys.onEscapePressed: card.closeRequested()
        Keys.onReturnPressed: if (currentItem) { Clipboard.pick(Clipboard.items[currentIndex].id); card.closeRequested() }
        delegate: Rectangle {
            required property var modelData
            required property int index
            width: list.width; height: 44; radius: 10
            color: ListView.isCurrentItem ? Theme.accentSelected : (ma.containsMouse ? Theme.fill : "transparent")
            Text { x: 14; width: parent.width - 28; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; maximumLineCount: 1
                   text: modelData.text; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 14 }
            MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true
                        onEntered: list.currentIndex = index
                        onClicked: { Clipboard.pick(modelData.id); card.closeRequested() } }
        }
        Text { visible: Clipboard.items.length === 0; anchors.centerIn: parent; horizontalAlignment: Text.AlignHCenter; width: parent.width - 40
               wrapMode: Text.WordWrap; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 15
               text: Clipboard.available ? qsTr("Todavía no has copiado nada") : qsTr("El historial no está disponible (falta cliphist)") }
    }
}
