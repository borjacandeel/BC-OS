import QtQuick
import BCShell

// Menú desplegable de la barra (logo BC o menús de la app enfocada).
Rectangle {
    id: card
    property var items: []
    signal activated(string cmd)
    width: 300
    height: col.height + 16
    radius: 14
    color: Qt.rgba(0.08, 0.13, 0.28, 0.97)
    border.width: 1
    border.color: Theme.hairline

    Column {
        id: col
        x: 8; y: 8
        width: parent.width - 16
        spacing: 2
        Repeater {
            model: card.items
            Item {
                required property var modelData
                width: col.width
                height: modelData.sep ? 9 : 32
                Rectangle {
                    visible: modelData.sep === true
                    anchors.verticalCenter: parent.verticalCenter
                    x: 8; width: parent.width - 16; height: 1; color: Theme.hairline
                }
                Rectangle {
                    visible: !modelData.sep
                    anchors.fill: parent
                    radius: 8
                    color: ia.containsMouse && !modelData.disabled ? Theme.accentSelected : "transparent"
                    opacity: modelData.disabled ? 0.45 : 1
                    Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: modelData.label || ""
                           color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 15 }
                    Text { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                           text: modelData.key || ""; color: Qt.rgba(1, 1, 1, 0.5)
                           font.family: Theme.fontFamily; font.pixelSize: 13 }
                    MouseArea {
                        id: ia
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !modelData.disabled
                        onClicked: card.activated(modelData.cmd)
                    }
                }
            }
        }
    }
}
