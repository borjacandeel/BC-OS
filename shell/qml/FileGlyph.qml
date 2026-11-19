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
    // Documentos: icono del tipo de archivo del tema (PNG, PDF, ZIP, audio, vídeo, HTML…), como en el Finder
    readonly property string mimeIcon: {
        if (kind === "carpeta" || path === "") return ""
        const e = path.substring(path.lastIndexOf(".") + 1).toLowerCase()
        const m = { png: "image-png", jpg: "image-jpeg", jpeg: "image-jpeg", gif: "image-gif", webp: "image-webp", svg: "image-svg+xml",
                    bmp: "image-bmp", heic: "image-heif", pdf: "application-pdf", txt: "text-plain", md: "text-markdown",
                    zip: "application-zip", gz: "application-x-compressed-tar", xz: "application-x-xz-compressed-tar", tar: "application-x-tar",
                    "7z": "application-x-7z-compressed", rar: "application-x-rar", mp3: "audio-mpeg", flac: "audio-x-flac", ogg: "audio-x-vorbis+ogg",
                    wav: "audio-x-wav", m4a: "audio-mp4", mp4: "video-mp4", mkv: "video-x-matroska", webm: "video-webm", mov: "video-quicktime",
                    html: "text-html", htm: "text-html", css: "text-css", js: "application-javascript", json: "application-json",
                    py: "text-x-python", sh: "application-x-shellscript", c: "text-x-csrc", cpp: "text-x-c++src", h: "text-x-chdr",
                    qml: "text-x-qml", xml: "application-xml", iso: "application-x-cd-image", img: "application-x-raw-disk-image",
                    deb: "application-x-deb", appimage: "application-x-iso9660-appimage", odt: "application-vnd.oasis.opendocument.text",
                    docx: "application-vnd.openxmlformats-officedocument.wordprocessingml.document",
                    xlsx: "application-vnd.openxmlformats-officedocument.spreadsheetml.sheet", ttf: "font-x-generic", otf: "font-x-generic" }
        const generic = { imagen: "image-x-generic", codigo: "text-x-script", texto: "text-x-generic", pdf: "application-pdf" }
        for (const n of [m[e], generic[kind]]) { if (!n) continue; const p = Quick.iconPath(n); if (p !== "") return "file://" + p }
        return ""
    }
    readonly property real dpr: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1

    Image {
        anchors.centerIn: parent
        width: Math.min(root.width, root.height * 1.0); height: width
        source: root.special !== "" ? root.special : root.mimeIcon !== "" ? root.mimeIcon : "qrc:/BCShell/apps/" + (root.names[root.kind] || "text-x-generic") + ".svg"
        sourceSize: Qt.size(Math.ceil(width * root.dpr / 16) * 16, Math.ceil(width * root.dpr / 16) * 16)
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }
    // Emblemas de Finder: alias (flecha, abajo a la izquierda) y candado (archivo protegido, abajo a la derecha)
    readonly property string emblem: path !== "" && root.width >= 24 ? Quick.fileEmblem(path) : ""
    Image {
        visible: root.emblem !== ""
        width: Math.max(10, root.height * 0.34); height: width
        x: root.emblem === "alias" ? root.width / 2 - root.height / 2 + root.height * 0.04 : root.width / 2 + root.height / 2 - width - root.height * 0.04
        y: root.height - height - root.height * 0.04
        source: root.emblem === "alias" ? "qrc:/BCShell/apps/emblem-symbolic-link.svg" : root.emblem === "lock" ? "qrc:/BCShell/apps/emblem-readonly.svg" : ""
        sourceSize: Qt.size(Math.ceil(width * root.dpr), Math.ceil(width * root.dpr))
        smooth: true
    }
}
