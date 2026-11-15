import QtQuick
import QtQuick.Window
import BCShell

// Ventana de aplicación de BC (xdg-toplevel propio): barra de título con semáforo, arrastre y redimensionado por el compositor.
Window {
    id: win
    default property alias content: contentArea.data
    property alias titlebarContent: tbSlot.data
    property int titlebarHeight: Theme.gg ? 52 : 44
    // Posición en pantalla (sway) para que el cristal de las barras laterales recorte el fondo correcto
    readonly property real originX: Quick.windowPos.x
    readonly property real originY: Quick.windowPos.y
    Binding { target: Quick; property: "trackWindow"; value: Theme.gg && win.active }
    signal closeRequested()
    visible: true
    color: "transparent"
    flags: Qt.FramelessWindowHint
    minimumWidth: 480
    minimumHeight: 320

    onClosing: (c) => { c.accepted = false; win.closeRequested() }
    onCloseRequested: { if (Theme.reducedMotion) Qt.quit(); else closeAnim.start() }
    ParallelAnimation {
        id: closeAnim
        NumberAnimation { target: frame; property: "scale"; to: Theme.gg ? 0.92 : 0.94; duration: Theme.gg ? Theme.durWindowClose : 140; easing.type: Easing.InCubic }
        NumberAnimation { target: frame; property: "opacity"; to: 0; duration: Theme.gg ? Theme.durWindowClose : 140 }
        onFinished: Qt.quit()
    }

    Connections {
        target: AppActions
        function onActionInvoked(a) {
            if (a === "close") win.closeRequested()
            else if (a === "fullscreen") WindowControl.toggleFullscreen()
            else if (a === "minimize") win.minimizeAnimated()
        }
    }
    // Minimizar: la ventana se encoge hacia el Dock y pasa al scratchpad de sway; al volver, se despliega.
    function minimizeAnimated() {
        if (Theme.reducedMotion) { WindowControl.minimize(); return }
        // Golden Gate: el panel hace el efecto genio hacia el Dock (captura la ventana y la minimiza)
        if (Theme.gg && Launcher.run("bc-ctl", ["minimize"])) return
        minAnim.restart()
    }
    onActiveChanged: if (active && frame.opacity < 0.1) {
        frame.transformOrigin = Item.Bottom
        frame.scale = 1
        frame.opacity = 1
    }
    SequentialAnimation {
        id: minAnim
        ScriptAction { script: frame.transformOrigin = Item.Bottom }
        ParallelAnimation {
            NumberAnimation { target: frame; property: "scale"; to: 0.55; duration: 200; easing.type: Easing.InCubic }
            NumberAnimation { target: frame; property: "opacity"; to: 0; duration: 200; easing.type: Easing.InCubic }
        }
        ScriptAction { script: WindowControl.minimize() }
    }
    Shortcut { sequence: "Ctrl+W"; onActivated: win.closeRequested() }

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: Theme.radiusWindow
        color: Theme.gg && !win.active ? Theme.windowBgInactive : Theme.windowFill
        border.width: 1
        border.color: Theme.gg ? (Theme.dark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.16)) : Theme.hairline
        Behavior on color { ColorAnimation { duration: Theme.d(Theme.durHover) } }
        clip: true
        scale: Theme.gg ? 0.94 : 0.97
        opacity: 0
        transformOrigin: Item.Center
        Component.onCompleted: { scale = 1; opacity = 1 }
        Behavior on scale { NumberAnimation { duration: Theme.dur(Theme.gg ? Theme.durWindowOpen : 220); easing.type: Theme.gg ? Theme.easeEmphasized : Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.gg ? Theme.durWindowOpen * 0.8 : 180); easing.type: Theme.easing } }

        Rectangle {
            id: titlebar
            z: 2      // por encima del contenido: las barras laterales de borde a borde suben bajo el semáforo
            width: parent.width
            height: win.titlebarHeight
            color: Theme.gg ? "transparent" : Qt.rgba(1, 1, 1, 0.04)
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.hairline }
            MouseArea { id: tlHover; x: 0; width: 90; height: parent.height; hoverEnabled: true; acceptedButtons: Qt.NoButton; z: 2 }
            MouseArea {
                anchors.fill: parent
                onPressed: win.startSystemMove()
                onDoubleClicked: WindowControl.toggleFullscreen()
            }
            Row {
                x: Theme.gg ? Theme.trafficLeft + 4 : 16; anchors.verticalCenter: parent.verticalCenter; spacing: Theme.gg ? Theme.trafficGap : 9
                z: 3
                Repeater {
                    model: [{ c: Theme.close, a: 0, g: "×" }, { c: Theme.minimize, a: 1, g: "−" }, { c: Theme.zoom, a: 2, g: "⤢" }]
                    Rectangle {
                        readonly property int d: Theme.gg ? Theme.trafficSize : 14
                        width: d; height: d; radius: d / 2
                        color: !Theme.gg || win.active || tlHover.containsMouse ? modelData.c : Theme.trafficInactive
                        Text { anchors.centerIn: parent; visible: Theme.gg && tlHover.containsMouse; text: modelData.g; color: Qt.rgba(0, 0, 0, 0.55)
                               font.pixelSize: parent.d - 2; font.weight: Font.Black }
                        MouseArea {
                            anchors.fill: parent; anchors.margins: -3
                            onClicked: modelData.a === 0 ? win.closeRequested() : (modelData.a === 1 ? win.minimizeAnimated() : WindowControl.toggleFullscreen())
                        }
                    }
                }
            }
            Text {
                visible: tbSlot.children.length === 0
                anchors.centerIn: parent
                text: win.title
                color: Theme.gg && !win.active ? Theme.labelSecondary : Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.gg ? 13 : 15
                font.weight: Theme.gg ? Font.Bold : Font.DemiBold
            }
            Item { id: tbSlot; anchors.fill: parent }
        }

        Item {
            id: contentArea
            anchors.top: titlebar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
        }
    }

    // Bordes de redimensionado (el compositor hace el trabajo).
    component Edge: MouseArea {
        property int edges: 0
        hoverEnabled: true
        onPressed: win.startSystemResize(edges)
    }
    Edge { edges: Qt.LeftEdge; x: 0; y: 10; width: 5; height: parent.height - 20; cursorShape: Qt.SizeHorCursor }
    Edge { edges: Qt.RightEdge; x: parent.width - 5; y: 10; width: 5; height: parent.height - 20; cursorShape: Qt.SizeHorCursor }
    Edge { edges: Qt.BottomEdge; x: 10; y: parent.height - 5; width: parent.width - 20; height: 5; cursorShape: Qt.SizeVerCursor }
    Edge { edges: Qt.TopEdge; x: 10; y: 0; width: parent.width - 20; height: 4; cursorShape: Qt.SizeVerCursor }
    Edge { edges: Qt.RightEdge | Qt.BottomEdge; x: parent.width - 12; y: parent.height - 12; width: 12; height: 12; cursorShape: Qt.SizeFDiagCursor }
    Edge { edges: Qt.LeftEdge | Qt.BottomEdge; x: 0; y: parent.height - 12; width: 12; height: 12; cursorShape: Qt.SizeBDiagCursor }
}
