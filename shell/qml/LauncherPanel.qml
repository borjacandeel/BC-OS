import QtQuick
import BCShell

// Lanzador de aplicaciones con búsqueda (Ctrl+Espacio o el icono del Dock).
Item {
    id: root
    property bool open: false
    property int selected: 0
    property var results: []
    signal launchRequested(string id, string name)
    anchors.fill: parent
    z: 700
    visible: card.opacity > 0.01

    function show() { open = true; field.text = ""; refresh(); field.forceActiveFocus() }
    function hide() { open = false }
    function refresh() { results = Apps.search(field.text); selected = 0 }
    onOpenChanged: if (open) { field.text = ""; refresh(); field.forceActiveFocus() }
    function launchSelected() {
        if (results.length === 0) return
        const r = results[Math.min(selected, results.length - 1)]
        hide()
        launchRequested(r.id, r.name)
    }

    Rectangle { anchors.fill: parent; color: Qt.rgba(0.01, 0.04, 0.10, 0.45); opacity: card.opacity }
    MouseArea { anchors.fill: parent; enabled: root.open; onClicked: root.hide() }

    Rectangle {
        id: card
        width: Math.min(640, root.width - 40)
        height: Math.min(460, root.height - 80)
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(root.height * 0.14) + (root.open ? 0 : -18)
        radius: 22
        color: Qt.rgba(0.07, 0.11, 0.25, 0.97)
        border.width: 1
        border.color: Theme.hairline
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.97
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: Theme.dur(160); easing.type: Theme.easing } }
        Behavior on y { NumberAnimation { duration: Theme.dur(180); easing.type: Theme.easing } }
        Behavior on scale { NumberAnimation { duration: Theme.dur(180); easing.type: Theme.easing } }
        MouseArea { anchors.fill: parent }

        Rectangle {
            id: bar
            x: 18; y: 18; width: parent.width - 36; height: 46; radius: 14
            color: Qt.rgba(1, 1, 1, 0.1)
            Icon { x: 14; anchors.verticalCenter: parent.verticalCenter; name: Icons.search; size: 22; color: Theme.textSecondary }
            TextInput {
                id: field
                anchors.left: parent.left; anchors.right: parent.right
                anchors.leftMargin: 48; anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.white; selectionColor: Theme.accent
                font.family: Theme.fontFamily; font.pixelSize: 19
                focus: true
                onTextChanged: root.refresh()
                Keys.onEscapePressed: root.hide()
                Keys.onReturnPressed: root.launchSelected()
                Keys.onDownPressed: root.selected = Math.min(root.results.length - 1, root.selected + 1)
                Keys.onUpPressed: root.selected = Math.max(0, root.selected - 1)
                Text { visible: field.text.length === 0; anchors.verticalCenter: parent.verticalCenter
                       text: qsTr("Buscar aplicaciones"); color: Theme.textSecondary
                       font: field.font }
            }
        }

        ListView {
            id: list
            x: 12; y: 76; width: parent.width - 24; height: parent.height - 88
            clip: true
            model: root.results
            currentIndex: root.selected
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
            delegate: Rectangle {
                width: list.width; height: 52; radius: 12
                color: index === root.selected ? Theme.accentSelected : (ma.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent")
                Rectangle {
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
                    onEntered: root.selected = index
                    onClicked: { root.selected = index; root.launchSelected() }
                }
            }
            Text {
                visible: root.results.length === 0
                anchors.centerIn: parent
                text: qsTr("No se encontró ninguna aplicación")
                color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 16
            }
        }
    }
}
