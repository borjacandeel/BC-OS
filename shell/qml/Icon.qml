import QtQuick
import QtQuick.Window
import BCShell

// Icono del tema BC por nombre Freedesktop. Los *-symbolic se tiñen con `color`.
Item {
    id: root
    property string name
    property color color: "#F5F5F7"
    property real size: 24
    property bool filled: false
    width: size
    height: size

    readonly property bool symbolic: name.endsWith("-symbolic")
    // Si no existe la variante rellena, se usa la normal
    property bool noFill: false
    onNameChanged: noFill = false
    readonly property string resolved: filled && !noFill && symbolic && name.indexOf("-fill-") < 0 ? name.replace("-symbolic", "-fill-symbolic") : name
    readonly property real dpr: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1

    Image {
        anchors.fill: parent
        sourceSize: Qt.size(Math.ceil(root.size * root.dpr), Math.ceil(root.size * root.dpr))
        fillMode: Image.PreserveAspectFit
        smooth: true
        opacity: root.symbolic ? root.color.a : 1
        onStatusChanged: if (status === Image.Error && root.filled && !root.noFill) root.noFill = true
        source: root.name === "" ? ""
              : root.symbolic ? IconCache.uri(root.resolved, root.color)
              : "qrc:/BCShell/icons/" + root.name + ".svg"
    }
}
