import QtQuick
import BCShell

// Icono de aplicación del tema BC (squircle ya incluido en el SVG).
Item {
    id: root
    property string kind: "archivos"
    property real size: 70
    property bool full: false      // papelera con elementos
    width: size
    height: size

    // Iconos de aplicación: tema MacOS-Like-Dark (Scrimas, sobre MacTahoe de vinceliuice; GPL-3.0).
    readonly property var names: ({
        lanzador: "view-app-grid",
        archivos: "system-file-manager",
        ajustes: "preferences-system",
        monitor: "utilities-system-monitor",
        terminal: "com.mitchellh.ghostty",
        tienda: "gnome-software",
        navegador: "firefox",
        musica: "multimedia-audio-player",
        papelera: "user-trash",
        notas: "accessories-notes",
        calculadora: "accessories-calculator",
        vista: "multimedia-photo-viewer"
    })

    Image {
        anchors.fill: parent
        source: root.kind === "papelera" && root.full ? "qrc:/BCShell/apps/user-trash-full.svg"
              : "qrc:/BCShell/apps/" + (root.names[root.kind] || "system-file-manager") + ".svg"
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: false
    }
}
