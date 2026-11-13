import QtQuick
import QtQuick.Shapes

// Fondo vectorial por degradados; sin desenfoque por CPU.
Item {
    id: root
    clip: true
    readonly property bool ready: wp.status === Image.Ready

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0a1236" }
            GradientStop { position: 0.55; color: "#0b1448" }
            GradientStop { position: 1.0; color: "#070c2c" }
        }
    }

    Shape {
        width: 1586
        height: 992
        scale: Math.max(root.width / 1586, root.height / 992)
        transformOrigin: Item.TopLeft

        // Barrido azul superior izquierdo
        ShapePath {
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0; y1: 0; x2: 700; y2: 500
                GradientStop { position: 0.0; color: "#3a55f5" }
                GradientStop { position: 0.6; color: "#3a3ee0" }
                GradientStop { position: 1.0; color: "#1e1f9a" }
            }
            PathSvg { path: "M0 0 L1180 0 C 1000 120 760 90 560 230 C 380 360 330 560 260 760 C 200 640 110 560 0 560 Z" }
        }
        // Ola violeta central/derecha
        ShapePath {
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 700; y1: 0; x2: 1500; y2: 420
                GradientStop { position: 0.0; color: "#5a63ff" }
                GradientStop { position: 0.55; color: "#4a35d8" }
                GradientStop { position: 1.0; color: "#181d78" }
            }
            PathSvg { path: "M700 0 L1330 0 C 1260 140 1100 240 1010 400 C 940 520 800 600 640 560 C 760 400 640 180 700 0 Z" }
        }
        // Banda oscura derecha
        ShapePath {
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 1100; y1: 0; x2: 1586; y2: 500
                GradientStop { position: 0.0; color: "#101a6a" }
                GradientStop { position: 1.0; color: "#0a1050" }
            }
            PathSvg { path: "M1180 0 L1586 0 L1586 640 C 1480 480 1300 380 1180 0 Z" }
        }
        // Ola inferior izquierda
        ShapePath {
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0; y1: 560; x2: 800; y2: 992
                GradientStop { position: 0.0; color: "#1c2395" }
                GradientStop { position: 1.0; color: "#0a1040" }
            }
            PathSvg { path: "M0 560 C 110 560 200 640 260 760 C 330 900 460 960 640 992 L0 992 Z" }
        }
        // Ola inferior derecha
        ShapePath {
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 800; y1: 992; x2: 1586; y2: 560
                GradientStop { position: 0.0; color: "#2a2cb4" }
                GradientStop { position: 0.6; color: "#4531cf" }
                GradientStop { position: 1.0; color: "#1a1f80" }
            }
            PathSvg { path: "M640 992 C 900 960 1060 780 1300 700 C 1420 660 1520 650 1586 690 L1586 992 Z" }
        }
        // Resplandor claro central
        ShapePath {
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: 1000; centerY: 140; centerRadius: 320; focalX: 1000; focalY: 140
                GradientStop { position: 0.0; color: "#885d6bff" }
                GradientStop { position: 1.0; color: "#005d6bff" }
            }
            PathSvg { path: "M600 -200 L1500 -200 L1500 480 L600 480 Z" }
        }
    }

    // Fondo por defecto de BC OS (el vectorial de arriba queda de respaldo si falla la carga).
    Image {
        id: wp
        anchors.fill: parent
        source: "qrc:/BCShell/assets/wallpaper-default.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        visible: status === Image.Ready
    }
}
