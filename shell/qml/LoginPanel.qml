import QtQuick
import BCShell

// Avatar, nombre y campo de contraseña estilo macOS. Compartido por el login y el bloqueo.
Item {
    id: root
    property string userName
    property string displayName
    property bool busy: false
    property string message: ""
    property string placeholder: qsTr("Introduce la contraseña")
    signal submitted(string password)
    width: 320
    height: avatar.height + 18 + nameText.height + 18 + field.height + 36 + hint.height

    function focusField() { pw.forceActiveFocus() }
    function fail(text) {
        message = text
        pw.text = ""
        busy = false
        shake.restart()
        pw.forceActiveFocus()
    }
    function clear() { pw.text = ""; message = "" }

    Column {
        id: col
        width: parent.width
        spacing: Theme.gg ? 10 : 18
        property real shiftX: 0
        transform: Translate { x: col.shiftX }

        Rectangle {
            id: avatar
            width: Theme.gg ? 84 : 108; height: width; radius: width / 2
            anchors.horizontalCenter: parent.horizontalCenter
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#6E86B8" }
                GradientStop { position: 1.0; color: "#2C3E66" }
            }
            border.width: Theme.gg ? 3 : 2
            border.color: Qt.rgba(1, 1, 1, Theme.gg ? 0.28 : 0.35)
            Text {
                anchors.centerIn: parent
                text: root.displayName.length > 0 ? root.displayName.charAt(0).toUpperCase() : "?"
                color: Theme.white
                font.family: Theme.fontFamily
                font.pixelSize: Theme.gg ? 36 : 46
                font.weight: Font.DemiBold
            }
        }

        Text {
            id: nameText
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.displayName
            color: Theme.white
            font.family: Theme.fontFamily
            font.pixelSize: Theme.gg ? 15 : 22
            font.weight: Font.DemiBold
        }

        Rectangle {
            id: field
            width: Theme.gg ? 240 : 280; height: Theme.gg ? 36 : 42; radius: height / 2
            anchors.horizontalCenter: parent.horizontalCenter
            color: Qt.rgba(1, 1, 1, pw.activeFocus ? 0.20 : 0.14)
            border.width: 1
            border.color: root.message !== "" ? "#FF6B63" : (pw.activeFocus ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(1, 1, 1, 0.2))
            Behavior on color { ColorAnimation { duration: Theme.dur(160) } }

            TextInput {
                id: pw
                anchors.left: parent.left
                anchors.right: go.left
                anchors.leftMargin: 18
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                echoMode: TextInput.Password
                passwordCharacter: "•"
                color: Theme.white
                selectionColor: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.gg ? 14 : 17
                clip: true
                enabled: !root.busy
                focus: true
                onTextChanged: if (text.length > 0) root.message = ""
                onAccepted: if (text.length > 0) { root.busy = true; root.submitted(text) }
                Text {
                    visible: pw.text.length === 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.placeholder
                    color: Qt.rgba(1, 1, 1, 0.55)
                    font: pw.font
                }
            }

            Rectangle {
                id: go
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: 30; height: 30; radius: 15
                color: pw.text.length > 0 ? Qt.rgba(1, 1, 1, 0.9) : Qt.rgba(1, 1, 1, 0.18)
                Behavior on color { ColorAnimation { duration: Theme.dur(140) } }
                Icon {
                    id: goIcon
                    anchors.centerIn: parent
                    name: root.busy ? Icons.refresh : Icons.next
                    size: 18
                    color: pw.text.length > 0 ? Theme.midnight : Qt.rgba(1, 1, 1, 0.7)
                    RotationAnimator on rotation {
                        running: root.busy
                        from: 0; to: 360; duration: 900; loops: Animation.Infinite
                        onRunningChanged: if (!running) goIcon.rotation = 0
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: pw.accepted()
                }
            }
        }

        Text {
            id: hint
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            height: 20
            text: root.message
            color: "#FF8D86"
            font.family: Theme.fontFamily
            font.pixelSize: 14
            opacity: root.message !== "" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(140) } }
        }
    }

    SequentialAnimation {
        id: shake
        NumberAnimation { target: col; property: "shiftX"; to: -14; duration: Theme.dur(60) }
        NumberAnimation { target: col; property: "shiftX"; to: 12; duration: Theme.dur(80) }
        NumberAnimation { target: col; property: "shiftX"; to: -8; duration: Theme.dur(80) }
        NumberAnimation { target: col; property: "shiftX"; to: 5; duration: Theme.dur(70) }
        NumberAnimation { target: col; property: "shiftX"; to: 0; duration: Theme.dur(60) }
    }
}
