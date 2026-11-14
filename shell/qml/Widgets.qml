import QtQuick
import BCShell

// Widgets del escritorio: reloj, calendario y uso del equipo (solo lectura; sin teclado).
Column {
    id: w
    spacing: 14
    width: 250
    property date now: new Date()
    readonly property var loc: Qt.locale(AppConfig.language)
    Timer { interval: 1000; running: w.visible; repeat: true; triggeredOnStart: true
            onTriggered: w.now = AppConfig.fixedTime !== "" ? new Date(AppConfig.fixedTime) : new Date() }
    Binding { target: Monitor; property: "active"; value: w.visible; when: w.visible }

    component Card: Rectangle {
        radius: 20; color: Theme.widgetFill; border.width: 1; border.color: Theme.hairline
        width: parent.width
    }

    Card {
        height: 110
        Text { anchors.horizontalCenter: parent.horizontalCenter; y: 12; text: w.now.toLocaleTimeString(w.loc, "HH:mm")
               color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 52; font.weight: Font.Light }
        Text { anchors.horizontalCenter: parent.horizontalCenter; y: 74; text: w.now.toLocaleDateString(w.loc, "dddd, d 'de' MMMM")
               color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 14 }
    }

    Card {
        id: cal
        height: 190
        readonly property int first: (new Date(w.now.getFullYear(), w.now.getMonth(), 1).getDay() + 6) % 7   // lunes = 0
        readonly property int days: new Date(w.now.getFullYear(), w.now.getMonth() + 1, 0).getDate()
        Text { x: 16; y: 10; text: w.now.toLocaleDateString(w.loc, "MMMM yyyy"); color: Theme.textPrimary
               font.family: Theme.fontFamily; font.pixelSize: 14; font.weight: Font.DemiBold }
        Grid {
            x: 12; y: 36; columns: 7
            Repeater {
                model: ["L", "M", "X", "J", "V", "S", "D"]
                delegate: Text { width: 32; height: 20; horizontalAlignment: Text.AlignHCenter; text: modelData
                                 color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
            }
            Repeater {
                model: 42
                delegate: Item {
                    required property int index
                    readonly property int day: index - cal.first + 1
                    width: 32; height: 22
                    visible: day >= 1 && day <= cal.days
                    Rectangle { anchors.centerIn: parent; width: 22; height: 22; radius: 11; color: Theme.accent; visible: day === w.now.getDate() }
                    Text { anchors.centerIn: parent; text: parent.day; color: Theme.white; font.family: Theme.fontFamily; font.pixelSize: 12 }
                }
            }
        }
    }

    Card {
        height: 120
        Text { x: 16; y: 10; text: qsTr("Uso del equipo"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 14; font.weight: Font.DemiBold }
        Repeater {
            model: [{ n: qsTr("CPU"), f: Monitor.cpu / 100, c: Theme.accent },
                    { n: qsTr("Memoria"), f: Monitor.memTotal > 0 ? Monitor.memUsed / Monitor.memTotal : 0, c: "#34C759" },
                    { n: qsTr("Disco"), f: Monitor.diskTotal > 0 ? Monitor.diskUsed / Monitor.diskTotal : 0, c: "#FF9F0A" }]
            delegate: Item {
                required property var modelData
                required property int index
                x: 16; y: 36 + index * 26; width: parent.width - 32; height: 22
                Text { text: modelData.n; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { x: 70; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 70; height: 8; radius: 4; color: Qt.rgba(1, 1, 1, 0.12)
                            Rectangle { width: parent.width * Math.max(0, Math.min(1, modelData.f)); height: parent.height; radius: 4; color: modelData.c
                                        Behavior on width { NumberAnimation { duration: Theme.dur(300) } } } }
            }
        }
    }
}
