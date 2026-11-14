import QtQuick
import BCShell

// Ventana de aplicación interna de BC Shell: barra de título arrastrable, semáforo y animaciones.
Rectangle {
    id: win
    property string title
    default property alias content: contentArea.data
    property bool shown: true
    property bool maximized: false
    property rect restoreRect: Qt.rect(0, 0, 0, 0)
    property rect freeArea: Qt.rect(0, 0, 1000, 700)
    property size bounds: Qt.size(1280, 800)
    signal closeRequested()
    signal activated()

    radius: Theme.radiusWindow
    color: Qt.rgba(0.06, 0.10, 0.23, 0.98)
    border.width: 1
    border.color: Theme.hairline
    clip: true
    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.92
    visible: opacity > 0.01
    transformOrigin: Item.Bottom
    Behavior on opacity { NumberAnimation { duration: Theme.dur(180); easing.type: Theme.easing } }
    Behavior on scale { NumberAnimation { duration: Theme.dur(200); easing.type: Easing.OutCubic } }
    Behavior on x { enabled: win.maximized || win.animatingMax; NumberAnimation { duration: Theme.dur(220); easing.type: Theme.easing } }
    Behavior on y { enabled: win.maximized || win.animatingMax; NumberAnimation { duration: Theme.dur(220); easing.type: Theme.easing } }
    Behavior on width { enabled: win.animatingMax; NumberAnimation { duration: Theme.dur(220); easing.type: Theme.easing } }
    Behavior on height { enabled: win.animatingMax; NumberAnimation { duration: Theme.dur(220); easing.type: Theme.easing } }
    property bool animatingMax: false

    function toggleMaximize() {
        animatingMax = true
        if (!maximized) {
            restoreRect = Qt.rect(x, y, width, height)
            x = freeArea.x; y = freeArea.y; width = freeArea.width; height = freeArea.height
            maximized = true
        } else {
            x = restoreRect.x; y = restoreRect.y; width = restoreRect.width; height = restoreRect.height
            maximized = false
        }
        maxTimer.restart()
    }
    Timer { id: maxTimer; interval: 300; onTriggered: win.animatingMax = false }

    MouseArea { anchors.fill: parent; onPressed: (m) => { win.activated(); m.accepted = false } }

    Rectangle {
        id: titlebar
        width: parent.width
        height: 44
        color: Qt.rgba(1, 1, 1, 0.04)
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.hairline }
        MouseArea {
            anchors.fill: parent
            drag.target: win.maximized ? null : win
            drag.minimumX: -win.width + 80
            drag.maximumX: win.bounds.width - 80
            drag.minimumY: 41
            drag.maximumY: win.bounds.height - 60
            onPressed: win.activated()
            onDoubleClicked: win.toggleMaximize()
        }
        Row {
            x: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 9
            Repeater {
                model: [{ c: Theme.close, a: 0 }, { c: Theme.minimize, a: 1 }, { c: Theme.zoom, a: 2 }]
                Rectangle {
                    width: 14; height: 14; radius: 7; color: modelData.c
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -3
                        onClicked: modelData.a === 0 ? win.closeRequested() : (modelData.a === 1 ? win.shown = false : win.toggleMaximize())
                    }
                }
            }
        }
        Text {
            anchors.centerIn: parent
            text: win.title
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 15
            font.weight: Font.DemiBold
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
