import QtQuick
import BCShell

// Menú del logo BC (arriba a la izquierda): bloquear, cerrar sesión, reiniciar, apagar.
Item {
    id: root
    property bool open: false
    signal aboutRequested()
    signal settingsRequested()
    signal lockRequested()
    signal powerRequested(string action)
    anchors.fill: parent
    z: 800
    visible: card.opacity > 0

    function close() { open = false }

    MouseArea { anchors.fill: parent; enabled: root.open; onClicked: root.close() }

    Rectangle {
        id: card
        x: 12
        y: 44
        width: 270
        height: items.height + 16
        radius: 14
        color: Qt.rgba(0.08, 0.13, 0.28, 0.96)
        border.width: 1
        border.color: Theme.hairline
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.95
        transformOrigin: Item.TopLeft
        Behavior on opacity { NumberAnimation { duration: Theme.dur(140); easing.type: Theme.easing } }
        Behavior on scale { NumberAnimation { duration: Theme.dur(160); easing.type: Theme.easing } }

        Column {
            id: items
            x: 8; y: 8
            width: parent.width - 16
            spacing: 2
            Repeater {
                model: [
                    { id: "about", label: qsTr("Acerca de BC OS"), hint: "" },
                    { id: "sep" },
                    { id: "settings", label: qsTr("Configuración…"), hint: "" },
                    { id: "sep" },
                    { id: "lock", label: qsTr("Bloquear pantalla"), hint: "Ctrl+Súper+Q" },
                    { id: "logout", label: qsTr("Cerrar sesión…"), hint: "" },
                    { id: "sep" },
                    { id: "reboot", label: qsTr("Reiniciar…"), hint: "" },
                    { id: "poweroff", label: qsTr("Apagar…"), hint: "" }
                ]
                Item {
                    width: items.width
                    height: modelData.id === "sep" ? 9 : 32
                    Rectangle {
                        visible: modelData.id === "sep"
                        anchors.verticalCenter: parent.verticalCenter
                        x: 8; width: parent.width - 16; height: 1; color: Theme.hairline
                    }
                    Rectangle {
                        visible: modelData.id !== "sep"
                        anchors.fill: parent
                        radius: 8
                        color: itemArea.containsMouse ? Theme.accentSelected : "transparent"
                        Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: modelData.label || ""
                               color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 15 }
                        Text { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                               text: modelData.hint || ""; color: Qt.rgba(1, 1, 1, 0.5)
                               font.family: Theme.fontFamily; font.pixelSize: 13 }
                        MouseArea {
                            id: itemArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.close()
                                const id = modelData.id
                                if (id === "about") root.aboutRequested()
                                else if (id === "settings") root.settingsRequested()
                                else if (id === "lock") root.lockRequested()
                                else root.powerRequested(id)
                            }
                        }
                    }
                }
            }
        }
    }
}
