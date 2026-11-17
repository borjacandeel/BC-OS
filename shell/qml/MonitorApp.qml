import QtQuick
import BCShell

// Monitor de Actividad (como el de macOS): barra de herramientas unificada con pestañas CPU · Memoria · Disco · Red,
// botón de detener proceso y búsqueda; tabla de procesos reales (/proc) ordenable; panel inferior con el resumen y la
// gráfica de la pestaña.
AppWindow {
    id: win
    width: 900
    height: 620
    titlebarHeight: 52
    title: Theme.gg ? qsTr("Monitor de Actividad") : qsTr("Monitor del sistema")
    property string tab: "cpu"
    property int selPid: -1
    Component.onCompleted: { Monitor.active = Qt.binding(() => win.visible); Processes.active = Qt.binding(() => win.visible) }
    Component.onDestruction: { Monitor.active = false; Processes.active = false }

    function dur(s) {
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60)
        return (d > 0 ? d + " d " : "") + h + " h " + m + " min"
    }
    readonly property var columns: ({
        cpu: [ { t: qsTr("Nombre del proceso"), k: "name", w: 0.40 }, { t: qsTr("% CPU"), k: "cpu", w: 0.12 }, { t: qsTr("Tiempo de CPU"), k: "cpuTime", w: 0.16 },
               { t: qsTr("Hilos"), k: "threads", w: 0.10 }, { t: "PID", k: "pid", w: 0.10 }, { t: qsTr("Usuario"), k: "user", w: 0.12 } ],
        mem: [ { t: qsTr("Nombre del proceso"), k: "name", w: 0.46 }, { t: qsTr("Memoria"), k: "mem", w: 0.18 }, { t: qsTr("Hilos"), k: "threads", w: 0.12 },
               { t: "PID", k: "pid", w: 0.12 }, { t: qsTr("Usuario"), k: "user", w: 0.12 } ],
        disk: [ { t: qsTr("Nombre del proceso"), k: "name", w: 0.58 }, { t: qsTr("Memoria"), k: "mem", w: 0.16 }, { t: "PID", k: "pid", w: 0.12 }, { t: qsTr("Usuario"), k: "user", w: 0.14 } ],
        net: [ { t: qsTr("Nombre del proceso"), k: "name", w: 0.58 }, { t: qsTr("% CPU"), k: "cpu", w: 0.14 }, { t: "PID", k: "pid", w: 0.14 }, { t: qsTr("Usuario"), k: "user", w: 0.14 } ]
    })
    function cell(p, k) { return k === "mem" ? p.memText : (k === "cpu" ? p.cpu.toFixed(1) : String(p[k])) }
    function sortKeyFor(k) { return k === "user" || k === "cpuTime" ? "cpu" : k }

    // ---- Barra de herramientas unificada ----------------------------------------------------
    titlebarContent: [
        Column {
            x: 92; anchors.verticalCenter: parent.verticalCenter
            Text { text: win.title; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Bold }
            Text { text: qsTr("Todos los procesos"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
        },
        Row {
            x: 250; anchors.verticalCenter: parent.verticalCenter; spacing: 8
            // Detener (Salir / Forzar salida) e información
            Rectangle {
                width: 30; height: 26; radius: 7; color: stopMa.containsMouse ? Theme.tileFill : "transparent"; opacity: win.selPid > 0 ? 1 : 0.35
                Text { anchors.centerIn: parent; text: "⊗"; color: Theme.textPrimary; font.pixelSize: 17 }
                MouseArea { id: stopMa; anchors.fill: parent; hoverEnabled: true; enabled: win.selPid > 0; onClicked: quitSheet.open = true }
            }
        },
        // Pestañas (control segmentado centrado, como en macOS)
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.horizontalCenterOffset: 60; anchors.verticalCenter: parent.verticalCenter
            width: tabs.width + 6; height: 26; radius: 7; color: Theme.tileFill
            Row {
                id: tabs; x: 3; anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: [ { k: "cpu", t: qsTr("CPU") }, { k: "mem", t: qsTr("Memoria") }, { k: "disk", t: qsTr("Disco") }, { k: "net", t: qsTr("Red") } ]
                    Rectangle {
                        required property var modelData
                        width: tl.implicitWidth + 24; height: 20; radius: 5
                        color: win.tab === modelData.k ? (Theme.dark ? Qt.rgba(1, 1, 1, 0.18) : "white") : "transparent"
                        Text { id: tl; anchors.centerIn: parent; text: modelData.t; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                        MouseArea { anchors.fill: parent; onClicked: { win.tab = modelData.k; Processes.sortKey = modelData.k === "mem" || modelData.k === "disk" ? "mem" : "cpu" } }
                    }
                }
            }
        },
        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
            width: 180; height: 26; radius: 7; color: Theme.tileFill
            Icon { x: 7; anchors.verticalCenter: parent.verticalCenter; name: Icons.search; size: 13; color: Theme.textSecondary }
            TextInput { id: q; x: 26; width: parent.width - 32; anchors.verticalCenter: parent.verticalCenter; color: Theme.textPrimary
                        font.family: Theme.fontFamily; font.pixelSize: 12; clip: true; onTextChanged: Processes.filter = text
                        Text { visible: !parent.text; text: qsTr("Buscar"); color: Theme.textSecondary; font: parent.font } }
        }
    ]

    // ---- Tabla de procesos --------------------------------------------------------------------
    Item {
        id: table
        width: parent.width; height: parent.height - bottomPanel.height
        readonly property var cols: win.columns[win.tab]
        Row {
            id: hdr; x: 10; width: parent.width - 20; height: 26
            Repeater {
                model: table.cols
                Item {
                    required property var modelData
                    width: hdr.width * modelData.w; height: 26
                    Text { anchors.verticalCenter: parent.verticalCenter; leftPadding: 8; rightPadding: 12; width: parent.width; text: modelData.t; font.family: Theme.fontFamily; font.pixelSize: 11
                           horizontalAlignment: modelData.k === "name" || modelData.k === "user" ? Text.AlignLeft : Text.AlignRight
                           font.weight: Processes.sortKey === win.sortKeyFor(modelData.k) ? Font.Bold : Font.DemiBold; color: Theme.textSecondary }
                    Text { visible: Processes.sortKey === win.sortKeyFor(modelData.k) && modelData.k !== "user" && modelData.k !== "cpuTime"; anchors.right: parent.right; anchors.rightMargin: 0
                           anchors.verticalCenter: parent.verticalCenter; text: "⌄"; color: Theme.textSecondary; font.pixelSize: 11 }
                    MouseArea { anchors.fill: parent; onClicked: Processes.sortKey = win.sortKeyFor(modelData.k) }
                }
            }
        }
        Rectangle { y: 26; width: parent.width; height: 1; color: Theme.hairline }
        ListView {
            id: list
            OverlayScroll { flick: list }
            x: 10; y: 28; width: parent.width - 20; height: parent.height - 28; clip: true
            model: Processes.list; boundsBehavior: Flickable.DragAndOvershootBounds
            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                width: list.width; height: 22; radius: 5
                color: modelData.pid === win.selPid ? Theme.accent : (index % 2 ? Theme.tileFill : "transparent")
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    Repeater {
                        model: table.cols
                        Text {
                            required property var modelData
                            width: hdr.width * modelData.w; leftPadding: 8; elide: Text.ElideRight
                            text: win.cell(row.modelData, modelData.k)
                            horizontalAlignment: modelData.k === "name" || modelData.k === "user" ? Text.AlignLeft : Text.AlignRight
                            rightPadding: 12
                            color: row.modelData.pid === win.selPid ? "white" : (modelData.k === "name" ? Theme.textPrimary : Theme.textSecondary)
                            font.family: Theme.fontFamily; font.pixelSize: 12
                        }
                    }
                }
                MouseArea { anchors.fill: parent; onClicked: win.selPid = row.modelData.pid; onDoubleClicked: { win.selPid = row.modelData.pid; quitSheet.open = true } }
            }
        }
    }

    // ---- Panel inferior (resumen de la pestaña) ------------------------------------------------
    Rectangle {
        id: bottomPanel
        anchors.bottom: parent.bottom; width: parent.width; height: 132; color: "transparent"
        // Fondo con las esquinas inferiores de la ventana (un rectángulo redondeado recortado por arriba)
        Item { anchors.fill: parent; clip: true; z: -1
            Rectangle { y: -Theme.radiusWindow; width: parent.width; height: parent.height + Theme.radiusWindow; radius: Theme.radiusWindow
                        color: Theme.gg ? Theme.sidebarBg : Theme.tileFill } }
        Rectangle { width: parent.width; height: 1; color: Theme.hairline }
        component Stat: Row {
            property string k
            property string v
            property color c: Theme.textPrimary
            spacing: 8
            Text { width: 150; text: parent.k; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12; horizontalAlignment: Text.AlignRight }
            Text { text: parent.v; color: parent.c; font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: Font.DemiBold }
        }
        Column {
            x: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 6
            visible: win.tab === "cpu"
            Stat { k: qsTr("Sistema:"); v: Processes.systemCpu.toFixed(2) + " %"; c: "#FF453A" }
            Stat { k: qsTr("Usuario:"); v: Processes.userCpu.toFixed(2) + " %"; c: "#0A84FF" }
            Stat { k: qsTr("Inactivo:"); v: Math.max(0, 100 - Processes.userCpu - Processes.systemCpu).toFixed(2) + " %" }
        }
        Column {
            x: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 6
            visible: win.tab === "mem"
            Stat { k: qsTr("Memoria física:"); v: Monitor.formatBytes(Monitor.memTotal) }
            Stat { k: qsTr("Memoria usada:"); v: Monitor.formatBytes(Monitor.memUsed) }
            Stat { k: qsTr("Intercambio usado:"); v: Monitor.formatBytes(Monitor.swapUsed) }
        }
        Column {
            x: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 6
            visible: win.tab === "disk"
            Stat { k: qsTr("Capacidad:"); v: Monitor.formatBytes(Monitor.diskTotal) }
            Stat { k: qsTr("Usado:"); v: Monitor.formatBytes(Monitor.diskUsed) }
            Stat { k: qsTr("Disponible:"); v: Monitor.formatBytes(Monitor.diskTotal - Monitor.diskUsed) }
        }
        Column {
            x: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 6
            visible: win.tab === "net"
            Stat { k: qsTr("Datos recibidos/s:"); v: Monitor.formatBytes(Monitor.netDown); c: "#0A84FF" }
            Stat { k: qsTr("Datos enviados/s:"); v: Monitor.formatBytes(Monitor.netUp); c: "#FF453A" }
            Stat { k: qsTr("Activo desde hace:"); v: win.dur(Monitor.uptime) }
        }
        // Gráfica (carga de CPU / presión de memoria) en el centro, como en macOS
        Column {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.verticalCenter: parent.verticalCenter; spacing: 4
            Text { anchors.horizontalCenter: parent.horizontalCenter; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11
                   text: win.tab === "mem" ? qsTr("PRESIÓN DE MEMORIA") : (win.tab === "net" ? qsTr("RED") : (win.tab === "disk" ? qsTr("OCUPACIÓN") : qsTr("CARGA DE CPU"))) }
            Rectangle {
                width: 220; height: 76; radius: 4; color: Theme.dark ? "#141416" : "#FFFFFF"; border.width: 1; border.color: Theme.hairline; clip: true
                Row {
                    visible: win.tab === "cpu" || win.tab === "net"
                    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 2; height: parent.height - 4; spacing: 1
                    Repeater {
                        model: Monitor.cpuHistory
                        Rectangle { required property real modelData; width: (parent.width - 39) / 40; height: Math.max(1, parent.height * modelData / 100)
                                    anchors.bottom: parent.bottom; color: "#30D158" }
                    }
                }
                Rectangle {
                    visible: win.tab === "mem" || win.tab === "disk"
                    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 2
                    readonly property real f: win.tab === "mem" ? (Monitor.memTotal > 0 ? Monitor.memUsed / Monitor.memTotal : 0) : (Monitor.diskTotal > 0 ? Monitor.diskUsed / Monitor.diskTotal : 0)
                    height: (parent.height - 4) * f
                    color: f > 0.85 ? "#FF453A" : (f > 0.65 ? "#FFD60A" : "#30D158")
                }
            }
        }
        Column {
            anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter; spacing: 6
            Stat { k: qsTr("Procesos:"); v: String(Processes.list.length) }
            Stat { k: qsTr("Hilos:"); v: String(Processes.threadCount) }
            Stat { k: qsTr("Núcleos:"); v: String(Monitor.cpuCount) }
        }
    }

    // ---- Hoja «¿Seguro que quieres salir de este proceso?» ----------------------------------
    Item {
        id: quitSheet
        property bool open: false
        anchors.fill: parent; z: 60; visible: opacity > 0; opacity: open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.d(Theme.durSheet * 0.6) } }
        readonly property var proc: Processes.list.find(p => p.pid === win.selPid) || null
        Rectangle { anchors.fill: parent; anchors.topMargin: -win.titlebarHeight; radius: Theme.radiusWindow; color: Theme.scrim; opacity: 0.35 }
        MouseArea { anchors.fill: parent; onClicked: quitSheet.open = false }
        Rectangle {
            width: 420; height: 150; radius: 16; anchors.horizontalCenter: parent.horizontalCenter
            y: quitSheet.open ? 16 : -40
            Behavior on y { NumberAnimation { duration: Theme.d(Theme.durSheet); easing.type: Theme.easeEmphasized } }
            color: Theme.popupFill; border.width: 1; border.color: Theme.hairline
            MouseArea { anchors.fill: parent }
            Text { x: 20; y: 18; width: parent.width - 40; wrapMode: Text.Wrap; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Bold
                   text: qsTr("¿Seguro que quieres salir de «%1»?").arg(quitSheet.proc ? quitSheet.proc.name : "") }
            Text { x: 20; y: 46; width: parent.width - 40; wrapMode: Text.Wrap; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12
                   text: quitSheet.proc && !quitSheet.proc.mine ? qsTr("Este proceso es de otro usuario: no se puede cerrar desde aquí.") : qsTr("«Forzar salida» cierra el proceso sin guardar cambios.") }
            Row {
                anchors.right: parent.right; anchors.rightMargin: 16; anchors.bottom: parent.bottom; anchors.bottomMargin: 14; spacing: 8
                Repeater {
                    model: [ { t: qsTr("Cancelar"), a: 0 }, { t: qsTr("Forzar salida"), a: 2 }, { t: qsTr("Salir"), a: 1 } ]
                    Rectangle {
                        required property var modelData
                        width: bt.implicitWidth + 26; height: 26; radius: 7
                        color: modelData.a === 1 ? Theme.accent : Theme.tileFill
                        opacity: modelData.a > 0 && quitSheet.proc && !quitSheet.proc.mine ? 0.4 : 1
                        Text { id: bt; anchors.centerIn: parent; text: modelData.t; color: modelData.a === 1 ? "white" : Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                        MouseArea { anchors.fill: parent; onClicked: {
                            if (modelData.a > 0 && quitSheet.proc && quitSheet.proc.mine) Processes.quit(win.selPid, modelData.a === 2)
                            quitSheet.open = false; Processes.refresh() } }
                    }
                }
            }
        }
    }
}
