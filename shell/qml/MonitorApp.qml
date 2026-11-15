import QtQuick
import BCShell

// Monitor del sistema: CPU, memoria, disco, red y procesos reales (/proc).
AppWindow {
    id: win
    width: 760
    height: 560
    title: Theme.gg ? qsTr("Monitor de Actividad") : qsTr("Monitor del sistema")
    Component.onCompleted: Monitor.active = Qt.binding(() => win.visible)
    Component.onDestruction: Monitor.active = false

    function dur(s) {
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60)
        return (d > 0 ? d + " d " : "") + h + " h " + m + " min"
    }

    component Card: Rectangle {
        property string heading
        property string value
        property string detail
        property real fraction: -1
        property color barColor: Theme.accent
        width: 165; height: 104; radius: 16
        color: Theme.tileFill
        Text { x: 14; y: 10; text: parent.heading; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 13 }
        Text { x: 14; y: 30; text: parent.value; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 24; font.weight: Font.DemiBold }
        Text { x: 14; y: 62; text: parent.detail; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
        Rectangle {
            visible: parent.fraction >= 0
            x: 14; y: 86; width: parent.width - 28; height: 5; radius: 2.5; color: Theme.tileFill
            Rectangle { width: parent.width * Math.max(0, Math.min(1, parent.parent.fraction)); height: parent.height; radius: 2.5; color: parent.parent.barColor
                        Behavior on width { NumberAnimation { duration: Theme.dur(300) } } }
        }
    }

    Row {
        x: 20; y: 18; spacing: 12
        Card { heading: qsTr("CPU"); value: Math.round(Monitor.cpu) + " %"
               detail: qsTr("%1 núcleos").arg(Monitor.cpuCount); fraction: Monitor.cpu / 100 }
        Card { heading: qsTr("Memoria"); value: Monitor.formatBytes(Monitor.memUsed)
               detail: qsTr("de %1").arg(Monitor.formatBytes(Monitor.memTotal))
               fraction: Monitor.memTotal > 0 ? Monitor.memUsed / Monitor.memTotal : 0; barColor: "#34C759" }
        Card { heading: qsTr("Disco"); value: Monitor.formatBytes(Monitor.diskUsed)
               detail: qsTr("de %1").arg(Monitor.formatBytes(Monitor.diskTotal))
               fraction: Monitor.diskTotal > 0 ? Monitor.diskUsed / Monitor.diskTotal : 0; barColor: "#FF9F0A" }
        Card { heading: qsTr("Red"); value: "↓ " + Monitor.formatBytes(Monitor.netDown) + "/s"
               detail: "↑ " + Monitor.formatBytes(Monitor.netUp) + "/s" }
    }

    Rectangle {
        x: 20; y: 134; width: parent.width - 40; height: 54; radius: 14; color: Theme.tileFill
        Row {
            anchors.fill: parent; anchors.margins: 10; spacing: 2
            Repeater {
                model: Monitor.cpuHistory
                Rectangle {
                    width: (parent.width - 39 * 2) / 40; height: Math.max(2, parent.height * modelData / 100)
                    anchors.bottom: parent.bottom; radius: 1.5; color: Theme.accent; opacity: 0.85
                }
            }
        }
    }

    Text {
        x: 22; y: 198
        text: Monitor.hostname + " · Linux " + Monitor.kernel + " · " + Monitor.cpuModel + " · " + qsTr("activo %1").arg(win.dur(Monitor.uptime))
              + " · " + qsTr("%1 procesos").arg(Monitor.processCount)
        color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12
        width: parent.width - 44; elide: Text.ElideRight
    }

    Rectangle {
        x: 20; y: 224; width: parent.width - 40; height: parent.height - 224 - 56 - 20 + 56; radius: 14; color: Theme.tileFill
        clip: true
        Row {
            x: 14; y: 8; height: 22; spacing: 0
            Text { width: 360; text: qsTr("Proceso"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
            Text { width: 90; text: "PID"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
            Text { width: 90; text: qsTr("CPU"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
            Text { width: 120; text: qsTr("Memoria"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
        }
        ListView {
            x: 0; y: 32; width: parent.width; height: parent.height - 36
            model: Monitor
            clip: true
            delegate: Item {
                width: ListView.view.width; height: 28
                Row {
                    x: 14; anchors.verticalCenter: parent.verticalCenter
                    Text { width: 360; text: model.name; elide: Text.ElideRight; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 14 }
                    Text { width: 90; text: model.pid; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 14 }
                    Text { width: 90; text: model.cpu.toFixed(1) + " %"; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 14 }
                    Text { width: 120; text: Monitor.formatBytes(model.mem); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 14 }
                }
            }
        }
    }
}
