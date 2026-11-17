import QtQuick
import QtQuick.Window
import BCShell

// Ventana de aplicación de BC (xdg-toplevel propio): barra de título con semáforo, arrastre y redimensionado por el compositor.
Window {
    id: win
    default property alias content: contentArea.data
    property alias titlebarContent: tbSlot.data
    property int titlebarHeight: Theme.gg ? 52 : 44
    // Ancho de la barra lateral de borde a borde: el fundido bajo la barra de herramientas empieza a su derecha
    property real sidebarWidth: 0
    // Fundido bajo la barra de herramientas (desactivar en apps con un fondo continuo, como la Calculadora)
    property bool edgeFade: true
    // Posición en pantalla (sway) para que el cristal de las barras laterales recorte el fondo correcto
    // Sombra de ventana tipo macOS dibujada por la propia app (sway por software no hace sombras; Hyprland sí)
    readonly property int sh: Theme.gg && !Quick.realBlur && win.visibility !== Window.FullScreen && win.visibility !== Window.Maximized ? 32 : 0
    readonly property real originX: Quick.windowPos.x
    readonly property real originY: Quick.windowPos.y
    Binding { target: Quick; property: "trackWindow"; value: Theme.gg && win.active }
    signal closeRequested()
    property bool canClose: true
    visible: true
    color: "transparent"
    flags: Qt.FramelessWindowHint
    minimumWidth: Math.max(480, sidebarWidth + 460) + 2 * sh
    minimumHeight: 320 + 2 * sh

    onClosing: (c) => { c.accepted = false; win.closeRequested() }
    onCloseRequested: { if (!canClose) { Sounds.play("error"); return } if (Theme.reducedMotion) Qt.quit(); else closeAnim.start() }
    ParallelAnimation {
        id: closeAnim
        NumberAnimation { target: frame; property: "scale"; to: Quick.softwareRender ? 0.96 : (Theme.gg ? 0.92 : 0.94); duration: Theme.gg ? Theme.durWindowClose : 140; easing.type: Easing.InCubic }
        NumberAnimation { target: frame; property: "opacity"; to: 0; duration: Theme.gg ? Theme.durWindowClose : 140 }
        onFinished: Qt.quit()
    }

    // Expandir / restaurar (pantalla completa o maximizar): la ventana «crece» hasta su nuevo tamaño en vez de saltar
    property int _lastVis: Window.Windowed
    onVisibilityChanged: (v) => {
        const big = v === Window.FullScreen || v === Window.Maximized, wasBig = _lastVis === Window.FullScreen || _lastVis === Window.Maximized
        if (big !== wasBig && !Theme.reducedMotion && frame.opacity > 0.5 && !closeAnim.running) expandAnim.restart()
        _lastVis = v
    }
    ParallelAnimation {
        id: expandAnim
        NumberAnimation { target: frame; property: "scale"; from: Quick.softwareRender ? 0.985 : 0.96; to: 1; duration: Theme.durFullscreen * 0.55; easing.type: Easing.OutCubic }
        NumberAnimation { target: frame; property: "opacity"; from: 0.82; to: 1; duration: Theme.durFullscreen * 0.4; easing.type: Easing.OutQuad }
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
    onActiveChanged: if (active) Quick.refreshWindowPos()
    Connections { target: win; function onActiveChanged() { if (!win.active || frame.opacity >= 0.1) return
        frame.transformOrigin = Item.Bottom
        frame.scale = 1
        frame.opacity = 1
    } }
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

    // Al arrastrar la ventana se «levanta»: sombra algo más marcada y un toque de transparencia, que vuelven con
    // suavidad al soltarla
    // Zoom (doble clic en la barra de título o botón verde): ocupa la pantalla bajo la barra de menús; otra vez, vuelve
    // al tamaño y sitio de antes. Con animación de crecer (expandAnim)
    property var zoomBack: null
    function toggleZoom() {
        const s = win.screen, bar = Math.round(30 * Math.max(0.7, Math.min(2.0, (s ? s.height : 1080) / 1080)))
        if (zoomBack) {
            const b = zoomBack; zoomBack = null
            WindowControl.setGeometry(b.x, b.y, b.w, b.h)
            if (!Theme.reducedMotion) expandAnim.restart()
        } else {
            zoomBack = { x: Quick.windowPos.x, y: Quick.windowPos.y, w: win.width, h: win.height }
            // La sombra va por fuera del marco: la ventana se coloca de modo que el marco quede justo bajo la barra
            WindowControl.setGeometry(-win.sh, bar - win.sh, (s ? s.width : 1280) + 2 * win.sh, (s ? s.height : 800) - bar + 2 * win.sh)
            if (!Theme.reducedMotion) expandAnim.restart()
        }
    }
    property bool lifting: false
    Connections { target: Quick; function onWindowPosChanged() { if (win.active && Quick.trackWindow) { win.lifting = true; liftOff.restart() } } }
    Timer { id: liftOff; interval: 220; onTriggered: win.lifting = false }
    BorderImage {
        visible: win.sh > 0
        anchors.fill: parent
        anchors.margins: win.lifting ? -4 : 0
        Behavior on anchors.margins { NumberAnimation { duration: Theme.d(180); easing.type: Easing.OutCubic } }
        source: "qrc:/BCShell/assets/window-shadow.png"
        border { left: 64; right: 64; top: 64; bottom: 64 }
        opacity: win.lifting ? 1 : (win.active ? 0.85 : 0.5)
        Behavior on opacity { NumberAnimation { duration: Theme.d(Theme.durHover) } }
    }
    Rectangle {
        id: frame
        anchors.fill: parent
        anchors.margins: win.sh
        radius: Theme.radiusWindow
        color: Theme.gg && !win.active ? Theme.windowBgInactive : Theme.windowFill
        border.width: 1
        border.color: Theme.gg ? (Theme.dark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.16)) : Theme.hairline
        Behavior on color { ColorAnimation { duration: Theme.d(Theme.durHover) } }
        clip: true
        // Por software se abre solo con fundido: escalar toda la ventana en cada fotograma cuesta mucha CPU
        scale: Quick.softwareRender ? 1 : (Theme.gg ? 0.94 : 0.97)
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
            // Golden Gate: sin línea bajo la barra de herramientas; el contenido se funde bajo ella («scroll edge effect»)
            Rectangle { visible: !Theme.gg; anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.hairline }
            MouseArea { id: tlHover; x: 0; width: 90; height: parent.height; hoverEnabled: true; acceptedButtons: Qt.NoButton; z: 2 }
            MouseArea {
                anchors.fill: parent
                onPressed: { win.startSystemMove(); Quick.followWindowMove() }
                onReleased: Quick.refreshWindowPos()
                onDoubleClicked: win.toggleZoom()
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
                            onClicked: modelData.a === 0 ? win.closeRequested() : (modelData.a === 1 ? win.minimizeAnimated() : win.toggleZoom())
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

        Rectangle {
            visible: Theme.gg && win.edgeFade
            z: 1; x: win.sidebarWidth; y: titlebar.height; width: parent.width - x; height: 14
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(frame.color.r, frame.color.g, frame.color.b, 0.85) }
                GradientStop { position: 1.0; color: Qt.rgba(frame.color.r, frame.color.g, frame.color.b, 0) }
            }
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
    // Bordes de redimensionado sobre el borde real de la ventana (con sombra propia hay 32 px transparentes alrededor):
    // franja de 12 px centrada en el borde, como en macOS, y las cuatro esquinas en diagonal
    readonly property int grip: 6
    Edge { edges: Qt.LeftEdge; x: win.sh - win.grip; y: win.sh + 14; width: 2 * win.grip; height: parent.height - 2 * win.sh - 28; cursorShape: Qt.SizeHorCursor }
    Edge { edges: Qt.RightEdge; x: parent.width - win.sh - win.grip; y: win.sh + 14; width: 2 * win.grip; height: parent.height - 2 * win.sh - 28; cursorShape: Qt.SizeHorCursor }
    Edge { edges: Qt.BottomEdge; x: win.sh + 14; y: parent.height - win.sh - win.grip; width: parent.width - 2 * win.sh - 28; height: 2 * win.grip; cursorShape: Qt.SizeVerCursor }
    Edge { edges: Qt.TopEdge; x: win.sh + 14; y: win.sh - win.grip; width: parent.width - 2 * win.sh - 28; height: win.grip + 2; cursorShape: Qt.SizeVerCursor }
    Edge { edges: Qt.RightEdge | Qt.BottomEdge; x: parent.width - win.sh - 14; y: parent.height - win.sh - 14; width: 14 + win.grip; height: 14 + win.grip; cursorShape: Qt.SizeFDiagCursor }
    Edge { edges: Qt.LeftEdge | Qt.BottomEdge; x: win.sh - win.grip; y: parent.height - win.sh - 14; width: 14 + win.grip; height: 14 + win.grip; cursorShape: Qt.SizeBDiagCursor }
    Edge { edges: Qt.LeftEdge | Qt.TopEdge; x: win.sh - win.grip; y: win.sh - win.grip; width: 14 + win.grip; height: 14 + win.grip; cursorShape: Qt.SizeFDiagCursor }
    Edge { edges: Qt.RightEdge | Qt.TopEdge; x: parent.width - win.sh - 14; y: win.sh - win.grip; width: 14 + win.grip; height: 14 + win.grip; cursorShape: Qt.SizeBDiagCursor }
}
