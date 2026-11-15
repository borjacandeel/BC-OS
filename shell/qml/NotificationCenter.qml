import QtQuick
import BCShell

// Centro de notificaciones (clic en la fecha y hora): notificaciones reales del servicio
// org.freedesktop.Notifications de BC OS agrupadas por app, y debajo el widget de calendario.
Item {
    id: nc
    readonly property real s: Theme.s
    function px(v) { return Math.round(v * s) }
    width: px(344)
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
        width: parent.width; spacing: px(10)
        // Notificaciones (arriba, como en macOS 27): tarjeta de vidrio de 344×72, icono de app de 32, título y texto
        Repeater {
            model: Notifications.history.slice(0, 5)
            delegate: Item {
                id: card
                required property var modelData
                required property int index
                width: col.width; height: px(72)
                Glass { anchors.fill: parent; radius: px(20); tintBoost: 0.18 }
                Item {
                    x: px(12); anchors.verticalCenter: parent.verticalCenter; width: px(32); height: width
                    readonly property string ico: Quick.iconPath(card.modelData.icon || card.modelData.app || "")
                    Image { anchors.fill: parent; visible: parent.ico !== ""; source: parent.ico !== "" ? "file://" + parent.ico : ""
                            sourceSize: Qt.size(64, 64); smooth: true; mipmap: true }
                    Rectangle { anchors.fill: parent; visible: parent.ico === ""; radius: px(8); color: Theme.accent
                                Text { anchors.centerIn: parent; text: (card.modelData.app || "BC").charAt(0).toUpperCase(); color: "white"
                                       font.family: Theme.font; font.pixelSize: px(15); font.weight: Font.Bold } }
                }
                Column {
                    x: px(56); anchors.verticalCenter: parent.verticalCenter; width: parent.width - px(68); spacing: px(1)
                    Item { width: parent.width; height: px(17)
                        Text { text: card.modelData.title; color: Theme.label; font.family: Theme.font; font.pixelSize: px(13); font.weight: Font.Bold
                               width: parent.width - px(60); elide: Text.ElideRight }
                        Text { anchors.right: parent.right; text: nc.ago(card.modelData.time); color: Theme.labelSecondary; font.family: Theme.font; font.pixelSize: px(11) } }
                    Text { text: card.modelData.body; color: Theme.label; font.family: Theme.font; font.pixelSize: px(13)
                           width: parent.width; maximumLineCount: 2; wrapMode: Text.Wrap; elide: Text.ElideRight; lineHeight: 0.95 }
                }
                Rectangle {
                    visible: hov.containsMouse; x: -px(6); y: -px(6); width: px(20); height: width; radius: width / 2; color: Theme.windowBg
                    border.width: 1; border.color: Theme.separator
                    Text { anchors.centerIn: parent; text: "×"; color: Theme.label; font.pixelSize: px(13) }
                    MouseArea { anchors.fill: parent; onClicked: Notifications.removeAt(card.index) }
                }
                MouseArea { id: hov; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton; z: -1 }
            }
        }
        // Cabecera «Centro de notificaciones» con el botón de borrar (círculo ×)
        Item {
            width: parent.width; height: px(30)
            Text { x: px(2); anchors.verticalCenter: parent.verticalCenter; text: qsTr("Centro de notificaciones"); color: Theme.barText
                   font.family: Theme.font; font.pixelSize: px(17); font.weight: Font.DemiBold
                   style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.18) }
            Rectangle {
                anchors.right: parent.right; anchors.rightMargin: px(2); anchors.verticalCenter: parent.verticalCenter
                width: px(22); height: width; radius: width / 2; color: Qt.rgba(1, 1, 1, cma.containsMouse ? 0.42 : 0.3)
                Text { anchors.centerIn: parent; text: "×"; color: "white"; font.pixelSize: px(15); font.weight: Font.Bold }
                MouseArea { id: cma; anchors.fill: parent; hoverEnabled: true
                            onClicked: Notifications.history.length > 0 ? Notifications.clearHistory() : UiState.closePopups() }
            }
        }
        // Widget de calendario (mediano 344×164)
        Item {
            id: cal
            width: parent.width; height: px(164)
            readonly property int first: (new Date(nc.now.getFullYear(), nc.now.getMonth(), 1).getDay() + 6) % 7
            readonly property int days: new Date(nc.now.getFullYear(), nc.now.getMonth() + 1, 0).getDate()
            Glass { anchors.fill: parent; radius: px(23); tintBoost: 0.18 }
            Column {
                x: px(17); y: px(14); width: px(120); spacing: px(2)
                Text { text: { const s = nc.now.toLocaleDateString(Qt.locale(AppConfig.language), "dddd"); return s.charAt(0).toUpperCase() + s.slice(1) }
                       color: "#FF3B30"; font.family: Theme.font; font.pixelSize: px(13); font.weight: Font.DemiBold }
                Text { text: nc.now.getDate(); color: Theme.label; font.family: Theme.font; font.pixelSize: px(40) }
                Text { text: qsTr("Sin eventos hoy"); color: Theme.labelSecondary; font.family: Theme.font; font.pixelSize: px(12) }
            }
            Grid {
                x: px(150); y: px(12); columns: 7
                Repeater { model: ["L", "M", "X", "J", "V", "S", "D"]
                           Text { required property string modelData; required property int index; width: px(25); height: px(18); horizontalAlignment: Text.AlignHCenter
                                  text: modelData; color: index >= 5 ? Theme.labelSecondary : Theme.label; font.family: Theme.font; font.pixelSize: px(10); font.weight: Font.DemiBold } }
                Repeater {
                    model: 42
                    Item {
                        required property int index
                        readonly property int day: index - cal.first + 1
                        width: px(25); height: px(19.5)
                        visible: index < cal.first + cal.days
                        Rectangle { anchors.centerIn: parent; width: px(18); height: width; radius: width / 2; color: "#FF3B30"; visible: parent.day === nc.now.getDate() }
                        Text { anchors.centerIn: parent; text: parent.day >= 1 ? parent.day : ""; font.family: Theme.font; font.pixelSize: px(11); font.weight: Font.DemiBold
                               color: parent.day === nc.now.getDate() ? "white" : (index % 7 >= 5 ? Theme.labelSecondary : Theme.label) }
                    }
                }
            }
        }
        // Recordatorios (mediano)
        Item {
            width: parent.width; height: px(164)
            Glass { anchors.fill: parent; radius: px(23); tintBoost: 0.18 }
            Rectangle { x: px(17); y: px(16); width: px(30); height: width; radius: width / 2; color: Theme.accent
                        Icon { anchors.centerIn: parent; name: "view-list-symbolic"; size: px(15); color: "white" } }
            Text { x: px(17); y: px(96); text: Reminders.pending; color: Theme.label; font.family: Theme.font; font.pixelSize: px(28); font.weight: Font.Bold }
            Text { x: px(17); y: px(132); text: qsTr("Recordatorios"); color: Theme.accent; font.family: Theme.font; font.pixelSize: px(14); font.weight: Font.DemiBold }
            Column {
                x: px(140); y: px(16); spacing: px(10)
                Repeater {
                    model: Reminders.items.filter(r => !r.done).slice(0, 4)
                    Row { required property var modelData; spacing: px(10)
                          Rectangle { width: px(20); height: width; radius: width / 2; color: "transparent"; border.width: 1.5; border.color: Theme.labelTertiary }
                          Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.title; color: Theme.label; font.family: Theme.font; font.pixelSize: px(13)
                                 width: px(170); elide: Text.ElideRight } }
                }
                Text { visible: Reminders.pending === 0; text: qsTr("Todo hecho"); color: Theme.labelSecondary; font.family: Theme.font; font.pixelSize: px(13) }
            }
        }
        // «Editar widgets» y cerrar
        Row {
            anchors.horizontalCenter: parent.horizontalCenter; spacing: px(8)
            Rectangle { width: ew.implicitWidth + px(20); height: px(24); radius: height / 2; color: Qt.rgba(1, 1, 1, ewm.containsMouse ? 0.42 : 0.3)
                        Text { id: ew; anchors.centerIn: parent; text: qsTr("Editar widgets"); color: "white"; font.family: Theme.font; font.pixelSize: px(12); font.weight: Font.DemiBold }
                        MouseArea { id: ewm; anchors.fill: parent; hoverEnabled: true; onClicked: { UiState.closePopups(); UiState.widgetGalleryOpen = true } } }
            Rectangle { width: px(24); height: width; radius: width / 2; color: Qt.rgba(1, 1, 1, xm.containsMouse ? 0.42 : 0.3)
                        Text { anchors.centerIn: parent; text: "×"; color: "white"; font.pixelSize: px(15); font.weight: Font.Bold }
                        MouseArea { id: xm; anchors.fill: parent; hoverEnabled: true; onClicked: UiState.closePopups() } }
        }
    }
}
