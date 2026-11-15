import QtQuick
import QtQuick.Window
import BCShell

// Glifos de archivo: carpeta, código, texto, imagen, PDF. Las carpetas especiales (Descargas, Documentos, Imágenes,
// Música, Escritorio, Vídeos) usan su icono propio del tema, como en el Finder.
Item {
    id: root
    property string kind: "carpeta"
    property string path: ""
    width: 93
    height: 78

    readonly property var names: ({
        carpeta: "folder",
        codigo: "text-x-script",
        texto: "text-x-generic",
        imagen: "image-x-generic",
        pdf: "application-pdf"
    })
    readonly property string special: {
        if (kind !== "carpeta" || path === "") return ""
        const m = { downloads: "folder-download", documents: "folder-documents", pictures: "folder-pictures", music: "folder-music",
                    desktop: "folder-desktop", videos: "folder-videos", home: "user-home" }
        for (const k in m) if (Files.placePath(k) === path) { const p = Quick.iconPath(m[k]); if (p !== "") return "file://" + p }
        return ""
    }
    readonly property real dpr: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1

    Image {
        anchors.centerIn: parent
        width: Math.min(root.width, root.height * 1.0); height: width
        source: root.special !== "" ? root.special : "qrc:/BCShell/apps/" + (root.names[root.kind] || "text-x-generic") + ".svg"
        sourceSize: Qt.size(Math.ceil(width * root.dpr / 16) * 16, Math.ceil(width * root.dpr / 16) * 16)
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }
}
