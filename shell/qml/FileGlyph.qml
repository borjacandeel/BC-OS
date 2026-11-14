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

    Image {
        anchors.centerIn: parent
        width: 76; height: 76
        source: "qrc:/BCShell/qogir/" + (root.names[root.kind] || "text-x-generic") + ".svg"
        sourceSize: Qt.size(152, 152)
        fillMode: Image.PreserveAspectFit
        smooth: true
    }
}
