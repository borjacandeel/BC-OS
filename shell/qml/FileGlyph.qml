import QtQuick
import QtQuick.Shapes
import BCShell

// Glifos de archivo originales: carpeta, código, texto, imagen, PDF.
Item {
    id: root
    property string kind: "carpeta"
    width: 93
    height: 78

    Loader {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: root.kind === "carpeta" ? folder : doc
    }

    Component {
        id: folder
        Shape {
            width: 93; height: 76
            ShapePath {
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    x1: 0; y1: 0; x2: 0; y2: 76
                    GradientStop { position: 0.0; color: "#5cbcff" }
                    GradientStop { position: 1.0; color: "#2b7cf2" }
                }
                PathSvg { path: "M0 9Q0 0 9 0H30Q34 0 37 4L40 8H84Q93 8 93 17V64Q93 76 81 76H12Q0 76 0 64Z" }
            }
            ShapePath {
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    x1: 0; y1: 14; x2: 0; y2: 76
                    GradientStop { position: 0.0; color: "#6fc6ff" }
                    GradientStop { position: 1.0; color: "#2a79f0" }
                }
                PathSvg { path: "M0 22Q0 16 6 16H87Q93 16 93 22V64Q93 76 81 76H12Q0 76 0 64Z" }
            }
        }
    }

    Component {
        id: doc
        Item {
            width: 62; height: 78
            readonly property bool isImage: root.kind === "imagen"
            Rectangle {
                anchors.fill: parent
                radius: 8
                color: isImage ? "#2f86ff" : (root.kind === "texto" ? "#e4e6eb" : "#f5f6f8")
                gradient: isImage ? imgGrad : null
            }
            Gradient { id: imgGrad
                GradientStop { position: 0.0; color: "#4aa0ff" }
                GradientStop { position: 1.0; color: "#1f6eea" }
            }
            Loader {
                anchors.fill: parent
                sourceComponent: {
                    switch (root.kind) {
                    case "codigo": return codeMark
                    case "texto": return textMark
                    case "imagen": return imageMark
                    default: return pdfMark
                    }
                }
            }
        }
    }

    Component { id: codeMark
        Item {
            Text { anchors.centerIn: parent; text: "</>"; color: "#1b2230"
                   font.family: Theme.fontMono; font.pixelSize: 24; font.weight: Font.Bold } } }
    Component { id: textMark
        Column {
            x: 12; y: 24; spacing: 7
            Repeater { model: 4; Rectangle { width: index === 3 ? 22 : 38; height: 3; radius: 1.5; color: "#9aa0ad" } }
        } }
    Component { id: imageMark
        Item {
            Icon { anchors.centerIn: parent; path: "M3 20L10 9l4 6 3-4 4 9z"; size: 38; color: "white"; filled: true; strokeWidth: 1 }
        } }
    Component { id: pdfMark
        Item {
            Icon { anchors.centerIn: parent; path: "M12 3c1.5 5-1 9-6 12 4-.5 8-2 12-1.5 3 .5 3.5 2.5 1.5 3C15 17 12 11 12 3z"
                   size: 40; color: "#e0332f"; strokeWidth: 1.5 }
        } }
}
