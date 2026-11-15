import QtQuick
import QtQml.Models
import BCShell

// Semáforo (cerrar, minimizar, zoom) a la izquierda de la barra de título de TODAS las ventanas que no son de BC,
// como en macOS. Una superficie layer-shell pequeña por ventana, colocada sobre la barra de título que dibuja sway.
Instantiator {
    model: Sway.chromeWindows
    delegate: LayerWindow {
        id: chrome
        required property var modelData
        layer: "top"; edges: ["top", "left"]; absolute: true; scope: "bc-chrome"
        margins: [modelData.y + Math.max(0, Math.round((modelData.h - 26) / 2)), 0, 0, modelData.x + 8]
        width: 72; height: 26
        shown: !UiState.locked && !UiState.splashing
        Row {
            anchors.verticalCenter: parent.verticalCenter
            x: 4; spacing: 8
            opacity: modelData.focused ? 1 : 0.55
            Repeater {
                model: [{ c: Theme.close, a: 0 }, { c: Theme.minimize, a: 1 }, { c: Theme.zoom, a: 2 }]
                delegate: Rectangle {
                    required property var modelData
                    width: 13; height: 13; radius: 6.5; color: modelData.c
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -4
                        onClicked: modelData.a === 0 ? Sway.closeWindow(chrome.modelData.id)
                                 : (modelData.a === 1 ? UiState.run("bc:minimize:" + chrome.modelData.id) : Sway.toggleFullscreen(chrome.modelData.id))
                    }
                }
            }
        }
    }
}
