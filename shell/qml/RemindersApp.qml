import QtQuick
import BCShell

// Recordatorios (como la app de macOS): barra lateral con listas inteligentes en mosaico (Hoy, Todos, Completados)
// y la lista «Recordatorios»; a la derecha el título grande en color, el contador y las tareas con círculo.
// Comparte los datos con el widget del escritorio (~/.local/share/bc/recordatorios.json).
AppWindow {
    id: win
    sidebarWidth: 240
    width: 860
    height: 580
    titlebarHeight: 52
    title: qsTr("Recordatorios")
    property string view: "all"      // all | done
    readonly property color blue: "#0A84FF"
    readonly property var items: Reminders.items.filter(r => view === "done" ? r.done : !r.done)

    titlebarContent: [
        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter
            width: 30; height: 26; radius: 7; color: am.containsMouse ? Theme.tileFill : "transparent"
            Text { anchors.centerIn: parent; text: "+"; color: Theme.textSecondary; font.pixelSize: 20 }
            MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; onClicked: { win.view = "all"; if (lv.footerItem) lv.footerItem.children[1].forceActiveFocus() } }
        }
    ]

    Rectangle {
        id: side
        y: -win.titlebarHeight; width: 240; height: parent.height + win.titlebarHeight
        color: Theme.gg ? "transparent" : Theme.sidebarFill
        SidebarGlass { anchors.fill: parent; active: win.active; z: -1 }
        Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.hairline }
        Grid {
            x: 12; y: win.titlebarHeight + 6; columns: 2; spacing: 8
            Repeater {
                model: [ { k: "all", t: qsTr("Todos"), c: "#3A3A3C", n: Reminders.pending, i: "view-list-symbolic" },
                         { k: "done", t: qsTr("Completados"), c: "#636366", n: Reminders.items.length - Reminders.pending, i: "object-select-symbolic" } ]
                Rectangle {
                    required property var modelData
                    width: 104; height: 64; radius: 10
                    color: win.view === modelData.k ? win.blue : (Theme.dark ? Qt.rgba(1, 1, 1, 0.08) : "white")
                    Rectangle { x: 10; y: 10; width: 26; height: 26; radius: 13; color: win.view === modelData.k ? "white" : modelData.c
                                Icon { anchors.centerIn: parent; name: modelData.i; size: 14; color: win.view === modelData.k ? win.blue : "white" } }
                    Text { anchors.right: parent.right; anchors.rightMargin: 10; y: 8; text: modelData.n; color: win.view === modelData.k ? "white" : Theme.textPrimary
                           font.family: Theme.fontFamily; font.pixelSize: 22; font.weight: Font.Bold }
                    Text { x: 10; y: 42; text: modelData.t; color: win.view === modelData.k ? "white" : Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: Font.DemiBold }
                    MouseArea { anchors.fill: parent; onClicked: win.view = modelData.k }
                }
            }
        }
        Column {
            x: 12; y: win.titlebarHeight + 86; width: parent.width - 24; spacing: 2
            Text { leftPadding: 4; bottomPadding: 4; text: qsTr("Mis listas"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold }
            Rectangle {
                width: parent.width; height: 32; radius: 7; color: win.view === "all" ? Theme.tileFill : "transparent"
                Rectangle { x: 8; anchors.verticalCenter: parent.verticalCenter; width: 22; height: 22; radius: 11; color: win.blue
                            Icon { anchors.centerIn: parent; name: "view-list-symbolic"; size: 12; color: "white" } }
                Text { x: 38; anchors.verticalCenter: parent.verticalCenter; text: qsTr("Recordatorios"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13 }
                Text { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: Reminders.pending; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                MouseArea { anchors.fill: parent; onClicked: win.view = "all" }
            }
        }
    }

    Item {
        x: side.width; width: parent.width - side.width; height: parent.height
        Text { x: 28; y: 6; text: win.view === "done" ? qsTr("Completados") : qsTr("Recordatorios"); color: win.view === "done" ? Theme.textSecondary : win.blue
               font.family: Theme.fontFamily; font.pixelSize: 26; font.weight: Font.Bold }
        Text { anchors.right: parent.right; anchors.rightMargin: 28; y: 6; text: win.items.length; color: win.view === "done" ? Theme.textSecondary : win.blue
               font.family: Theme.fontFamily; font.pixelSize: 26; font.weight: Font.Bold }
        Rectangle {
            visible: win.view === "done" && win.items.length > 0
            anchors.right: parent.right; anchors.rightMargin: 28; y: 46; width: ct.implicitWidth + 20; height: 22; radius: 6; color: Theme.tileFill
            Text { id: ct; anchors.centerIn: parent; text: qsTr("Borrar completados"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 11 }
            MouseArea { anchors.fill: parent; onClicked: Reminders.clearDone() }
        }
        ListView {
            id: lv
            x: 20; y: 78; width: parent.width - 40; height: parent.height - 78 - 10; clip: true
            model: win.items
            delegate: Item {
                required property var modelData
                width: lv.width; height: 38
                Rectangle {
                    x: 8; anchors.verticalCenter: parent.verticalCenter; width: 20; height: 20; radius: 10
                    color: modelData.done ? win.blue : "transparent"; border.width: 1.5; border.color: modelData.done ? win.blue : Theme.textSecondary
                    Rectangle { anchors.centerIn: parent; width: 10; height: 10; radius: 5; color: "white"; visible: modelData.done }
                    MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: Reminders.toggle(modelData.id) }
                }
                Text { x: 40; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 80; elide: Text.ElideRight; text: modelData.title
                       color: modelData.done ? Theme.textSecondary : Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13 }
                Text { anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: "×"; color: Theme.textSecondary; font.pixelSize: 16
                       visible: rm.containsMouse
                       MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: Reminders.remove(modelData.id) } }
                Rectangle { x: 40; anchors.bottom: parent.bottom; width: parent.width - 40; height: 1; color: Theme.hairline }
                MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton; z: -1 }
            }
            footer: Item {
                visible: win.view === "all"; width: lv.width; height: visible ? 40 : 0
                Rectangle { x: 8; anchors.verticalCenter: parent.verticalCenter; width: 20; height: 20; radius: 10; color: "transparent"; border.width: 1.5; border.color: Theme.hairline }
                TextInput {
                    id: input
                    x: 40; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 48
                    color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13
                    onAccepted: { Reminders.add(text); text = "" }
                    Text { visible: !parent.text; text: qsTr("Nuevo recordatorio"); color: Theme.textSecondary; font: parent.font }
                }
            }
            Text { visible: win.items.length === 0 && win.view === "done"; anchors.centerIn: parent; text: qsTr("Sin recordatorios completados"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 14 }
        }
    }
    Shortcut { sequence: "Ctrl+N"; onActivated: { win.view = "all"; lv.footerItem && lv.footerItem.children[1].forceActiveFocus() } }
    Connections { target: AppActions; function onActionInvoked(a) { if (a === "close") win.closeRequested() } }
}
