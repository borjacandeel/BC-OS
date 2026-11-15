import QtQuick
import QtQml.Models
import BCShell

// Semáforo (cerrar, minimizar, zoom) a la izquierda de la barra de título de TODAS las ventanas que no son de BC,
// como en macOS. Una superficie layer-shell pequeña por ventana, colocada sobre la barra de título que dibuja sway.
// Golden Gate: grises en las ventanas inactivas, símbolos (× − ⤢) al pasar por el grupo, y menú de mosaico
// en el botón verde (clic derecho o mantener pulsado).
Instantiator {
    model: Sway.chromeWindows
    delegate: LayerWindow {
        id: chrome
        required property var modelData
        readonly property bool gg: !UiState.classic
        readonly property int d: gg ? Theme.trafficSize : 13
        readonly property int gap: gg ? Theme.trafficGap : 8
        layer: "top"; edges: ["top", "left"]; absolute: true; scope: "bc-chrome"
        margins: [modelData.y + Math.max(0, Math.round((modelData.h - 26) / 2)), 0, 0, modelData.x + (gg ? Theme.trafficLeft - 4 : 8)]
        width: 3 * d + 2 * gap + 8; height: 26
        shown: !UiState.locked && !UiState.splashing && !UiState.missionOpen
        MouseArea { id: group; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
        Row {
            anchors.verticalCenter: parent.verticalCenter
            x: 4; spacing: chrome.gap
            opacity: chrome.gg || modelData.focused ? 1 : 0.55
            Repeater {
                model: [{ c: Theme.close, a: 0, g: "×" }, { c: Theme.minimize, a: 1, g: "−" }, { c: Theme.zoom, a: 2, g: "⤢" }]
                delegate: Rectangle {
                    required property var modelData
                    width: chrome.d; height: chrome.d; radius: chrome.d / 2
                    // Inactiva: gris (salvo al pasar por encima, como en macOS)
                    color: !chrome.gg || chrome.modelData.focused || group.containsMouse ? modelData.c : Theme.trafficInactive
                    border.width: chrome.gg ? 0.5 : 0; border.color: Qt.rgba(0, 0, 0, 0.18)
                    Text {
                        anchors.centerIn: parent; visible: chrome.gg && group.containsMouse
                        text: modelData.g; color: Qt.rgba(0, 0, 0, 0.55)
                        font.pixelSize: chrome.d - 2; font.weight: Font.Black
                    }
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -4
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        pressAndHoldInterval: 400
                        onClicked: (m) => {
                            if (m.button === Qt.RightButton && modelData.a === 2) { chrome.tileMenu(); return }
                            if (modelData.a === 0) Sway.closeWindow(chrome.modelData.id)
                            else if (modelData.a === 1) UiState.run("bc:minimize:" + chrome.modelData.id)
                            else Sway.toggleFullscreen(chrome.modelData.id)
                        }
                        onPressAndHold: if (modelData.a === 2) chrome.tileMenu()
                    }
                }
            }
        }
        function tileMenu() {
            Sway.focusWindow(modelData.id)
            UiState.openContextMenu([
                { label: qsTr("Pantalla completa"), cmd: "sway:fullscreen toggle" }, { sep: true },
                { label: qsTr("Mover a la mitad izquierda"), cmd: "bc:tile:left" },
                { label: qsTr("Mover a la mitad derecha"), cmd: "bc:tile:right" },
                { label: qsTr("Rellenar"), cmd: "bc:tile:fill" }, { label: qsTr("Centrar"), cmd: "bc:tile:center" }
            ], Qt.point(modelData.x + 2 * (d + gap) + 4, modelData.y + modelData.h))
        }
    }
}
