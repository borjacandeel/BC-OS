import QtQuick
import QtQuick.Window
import BCShell

// Ventana de aplicación de BC (xdg-toplevel propio): barra de título con semáforo, arrastre y redimensionado por el compositor.
Window {
    id: win
    default property alias content: contentArea.data
    property alias titlebarContent: tbSlot.data
    property int titlebarHeight: 44
    signal closeRequested()
    visible: true
    color: "transparent"
    flags: Qt.FramelessWindowHint
    minimumWidth: 480
    minimumHeight: 320

    onClosing: (c) => { c.accepted = false; win.closeRequested() }
    onCloseRequested: Qt.quit()

    Connections {
        target: AppActions
        function onActionInvoked(a) {
            if (a === "close") win.closeRequested()
            else if (a === "fullscreen") WindowControl.toggleFullscreen()
            else if (a === "minimize") WindowControl.minimize()
        }
    }
    Shortcut { sequence: "Ctrl+W"; onActivated: win.closeRequested() }

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: Theme.radiusWindow
        color: Qt.rgba(0.06, 0.10, 0.23, 0.98)
        border.width: 1
        border.color: Theme.hairline
        clip: true
        scale: 0.97
        opacity: 0
        transformOrigin: Item.Center
        Component.onCompleted: { scale = 1; opacity = 1 }
        Behavior on scale { NumberAnimation { duration: Theme.dur(220); easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Theme.dur(180); easing.type: Theme.easing } }

        Rectangle {
            id: titlebar
            width: parent.width
            height: win.titlebarHeight
            color: Qt.rgba(1, 1, 1, 0.04)
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.hairline }
            MouseArea {
                anchors.fill: parent
                onPressed: win.startSystemMove()
                onDoubleClicked: WindowControl.toggleFullscreen()
            }
            Row {
                x: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 9
                Repeater {
                    model: [{ c: Theme.close, a: 0 }, { c: Theme.minimize, a: 1 }, { c: Theme.zoom, a: 2 }]
                    Rectangle {
                        width: 14; height: 14; radius: 7; color: modelData.c
                        MouseArea {
                            anchors.fill: parent; anchors.margins: -3
                            onClicked: modelData.a === 0 ? win.closeRequested() : (modelData.a === 1 ? WindowControl.minimize() : WindowControl.toggleFullscreen())
                        }
                    }
                }
            }
            Text {
                visible: tbSlot.children.length === 0
                anchors.centerIn: parent
                text: win.title
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 15
                font.weight: Font.DemiBold
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
