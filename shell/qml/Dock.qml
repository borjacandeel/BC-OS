import QtQuick
import BCShell

// BC Dock: flotante, con magnificación animada por proximidad del puntero.
Item {
    id: dock
    width: 124 + (apps.length - 1) * 98
    height: 103

    property real hoverX: -1000
    readonly property real magnification: Theme.reducedMotion ? 0.0 : 0.5
    readonly property var apps: [
        { kind: "lanzador", name: qsTr("Lanzador") },
        { kind: "archivos", name: qsTr("Archivos") },
        { kind: "ajustes", name: qsTr("Configuración") },
        { kind: "monitor", name: qsTr("Monitor") },
        { kind: "terminal", name: qsTr("Terminal") },
        { kind: "tienda", name: qsTr("Tienda") },
        { kind: "navegador", name: qsTr("Navegador") },
        { kind: "musica", name: qsTr("Música") },
        { kind: "papelera", name: qsTr("Papelera") }
    ]
    property var running: []
    signal launched(string kind, string name)

    Rectangle {
        anchors.fill: parent
        radius: 30
        color: Theme.panelFillSoft
        border.width: 1
        border.color: Theme.hairline
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.10) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.02) }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.topMargin: -60
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onPositionChanged: (m) => dock.hoverX = m.x
        onExited: dock.hoverX = -1000
    }

    Repeater {
        model: dock.apps
        delegate: Item {
            id: cell
            required property var modelData
            required property int index
            readonly property real centerX: 27 + 35 + index * 98
            readonly property real dist: Math.abs(dock.hoverX - centerX)
            readonly property real prox: dock.hoverX < 0 ? 0 : Math.max(0, 1 - dist / 140)
            property real factor: 1 + dock.magnification * prox * prox
            Behavior on factor { NumberAnimation { duration: Theme.dur(110); easing.type: Theme.easing } }

            property real jump: 0
            SequentialAnimation { id: bounce
                NumberAnimation { target: cell; property: "jump"; to: 24; duration: 150; easing.type: Easing.OutQuad }
                NumberAnimation { target: cell; property: "jump"; to: 0; duration: 420; easing.type: Easing.OutBounce } }
            x: centerX - 35
            y: 15
            width: 70
            height: 70

            AppIcon {
                kind: cell.modelData.kind
                size: 70
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: cell.jump
                transformOrigin: Item.Bottom
                scale: cell.factor
                z: cell.factor
            }
            Rectangle {
                visible: dock.running.indexOf(cell.modelData.kind) >= 0
                width: 6; height: 6; radius: 3
                color: Theme.white
                opacity: 0.9
                x: 32
                y: 77
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { if (!Theme.reducedMotion && dock.running.indexOf(cell.modelData.kind) < 0 && cell.modelData.kind !== "lanzador") bounce.restart(); dock.launched(cell.modelData.kind, cell.modelData.name) }
            }
            Accessible.name: cell.modelData.name
            Accessible.role: Accessible.Button
        }
    }
}
