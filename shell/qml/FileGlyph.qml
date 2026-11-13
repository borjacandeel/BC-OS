import QtQuick
import BCShell

// Glifos de archivo del tema BC: carpeta, código, texto, imagen, PDF.
Item {
    id: root
    property string kind: "carpeta"
    width: 93
    height: 78

    readonly property var names: ({
        carpeta: "folder",
        codigo: "text-x-script",
        texto: "text-x-generic",
        imagen: "image-x-generic",
        pdf: "application-pdf"
    })

    Icon { anchors.centerIn: parent; size: 76; name: root.names[root.kind] || "application-octet-stream" }
}
