import QtQuick
import BCShell

Item {
    id: root
    property real logoHeight: 34
    property bool withOs: false
    property color color: Theme.white
    implicitWidth: row.implicitWidth
    implicitHeight: logoHeight

    Row {
        id: row
        spacing: root.logoHeight * 0.4
        Image {
            height: root.logoHeight
            width: height * 2103 / 856
            // Logo oscuro cuando el color pedido es oscuro (barra de menús sobre un fondo claro)
            source: root.color.hslLightness < 0.5 ? "qrc:/BCShell/assets/BC-logo-oscuro.svg" : "qrc:/BCShell/assets/BC-logo-blanco.svg"
            sourceSize.height: root.logoHeight * 2
            smooth: true
        }
        Text {
            visible: root.withOs
            anchors.verticalCenter: parent.verticalCenter
            text: "OS"
            color: root.color
            font.family: Theme.fontFamily
            font.weight: Font.Black
            font.pixelSize: root.logoHeight * 1.2
            font.letterSpacing: 3
        }
    }
}
