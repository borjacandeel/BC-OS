import QtQuick
import BCShell

// Icono de aplicación del tema BC (squircle ya incluido en el SVG).
Item {
    id: root
    property string kind: "archivos"
    property real size: 70
    width: size
    height: size

    readonly property var names: ({
        lanzador: "bc-launcher",
        archivos: "system-file-manager",
        ajustes: "preferences-system",
        monitor: "utilities-system-monitor",
        terminal: "utilities-terminal",
        tienda: "system-software-install",
        navegador: "web-browser",
        musica: "multimedia-audio-player",
        papelera: "user-trash"
    })

    Icon { anchors.fill: parent; size: root.size; name: root.names[root.kind] || "application-octet-stream" }
}
