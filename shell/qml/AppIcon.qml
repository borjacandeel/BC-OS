import QtQuick
import QtQuick.Shapes
import BCShell

// Icono de aplicación original (rectángulo redondeado con degradado + glifo).
Item {
    id: root
    property string kind: "archivos"
    property real size: 70
    width: size
    height: size

    readonly property var gradients: ({
        archivos: ["#58b8ff", "#1f6fe8"],
        ajustes: ["#c9ced8", "#7b8392"],
        monitor: ["#1b2230", "#05080f"],
        terminal: ["#2a2d35", "#08090c"],
        tienda: ["#4cb4ff", "#1f5fe0"],
        navegador: ["#ffffff", "#dfe6f3"],
        musica: ["#ff6a78", "#e0203d"]
    })

    Rectangle {
        visible: root.kind !== "papelera"
        anchors.fill: parent
        radius: root.size * 0.235
        gradient: Gradient {
            GradientStop { position: 0.0; color: (root.gradients[root.kind] || ["#888", "#444"])[0] }
            GradientStop { position: 1.0; color: (root.gradients[root.kind] || ["#888", "#444"])[1] }
        }
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.18)
    }

    Loader {
        anchors.centerIn: parent
        sourceComponent: {
            switch (root.kind) {
            case "archivos": return glyphFolder
            case "ajustes": return glyphGear
            case "monitor": return glyphPulse
            case "terminal": return glyphPrompt
            case "tienda": return glyphBag
            case "navegador": return glyphCompass
            case "musica": return glyphMusic
            default: return glyphTrash
            }
        }
    }

    Component { id: glyphFolder; Icon { path: Icons.folder; size: root.size * 0.58; color: "white"; filled: true; strokeWidth: 1 } }
    Component { id: glyphGear; Icon { path: Icons.gear; size: root.size * 0.66; color: "#4a5160"; strokeWidth: 1.6 } }
    Component { id: glyphPulse; Icon { path: Icons.pulse; size: root.size * 0.7; color: "#34e27a"; strokeWidth: 1.8 } }
    Component { id: glyphPrompt; Icon { path: Icons.prompt; size: root.size * 0.58; color: "white"; strokeWidth: 2.2 } }
    Component { id: glyphBag; Icon { path: Icons.bag; size: root.size * 0.58; color: "white"; strokeWidth: 2 } }
    Component { id: glyphCompass; Icon { path: Icons.compass; size: root.size * 0.74; color: "#2f7bf5"; strokeWidth: 1.6 } }
    Component { id: glyphMusic; Icon { path: Icons.music; size: root.size * 0.56; color: "white"; strokeWidth: 2 } }
    Component { id: glyphTrash; Icon { path: Icons.trash; size: root.size * 0.78; color: Theme.silverMid; strokeWidth: 1.4 } }
}
