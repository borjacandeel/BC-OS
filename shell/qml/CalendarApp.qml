import QtQuick
import BCShell

// Calendario (como el de macOS): barra de herramientas con «Hoy», flechas y vista Día/Semana/Mes/Año (aquí Mes),
// rejilla del mes con el día de hoy en rojo y los eventos como píldoras de color; doble clic en un día crea un evento.
// Eventos en ~/.local/share/bc/calendario.json.
AppWindow {
    id: win
    width: 1000
    height: 680
    titlebarHeight: 52
    title: qsTr("Calendario")
    property date shown: new Date()
    property date today: new Date()
    property var events: []            // [{id, date: "yyyy-MM-dd", title, time, color}]
    property string editDate: ""
    readonly property var loc: Qt.locale(AppConfig.language)
    readonly property int first: (new Date(shown.getFullYear(), shown.getMonth(), 1).getDay() + 6) % 7
    readonly property int days: new Date(shown.getFullYear(), shown.getMonth() + 1, 0).getDate()
    readonly property var colors: ["#0A84FF", "#FF453A", "#30D158", "#FF9F0A", "#BF5AF2"]

    function key(y, m, d) { return y + "-" + ("0" + (m + 1)).slice(-2) + "-" + ("0" + d).slice(-2) }
    function load() { try { events = JSON.parse(Quick.readData("calendario") || "[]") } catch (e) { events = [] } }
    function save() { Quick.writeData("calendario", JSON.stringify(events)) }
    function add(date, title, time) {
        if (title.trim() === "") return
        const e = events.slice(); e.push({ id: Date.now(), date: date, title: title.trim(), time: time, color: colors[e.length % colors.length] })
        e.sort((a, b) => (a.date + a.time).localeCompare(b.date + b.time)); events = e; save()
    }
    function remove(id) { events = events.filter(e => e.id !== id); save() }
    function move(n) { shown = new Date(shown.getFullYear(), shown.getMonth() + n, 1) }
    Component.onCompleted: load()
    Timer { interval: 60000; running: true; repeat: true; onTriggered: win.today = new Date() }

    titlebarContent: [
        Row {
            x: 92; anchors.verticalCenter: parent.verticalCenter; spacing: 6
            Rectangle {
                width: ht.implicitWidth + 20; height: 24; radius: 6; color: Theme.tileFill
                Text { id: ht; anchors.centerIn: parent; text: qsTr("Hoy"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                MouseArea { anchors.fill: parent; onClicked: win.shown = new Date() }
            }
            Repeater {
                model: [ { t: "‹", n: -1 }, { t: "›", n: 1 } ]
                Rectangle { required property var modelData; width: 24; height: 24; radius: 6; color: am.containsMouse ? Theme.tileFill : "transparent"
                            Text { anchors.centerIn: parent; text: modelData.t; color: Theme.textPrimary; font.pixelSize: 18 }
                            MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; onClicked: win.move(modelData.n) } }
            }
        },
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.verticalCenter: parent.verticalCenter
            width: seg.width + 6; height: 26; radius: 7; color: Theme.tileFill
            Row {
                id: seg; x: 3; anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: [qsTr("Día"), qsTr("Semana"), qsTr("Mes"), qsTr("Año")]
                    Rectangle { required property string modelData; required property int index
                                width: st.implicitWidth + 24; height: 20; radius: 5; color: index === 2 ? (Theme.dark ? Qt.rgba(1, 1, 1, 0.18) : "white") : "transparent"
                                opacity: index === 2 ? 1 : 0.5
                                Text { id: st; anchors.centerIn: parent; text: modelData; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12 } }
                }
            }
        }
    ]

    // Cabecera del mes
    Text {
        x: 24; y: 10
        text: { const s = win.shown.toLocaleDateString(win.loc, "MMMM"); return "<b>" + s.charAt(0).toUpperCase() + s.slice(1) + "</b> " + win.shown.getFullYear() }
        textFormat: Text.StyledText; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 26
    }
    Row {
        id: dows; x: 0; y: 56; width: parent.width
        Repeater {
            model: [qsTr("lun"), qsTr("mar"), qsTr("mié"), qsTr("jue"), qsTr("vie"), qsTr("sáb"), qsTr("dom")]
            Text { required property string modelData; width: dows.width / 7; horizontalAlignment: Text.AlignRight; rightPadding: 10
                   text: modelData; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
        }
    }
    Grid {
        id: grid
        y: 78; width: parent.width; height: parent.height - 78; columns: 7
        Repeater {
            model: 42
            Rectangle {
                id: cell
                required property int index
                readonly property date d: new Date(win.shown.getFullYear(), win.shown.getMonth(), index - win.first + 1)
                readonly property bool inMonth: d.getMonth() === win.shown.getMonth()
                readonly property bool isToday: d.toDateString() === win.today.toDateString()
                readonly property string k: win.key(d.getFullYear(), d.getMonth(), d.getDate())
                width: grid.width / 7; height: grid.height / 6
                color: (index % 7) >= 5 ? (Theme.dark ? Qt.rgba(1, 1, 1, 0.025) : Qt.rgba(0, 0, 0, 0.02)) : "transparent"
                Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.hairline }
                Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.hairline }
                Rectangle {
                    anchors.right: parent.right; anchors.rightMargin: 6; y: 5; width: Math.max(22, dn.implicitWidth + 10); height: 22; radius: 11
                    color: cell.isToday ? "#FF453A" : "transparent"
                    Text { id: dn; anchors.centerIn: parent; text: cell.d.getDate() === 1 ? cell.d.toLocaleDateString(win.loc, "d MMM") : cell.d.getDate()
                           color: cell.isToday ? "white" : (cell.inMonth ? Theme.textPrimary : Theme.textSecondary); opacity: cell.inMonth ? 1 : 0.5
                           font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: cell.isToday ? Font.Bold : Font.Normal }
                }
                Column {
                    x: 4; y: 30; width: parent.width - 8; spacing: 2
                    Repeater {
                        model: win.events.filter(e => e.date === cell.k).slice(0, 3)
                        Rectangle {
                            required property var modelData
                            width: parent.width; height: 18; radius: 4; color: Qt.rgba(Qt.color(modelData.color).r, Qt.color(modelData.color).g, Qt.color(modelData.color).b, 0.25)
                            Rectangle { width: 3; height: parent.height; radius: 1.5; color: modelData.color }
                            Text { x: 7; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 10; elide: Text.ElideRight
                                   text: (modelData.time ? modelData.time + "  " : "") + modelData.title; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                            MouseArea { anchors.fill: parent; acceptedButtons: Qt.RightButton; onClicked: win.remove(modelData.id) }
                        }
                    }
                }
                MouseArea { anchors.fill: parent; z: -1; onDoubleClicked: { win.editDate = cell.k; titleIn.text = ""; timeIn.text = ""; sheet.open = true; titleIn.forceActiveFocus() } }
            }
        }
    }

    // Hoja de evento nuevo
    Item {
        id: sheet
        property bool open: false
        anchors.fill: parent; z: 60; visible: opacity > 0; opacity: open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.d(Theme.durSheet * 0.6) } }
        Rectangle { anchors.fill: parent; color: Theme.scrim; opacity: 0.35 }
        MouseArea { anchors.fill: parent; onClicked: sheet.open = false }
        Rectangle {
            width: 360; height: 170; radius: 16; anchors.horizontalCenter: parent.horizontalCenter
            y: sheet.open ? 16 : -40
            Behavior on y { NumberAnimation { duration: Theme.d(Theme.durSheet); easing.type: Theme.easeEmphasized } }
            color: Theme.popupFill; border.width: 1; border.color: Theme.hairline
            MouseArea { anchors.fill: parent }
            Text { x: 18; y: 14; text: qsTr("Evento nuevo · %1").arg(win.editDate); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Bold }
            Rectangle { x: 18; y: 44; width: parent.width - 36; height: 30; radius: 7; color: Theme.tileFill
                        TextInput { id: titleIn; anchors.fill: parent; anchors.leftMargin: 10; verticalAlignment: TextInput.AlignVCenter; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13
                                    onAccepted: done.clicked()
                                    Text { visible: !parent.text; anchors.verticalCenter: parent.verticalCenter; text: qsTr("Título"); color: Theme.textSecondary; font: parent.font } } }
            Rectangle { x: 18; y: 82; width: 110; height: 30; radius: 7; color: Theme.tileFill
                        TextInput { id: timeIn; anchors.fill: parent; anchors.leftMargin: 10; verticalAlignment: TextInput.AlignVCenter; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13
                                    inputMask: "99:99;_"; onAccepted: done.clicked()
                                    Text { visible: parent.text === ":"; anchors.verticalCenter: parent.verticalCenter; text: qsTr("Hora (opcional)"); color: Theme.textSecondary; font: parent.font } } }
            Row {
                anchors.right: parent.right; anchors.rightMargin: 18; anchors.bottom: parent.bottom; anchors.bottomMargin: 14; spacing: 8
                Rectangle { width: 86; height: 26; radius: 7; color: Theme.tileFill
                    Text { anchors.centerIn: parent; text: qsTr("Cancelar"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                    MouseArea { anchors.fill: parent; onClicked: sheet.open = false } }
                Rectangle { id: done; signal clicked(); width: 86; height: 26; radius: 7; color: Theme.accent
                    onClicked: { const t = timeIn.text.replace(/_/g, ""); win.add(win.editDate, titleIn.text, t.length === 5 ? t : ""); sheet.open = false }
                    Text { anchors.centerIn: parent; text: qsTr("Añadir"); color: "white"; font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: Font.DemiBold }
                    MouseArea { anchors.fill: parent; onClicked: done.clicked() } }
            }
        }
    }
    Item { focus: true; Keys.onLeftPressed: win.move(-1); Keys.onRightPressed: win.move(1) }
    Connections { target: AppActions; function onActionInvoked(a) { if (a === "close") win.closeRequested() } }
}
