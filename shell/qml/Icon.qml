import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property string path
    property color color: "#F5F5F7"
    property real size: 24
    property real strokeWidth: 1.8
    property bool filled: false
    width: size
    height: size

    Shape {
        width: 24
        height: 24
        scale: root.size / 24
        transformOrigin: Item.TopLeft
        ShapePath {
            strokeColor: root.color
            strokeWidth: root.strokeWidth
            fillColor: root.filled ? root.color : "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: root.path }
        }
    }
}
