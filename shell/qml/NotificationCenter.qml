import QtQuick
import BCShell

// Centro de notificaciones (clic en la fecha y hora): notificaciones reales del servicio
// org.freedesktop.Notifications de BC OS agrupadas por app, y debajo el widget de calendario.
Item {
    id: nc
    readonly property real s: Theme.s
    function px(v) { return Math.round(v * s) }
    width: px(356)
    height: col.height
    property date now: new Date()
    Timer { interval: 30000; running: nc.visible; repeat: true; triggeredOnStart: true; onTriggered: nc.now = new Date() }

    function ago(iso) {
        const d = new Date(iso), m = Math.round((now - d) / 60000)
        if (m < 1) return qsTr("ahora")
        if (m < 60) return qsTr("hace %1 min").arg(m)
        const h = Math.round(m / 60)
        return h < 24 ? qsTr("hace %1 h").arg(h) : d.toLocaleDateString(Qt.locale(AppConfig.language), "d MMM")
    }

    Column {
        id: col
        width: parent.width; spacing: px(8)
        Item {
            width: parent.width; height: px(28)
            Text { x: px(6); anchors.verticalCenter: parent.verticalCenter; text: qsTr("Notificaciones"); color: Theme.barText
                   font.family: Theme.font; font.pixelSize: px(15); font.weight: Font.Bold
                   style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.25) }
            Rectangle {
                visible: Notifications.history.length > 0
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                width: clr.implicitWidth + px(18); height: px(24); radius: height / 2; color: Qt.rgba(1, 1, 1, cma.containsMouse ? 0.28 : 0.18)
                Text { id: clr; anchors.centerIn: parent; text: qsTr("Borrar todo"); color: "white"; font.family: Theme.font; font.pixelSize: px(11); font.weight: Font.DemiBold }
                MouseArea { id: cma; anchors.fill: parent; hoverEnabled: true; onClicked: Notifications.clearHistory() }
            }
        }
        Repeater {
            model: Notifications.history.slice(0, 6)
            delegate: Item {
                id: card
                required property var modelData
                required property int index
                width: col.width; height: px(70)
                Glass { anchors.fill: parent; radius: px(20); tintBoost: 0.25 }
                Rectangle { x: px(12); anchors.verticalCenter: parent.verticalCenter; width: px(34); height: width; radius: px(8); color: Theme.fill
                            Text { anchors.centerIn: parent; text: (card.modelData.app || "BC").charAt(0).toUpperCase(); color: Theme.label
                                   font.family: Theme.font; font.pixelSize: px(16); font.weight: Font.Bold } }
                Column {
                    x: px(56); anchors.verticalCenter: parent.verticalCenter; width: parent.width - px(70)
                    Item { width: parent.width; height: px(17)
                        Text { text: card.modelData.title; color: Theme.label; font.family: Theme.font; font.pixelSize: px(13); font.weight: Font.DemiBold
                               width: parent.width - px(70); elide: Text.ElideRight }
                        Text { anchors.right: parent.right; text: nc.ago(card.modelData.time); color: Theme.labelSecondary; font.family: Theme.font; font.pixelSize: px(11) } }
                    Text { text: card.modelData.body; color: Theme.label; opacity: 0.85; font.family: Theme.font; font.pixelSize: px(12)
                           width: parent.width; maximumLineCount: 2; wrapMode: Text.Wrap; elide: Text.ElideRight }
                }
                // Botón de cerrar al pasar (como en macOS, arriba a la izquierda)
                Rectangle {
                    visible: hov.containsMouse; x: -px(6); y: -px(6); width: px(20); height: width; radius: width / 2; color: Theme.windowBg
                    border.width: 1; border.color: Theme.separator
                    Text { anchors.centerIn: parent; text: "×"; color: Theme.label; font.pixelSize: px(13) }
                    MouseArea { anchors.fill: parent; onClicked: Notifications.removeAt(card.index) }
                }
                MouseArea { id: hov; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton; z: -1 }
            }
        }
        Item {
            visible: Notifications.history.length === 0
            width: parent.width; height: px(60)
            Glass { anchors.fill: parent; radius: px(20); tintBoost: 0.2 }
            Text { anchors.centerIn: parent; text: qsTr("No hay notificaciones"); color: Theme.labelSecondary; font.family: Theme.font; font.pixelSize: px(13) }
        }
        // Widget de calendario
        Item {
            id: cal
            width: parent.width; height: px(190)
            readonly property int first: (new Date(nc.now.getFullYear(), nc.now.getMonth(), 1).getDay() + 6) % 7
            readonly property int days: new Date(nc.now.getFullYear(), nc.now.getMonth() + 1, 0).getDate()
            Glass { anchors.fill: parent; radius: px(22); tintBoost: 0.2 }
            Text { x: px(16); y: px(12); text: nc.now.toLocaleDateString(Qt.locale(AppConfig.language), "MMMM").toUpperCase(); color: "#FF453A"
                   font.family: Theme.font; font.pixelSize: px(11); font.weight: Font.Bold }
            Grid {
                x: px(12); y: px(32); columns: 7
                Repeater { model: ["L", "M", "X", "J", "V", "S", "D"]
                           Text { required property string modelData; width: (cal.width - px(24)) / 7; height: px(20); horizontalAlignment: Text.AlignHCenter; text: modelData
                                  color: Theme.labelSecondary; font.family: Theme.font; font.pixelSize: px(10); font.weight: Font.DemiBold } }
                Repeater {
                    model: 42
                    Item {
                        required property int index
                        readonly property int day: index - cal.first + 1
                        width: (cal.width - px(24)) / 7; height: px(22)
                        visible: index < cal.first + cal.days
                        Rectangle { anchors.centerIn: parent; width: px(20); height: width; radius: width / 2; color: "#FF453A"; visible: parent.day === nc.now.getDate() }
                        Text { anchors.centerIn: parent; text: parent.day >= 1 ? parent.day : ""; color: Theme.label; font.family: Theme.font; font.pixelSize: px(11) }
                    }
                }
            }
        }
    }
}
