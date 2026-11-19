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
    // Liquid Glass (Golden Gate): además de deslizarse, el cristal «brota» desde su origen con un leve muelle.
    // El origen por defecto es el borde por el que entra (arriba si baja, abajo si sube, el lateral si entra de lado).
    property real fromScale: Theme.gg && dx === 0 && Render.scaleAnimations ? 0.94 : 1   // por software, sin escalar (CPU)
    property real originX: target ? (dx > 0 ? target.width : (dx < 0 ? 0 : target.width / 2)) : 0
    property real originY: target ? (dy > 0 ? target.height : (dy < 0 ? 0 : target.height / 2)) : 0
    width: 0; height: 0
    visible: false

    Translate { id: tr }
    Scale { id: sc; origin.x: root.originX; origin.y: root.originY }
    Component.onCompleted: if (target) target.transform = [sc, tr]

    function play() { if (root.target && !Theme.reducedMotion) anim.restart() }
    Connections {
        target: root.target
        function onVisibleChanged() { if (root.target && root.target.visible && !Theme.reducedMotion) anim.restart() }
    }
    ParallelAnimation {
        id: anim
        NumberAnimation { target: tr; property: "x"; from: root.dx; to: 0; duration: root.duration; easing.type: Easing.OutCubic }
        NumberAnimation { target: tr; property: "y"; from: root.dy; to: 0; duration: root.duration; easing.type: Easing.OutCubic }
        NumberAnimation { target: root.fade ? root.target : null; property: "opacity"; from: 0; to: 1; duration: root.duration * 0.8; easing.type: Easing.OutQuad }
        NumberAnimation { target: sc; properties: "xScale,yScale"; from: root.fromScale; to: 1; duration: root.duration * 1.25
                          easing.type: Easing.OutBack; easing.overshoot: 0.7 }
    }
}
