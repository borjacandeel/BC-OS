import QtQuick
import BCShell

// Animación de entrada para ventanas emergentes: se desliza unos píxeles y aparece al hacerse visible.
// Uso: SlideIn { target: tarjeta; dy: -10 }   (fade: false si el propio elemento ya anima su opacidad)
Item {
    id: root
    property Item target
    property real dx: 0
    property real dy: -10
    property int duration: 200
    property bool fade: true
    width: 0; height: 0
    visible: false

    Translate { id: tr }
    Component.onCompleted: if (target) target.transform = [tr]

    Connections {
        target: root.target
        function onVisibleChanged() { if (root.target && root.target.visible && !Theme.reducedMotion) anim.restart() }
    }
    ParallelAnimation {
        id: anim
        NumberAnimation { target: tr; property: "x"; from: root.dx; to: 0; duration: root.duration; easing.type: Easing.OutCubic }
        NumberAnimation { target: tr; property: "y"; from: root.dy; to: 0; duration: root.duration; easing.type: Easing.OutCubic }
        NumberAnimation { target: root.fade ? root.target : null; property: "opacity"; from: 0; to: 1; duration: root.duration * 0.8; easing.type: Easing.OutQuad }
    }
}
