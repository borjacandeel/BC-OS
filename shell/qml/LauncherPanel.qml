import QtQuick
import BCShell

// Lanzador de aplicaciones con búsqueda (Ctrl+Espacio o el icono del Dock).
Rectangle {
    id: card
    property int selected: 0
    property var results: []
    signal launchRequested(string id, string name)
    signal closeRequested()
    width: Math.min(640, UiState.sw - 40)
    height: Math.min(460, UiState.sh - 80)
    radius: 22
    color: Theme.popupFill
    border.width: 1
    border.color: Theme.hairline

    function reset() { field.text = ""; refresh(); field.forceActiveFocus() }
    function refresh() { results = Apps.search(field.text); selected = 0 }
    function launchSelected() {
        if (results.length === 0) return
        const r = results[Math.min(selected, results.length - 1)]
        launchRequested(r.id, r.name)
    }

        Rectangle {
            id: bar
            x: 18; y: 18; width: parent.width - 36; height: 46; radius: 14
            color: Qt.rgba(1, 1, 1, 0.1)
            Icon { x: 14; anchors.verticalCenter: parent.verticalCenter; name: Icons.search; size: 22; color: Theme.textSecondary }
            TextInput {
                cursorDelegate: TextCursor {}
                id: field
                anchors.left: parent.left; anchors.right: parent.right
                anchors.leftMargin: 48; anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.white; selectionColor: Theme.textSelection
                font.family: Theme.fontFamily; font.pixelSize: 19
                focus: true
                onTextChanged: card.refresh()
                Keys.onEscapePressed: card.closeRequested()
                Keys.onReturnPressed: card.launchSelected()
                Keys.onDownPressed: card.selected = Math.min(card.results.length - 1, card.selected + 1)
                Keys.onUpPressed: card.selected = Math.max(0, card.selected - 1)
                Text { visible: field.text.length === 0; anchors.verticalCenter: parent.verticalCenter
                       text: qsTr("Buscar aplicaciones"); color: Theme.textSecondary
                       font: field.font }
            }
        }

        ListView {
            id: list
            x: 12; y: 76; width: parent.width - 24; height: parent.height - 88
            clip: true
            model: card.results
            currentIndex: card.selected
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
            delegate: Rectangle {
                width: list.width; height: 52; radius: 12
                color: index === card.selected ? Theme.accentSelected : (ma.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent")
                Image {
                    visible: modelData.iconPath !== ""
                    x: 10; anchors.verticalCenter: parent.verticalCenter; width: 34; height: 34
                    source: modelData.iconPath !== "" ? "file://" + modelData.iconPath : ""
                    sourceSize: Qt.size(68, 68); fillMode: Image.PreserveAspectFit; asynchronous: true
                }
                Rectangle {
                    visible: modelData.iconPath === ""
                    x: 10; anchors.verticalCenter: parent.verticalCenter; width: 34; height: 34; radius: 9
                    color: Qt.hsla((modelData.name.charCodeAt(0) * 37 % 360) / 360, 0.45, 0.42, 1)
                    Text { anchors.centerIn: parent; text: modelData.name.charAt(0).toUpperCase(); color: Theme.white
                           font.family: Theme.fontFamily; font.pixelSize: 18; font.weight: Font.DemiBold }
                }
                Text { x: 58; y: modelData.comment !== "" ? 8 : 16; text: modelData.name; color: Theme.white
                       font.family: Theme.fontFamily; font.pixelSize: 16; font.weight: Font.Medium }
                Text { x: 58; y: 29; visible: modelData.comment !== ""; width: parent.width - 70; elide: Text.ElideRight
                       text: modelData.comment; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 13 }
                MouseArea {
                    id: ma; anchors.fill: parent; hoverEnabled: true
                    onEntered: card.selected = index
                    onClicked: { card.selected = index; card.launchSelected() }
                }
            }
            Text {
                visible: card.results.length === 0
                anchors.centerIn: parent
                text: qsTr("No se encontró ninguna aplicación")
                color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 16
            }
        }
}
