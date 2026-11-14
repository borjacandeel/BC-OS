import QtQuick
import BCShell

// Botón circular con icono y etiqueta (Suspender, Reiniciar, Apagar...).
Item {
    id: root
    property string icon
    property string label
    signal clicked()
    width: 84
    height: 84

    Rectangle {
        id: disc
        width: 52; height: 52; radius: 26
        anchors.horizontalCenter: parent.horizontalCenter
        color: area.pressed ? Qt.rgba(1, 1, 1, 0.34) : (area.containsMouse ? Qt.rgba(1, 1, 1, 0.24) : Qt.rgba(1, 1, 1, 0.14))
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.18)
        scale: area.pressed ? 0.94 : (area.containsMouse ? 1.06 : 1)
        Behavior on scale { NumberAnimation { duration: Theme.dur(140); easing.type: Theme.easing } }
        Behavior on color { ColorAnimation { duration: Theme.dur(140) } }
        Icon { anchors.centerIn: parent; name: root.icon; size: 24 }
    }
    Text {
        anchors.top: disc.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.label
        color: Qt.rgba(1, 1, 1, 0.85)
        font.family: Theme.fontFamily
        font.pixelSize: 13
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
