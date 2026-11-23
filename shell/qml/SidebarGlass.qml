import QtQuick
import BCShell

// Barra lateral de Golden Gate: panel de cristal FLOTANTE (separado del borde de la ventana, esquinas redondeadas
// concéntricas con las de la ventana y filo luminoso fino), como en macOS 26/27. Deja ver el escritorio desenfocado
// (vibrancy), más oscuro en la ventana activa. Ocupa también la zona de la barra de título (semáforos dentro).
Item {
    id: sb
    property bool active: true
    readonly property int inset: Math.round(7 * Theme.s)
    Glass {
        anchors.fill: parent
        anchors.margins: sb.inset; anchors.rightMargin: Math.round(3 * Theme.s)
        visible: Theme.gg
        // radio concéntrico: el de la ventana menos el margen (la curva interior sigue a la exterior)
        radius: Math.max(8, Theme.windowRadius - sb.inset)
        shadow: false; rim: true
        tintColor: Theme.dark ? (sb.active ? "#1A1A1F" : "#24242A") : (sb.active ? "#E4E4E9" : "#EDEDF0")
        tintBoost: 0.28
    }
    Rectangle { visible: !Theme.gg; anchors.fill: parent; color: Theme.sidebarFill }
    Rectangle { visible: !Theme.gg; anchors.right: parent.right; width: 1; height: parent.height; color: Theme.hairline }
}
