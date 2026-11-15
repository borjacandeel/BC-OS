import QtQuick
import BCShell

// Barra lateral de borde a borde de Golden Gate: material translúcido que deja ver el escritorio desenfocado
// (vibrancy), más oscuro en la ventana activa. Ocupa también la zona de la barra de título.
Item {
    id: sb
    property bool active: true
    Glass {
        anchors.fill: parent
        visible: Theme.gg
        radius: Theme.windowRadius; leftOnly: true
        shadow: false; rim: false
        tintColor: Theme.dark ? (sb.active ? "#1A1A1F" : "#24242A") : (sb.active ? "#E4E4E9" : "#EDEDF0")
        tintBoost: 0.28
    }
    Rectangle { visible: !Theme.gg; anchors.fill: parent; color: Theme.sidebarFill }
    Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.hairline }
}
