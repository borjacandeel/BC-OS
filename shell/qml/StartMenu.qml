import QtQuick
import BCShell

// Menú Inicio estilo Windows: búsqueda, apps fijadas, resultados y energía.
Rectangle {
    id: card
    signal launchPinned(string kind, string name)
    signal launchApp(string id, string name)
    signal closeRequested()
    property var results: []
    readonly property bool searching: field.text.trim().length > 0
    width: Math.min(620, UiState.sw - 24)
    height: Math.min(600, UiState.sh - UiState.taskH - 24)
    radius: 16
    color: Theme.popupFill
    border.width: 1
    border.color: Theme.hairline

    function reset() { field.text = ""; results = []; field.forceActiveFocus() }

    Rectangle {
        id: bar
        x: 24; y: 22; width: parent.width - 48; height: 44; radius: 22
        color: Qt.rgba(1, 1, 1, 0.1)
        Icon { x: 14; anchors.verticalCenter: parent.verticalCenter; name: Icons.search; size: 20; color: Theme.textSecondary }
        TextInput {
            id: field
            anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: 44; anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.white; selectionColor: Theme.accent
            font.family: Theme.fontFamily; font.pixelSize: 17
            focus: true
            onTextChanged: card.results = card.searching ? Apps.search(text) : []
            Keys.onEscapePressed: card.closeRequested()
            Keys.onReturnPressed: if (card.results.length > 0) card.launchApp(card.results[0].id, card.results[0].name)
            Text { visible: field.text.length === 0; anchors.verticalCenter: parent.verticalCenter
                   text: qsTr("Escribe aquí para buscar"); color: Theme.textSecondary; font: field.font }
        }
    }

    // Fijadas
    Column {
        visible: !card.searching
        x: 24; y: 88; width: parent.width - 48; spacing: 14
        Text { text: qsTr("Fijadas"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 15; font.weight: Font.DemiBold }
        Grid {
            columns: 4; columnSpacing: 8; rowSpacing: 8
            Repeater {
                model: UiState.pinned
                delegate: Rectangle {
                    id: pc
                    required property var modelData
                    width: (card.width - 48 - 24) / 4; height: 96; radius: 12
                    color: pma.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                    AppIcon { kind: pc.modelData.kind; size: 48; anchors.horizontalCenter: parent.horizontalCenter; y: 10 }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; y: 66; text: pc.modelData.name
                           color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13 }
                    MouseArea { id: pma; anchors.fill: parent; hoverEnabled: true; onClicked: card.launchPinned(pc.modelData.kind, pc.modelData.name) }
                }
            }
        }
    }

    // Resultados
    ListView {
        id: list
        visible: card.searching
        x: 20; y: 84; width: parent.width - 40; height: parent.height - 84 - 72
        clip: true
        model: card.results
        delegate: Rectangle {
            width: list.width; height: 48; radius: 10
            color: rma.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
            Image { visible: modelData.iconPath !== ""; x: 8; anchors.verticalCenter: parent.verticalCenter; width: 32; height: 32
                    source: modelData.iconPath !== "" ? "file://" + modelData.iconPath : ""; sourceSize: Qt.size(64, 64)
                    fillMode: Image.PreserveAspectFit; asynchronous: true }
            Rectangle { visible: modelData.iconPath === ""; x: 8; anchors.verticalCenter: parent.verticalCenter; width: 32; height: 32; radius: 8
                        color: Qt.hsla((modelData.name.charCodeAt(0) * 37 % 360) / 360, 0.45, 0.42, 1)
                        Text { anchors.centerIn: parent; text: modelData.name.charAt(0).toUpperCase(); color: Theme.white
                               font.family: Theme.fontFamily; font.pixelSize: 17; font.weight: Font.DemiBold } }
            Text { x: 54; anchors.verticalCenter: parent.verticalCenter; text: modelData.name; color: Theme.white
                   font.family: Theme.fontFamily; font.pixelSize: 15 }
            MouseArea { id: rma; anchors.fill: parent; hoverEnabled: true; onClicked: card.launchApp(modelData.id, modelData.name) }
        }
        Text { visible: card.results.length === 0; anchors.centerIn: parent; text: qsTr("No se encontró ninguna aplicación")
               color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 15 }
    }

    // Pie: usuario y energía
    Rectangle {
        anchors.bottom: parent.bottom; width: parent.width; height: 64; radius: 16
        color: Qt.rgba(1, 1, 1, 0.05)
        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.hairline }
        Rectangle { x: 24; anchors.verticalCenter: parent.verticalCenter; width: 34; height: 34; radius: 17; color: Theme.accent
                    Text { anchors.centerIn: parent; text: PamAuth.currentUser.charAt(0).toUpperCase(); color: Theme.white
                           font.family: Theme.fontFamily; font.pixelSize: 17; font.weight: Font.DemiBold } }
        Text { x: 68; anchors.verticalCenter: parent.verticalCenter; text: PamAuth.currentUser
               color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 15 }
        Row {
            anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter; spacing: 8
            Repeater {
                model: [{ i: Icons.lock, a: "lock" }, { i: Icons.reboot, a: "reboot" }, { i: Icons.shutdown, a: "poweroff" }]
                delegate: Rectangle {
                    required property var modelData
                    width: 38; height: 38; radius: 10; color: bma.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
                    Icon { anchors.centerIn: parent; name: modelData.i; size: 20 }
                    MouseArea { id: bma; anchors.fill: parent; hoverEnabled: true
                                onClicked: { UiState.closePopups(); UiState.run(modelData.a === "lock" ? "bc:lock" : "bc:power:" + modelData.a) } }
                }
            }
        }
    }
}
