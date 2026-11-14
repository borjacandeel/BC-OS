import QtQuick
import BCShell

// BC Tienda: buscar, instalar y quitar software con pacman.
AppWindow {
    id: win
    width: 780
    height: 560
    title: qsTr("Tienda")

    property int mode: 0            // 0 buscar, 1 instaladas
    property string password: ""    // solo en memoria, mientras la ventana está abierta
    property var pending: null      // { action, name }

    function reload() {
        if (mode === 1) Store.listInstalled()
        else Store.search(field.text)
    }
    function ask(action, name) {
        pending = { action: action, name: name }
        if (Store.flathub || password !== "") run()
        else { pwDialog.open = true; pwInput.text = ""; pwInput.forceActiveFocus() }
    }
    function run() {
        const p = pending
        pending = null
        if (p.action === "install") Store.install(p.name, password)
        else if (p.action === "remove") Store.remove(p.name, password)
        else Store.updateAll(password)
    }
    Component.onCompleted: reload()
    Connections {
        target: Store
        function onFinished(ok, action) {
            if (!ok) win.password = ""
            win.reload()
            Notifications.push(qsTr("Tienda"), ok ? qsTr("Operación completada") : qsTr("La operación ha fallado"), "", "", 3500)
        }
    }

    Rectangle {
        id: bar
        x: 20; y: 16; width: parent.width - 40; height: 40; radius: 12; color: Qt.rgba(1, 1, 1, 0.1)
        Icon { x: 12; anchors.verticalCenter: parent.verticalCenter; name: Icons.search; size: 20; color: Theme.textSecondary }
        TextInput {
            id: field
            anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 42; anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.white; selectionColor: Theme.accent
            font.family: Theme.fontFamily; font.pixelSize: 16
            onAccepted: { win.mode = 0; Store.search(text) }
            Text { visible: field.text.length === 0; anchors.verticalCenter: parent.verticalCenter
                   text: qsTr("Buscar software (nombre o descripción)"); color: Theme.textSecondary; font: field.font }
        }
    }

    Row {
        visible: Store.flatpakAvailable
        anchors.right: parent.right; anchors.rightMargin: 240; y: 66; spacing: 8
        Repeater {
            model: [qsTr("Arch"), qsTr("Flathub")]
            delegate: Rectangle {
                required property var modelData
                required property int index
                width: srcT.implicitWidth + 24; height: 28; radius: 14
                color: (index === 1) === Store.flathub ? Theme.accent : Qt.rgba(1, 1, 1, 0.1)
                Text { id: srcT; anchors.centerIn: parent; text: modelData; color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 14 }
                MouseArea { anchors.fill: parent; onClicked: { Store.flathub = index === 1; win.reload() } }
            }
        }
    }

    Row {
        x: 20; y: 66; spacing: 8
        Repeater {
            model: [qsTr("Resultados"), qsTr("Instaladas")]
            Rectangle {
                width: 110; height: 30; radius: 9
                color: index === win.mode ? Theme.accent : Qt.rgba(1, 1, 1, 0.1)
                Text { anchors.centerIn: parent; text: modelData; color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 14 }
                MouseArea { anchors.fill: parent; onClicked: { win.mode = index; win.reload() } }
            }
        }
    }
    Rectangle {
        anchors.right: parent.right; anchors.rightMargin: 20; y: 66; width: 190; height: 30; radius: 9
        color: Qt.rgba(1, 1, 1, 0.1); opacity: Store.busy ? 0.5 : 1
        Text { anchors.centerIn: parent; text: qsTr("Actualizar sistema"); color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 14 }
        MouseArea { anchors.fill: parent; enabled: !Store.busy; onClicked: win.ask("update", "") }
    }

    ListView {
        id: list
        x: 12; y: 108; width: parent.width - 24; height: parent.height - 108 - (logBox.visible ? logBox.height + 20 : 14) - 44
        clip: true
        model: Store
        delegate: Rectangle {
            width: list.width; height: 62; radius: 12
            color: ma.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
            Rectangle {
                x: 10; anchors.verticalCenter: parent.verticalCenter; width: 38; height: 38; radius: 10
                color: Qt.hsla((model.name.charCodeAt(0) * 53 % 360) / 360, 0.5, 0.42, 1)
                Text { anchors.centerIn: parent; text: model.name.charAt(0).toUpperCase(); color: Theme.white
                       font.family: Theme.fontFamily; font.pixelSize: 19; font.weight: Font.DemiBold }
            }
            Text { x: 60; y: 9; text: model.name; color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 16; font.weight: Font.Medium }
            Text { x: 60 + 14 + nameW.width; y: 12; text: model.version + (model.repo !== "" ? " · " + model.repo : ""); color: Theme.textSecondary
                   font.family: Theme.fontFamily; font.pixelSize: 13 }
            Text { id: nameW; visible: false; text: model.name; font.family: Theme.fontFamily; font.pixelSize: 16; font.weight: Font.Medium }
            Text { x: 60; y: 34; width: parent.width - 60 - 130; elide: Text.ElideRight; text: model.desc; color: Theme.textSecondary
                   font.family: Theme.fontFamily; font.pixelSize: 13 }
            Rectangle {
                anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                width: 100; height: 32; radius: 16
                color: model.installed ? Qt.rgba(1, 1, 1, 0.14) : Theme.accent
                opacity: Store.busy ? 0.5 : 1
                Text { anchors.centerIn: parent; text: model.installed ? qsTr("Quitar") : qsTr("Instalar"); color: Theme.white
                       font.family: Theme.fontFamily; font.pixelSize: 14; font.weight: Font.DemiBold }
                MouseArea { anchors.fill: parent; enabled: !Store.busy; onClicked: win.ask(model.installed ? "remove" : "install", model.id) }
            }
            MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
        }
        Text {
            visible: Store.count === 0 && !Store.busy
            anchors.centerIn: parent
            text: win.mode === 0 ? (field.text === "" ? qsTr("Escribe para buscar software") : qsTr("Sin resultados")) : qsTr("No hay software instalado")
            color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 16
        }
        Text {
            visible: Store.busy && Store.count === 0
            anchors.centerIn: parent
            text: qsTr("Buscando…"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 16
        }
    }

    Rectangle {
        id: logBox
        visible: Store.log !== ""
        x: 20; width: parent.width - 40; height: 110; radius: 10
        y: parent.height - height - 14 - 30
        color: Qt.rgba(0, 0, 0, 0.35)
        clip: true
        Flickable {
            id: lf
            anchors.fill: parent; anchors.margins: 8
            contentHeight: logText.height
            clip: true
            onContentHeightChanged: contentY = Math.max(0, contentHeight - height)
            Text { id: logText; width: lf.width; text: Store.log; wrapMode: Text.WrapAnywhere; color: "#B8C4DA"
                   font.family: Theme.fontMono; font.pixelSize: 12 }
        }
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 10
        text: Store.busy ? qsTr("Trabajando…") : (Store.flathub ? qsTr("Aplicaciones de Flathub (se instalan en tu usuario)") : qsTr("Software de los repositorios de Arch Linux ARM"))
        color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12
    }

    Item {
        id: pwDialog
        property bool open: false
        anchors.fill: parent
        z: 50
        visible: opacity > 0
        opacity: open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur(140) } }
        Rectangle { anchors.fill: parent; color: Theme.scrim }
        MouseArea { anchors.fill: parent; onClicked: { pwDialog.open = false; win.pending = null } }
        Rectangle {
            width: 380; height: 170; radius: 18; anchors.centerIn: parent
            color: Qt.rgba(0.10, 0.15, 0.30, 0.98); border.width: 1; border.color: Theme.hairline
            MouseArea { anchors.fill: parent }
            Text { x: 22; y: 18; text: qsTr("Se necesita tu contraseña"); color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 17; font.weight: Font.DemiBold }
            Text { x: 22; y: 44; width: parent.width - 44; wrapMode: Text.WordWrap
                   text: qsTr("Para instalar o quitar software hace falta permiso de administrador."); color: Theme.textSecondary
                   font.family: Theme.fontFamily; font.pixelSize: 13 }
            Rectangle {
                x: 22; y: 84; width: parent.width - 44; height: 36; radius: 10; color: Qt.rgba(1, 1, 1, 0.12)
                TextInput {
                    id: pwInput
                    anchors.fill: parent; anchors.margins: 9
                    echoMode: TextInput.Password; passwordCharacter: "•"
                    color: Theme.white; selectionColor: Theme.accent
                    font.family: Theme.fontFamily; font.pixelSize: 16
                    onAccepted: { if (text !== "") { win.password = text; pwDialog.open = false; win.run() } }
                    Keys.onEscapePressed: { pwDialog.open = false; win.pending = null }
                }
            }
            Row {
                anchors.right: parent.right; anchors.rightMargin: 22; anchors.bottom: parent.bottom; anchors.bottomMargin: 14; spacing: 10
                Rectangle { width: 96; height: 32; radius: 10; color: Qt.rgba(1, 1, 1, 0.14)
                    Text { anchors.centerIn: parent; text: qsTr("Cancelar"); color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 14 }
                    MouseArea { anchors.fill: parent; onClicked: { pwDialog.open = false; win.pending = null } } }
                Rectangle { width: 96; height: 32; radius: 10; color: Theme.accent
                    Text { anchors.centerIn: parent; text: qsTr("Aceptar"); color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 14; font.weight: Font.DemiBold }
                    MouseArea { anchors.fill: parent; onClicked: pwInput.accepted() } }
            }
        }
    }
}
