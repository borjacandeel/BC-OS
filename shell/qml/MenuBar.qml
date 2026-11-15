import QtQuick
import BCShell

// Barra de menús Golden Gate (captura de referencia): totalmente transparente sobre el fondo, logo BC,
// nombre de la app activa en negrita y sus menús; a la derecha iconos de estado monocromos y fecha/hora.
Item {
    id: bar
    readonly property var menus: AppMenus.menusFor(Sway.focusedAppId)
    readonly property real s: Theme.s
    property date now: new Date()
    readonly property var loc: Qt.locale(AppConfig.language)
    readonly property color ink: Theme.barText

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: bar.now = AppConfig.fixedTime !== "" ? new Date(AppConfig.fixedTime) : new Date()
    }

    // Formato de la captura: «Dom 15 nov 12:19 a.m.»
    function clockText(d) {
        const days = ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"]
        const months = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sept", "oct", "nov", "dic"]
        let h = d.getHours(); const pm = h >= 12; h = h % 12; if (h === 0) h = 12
        const m = ("0" + d.getMinutes()).slice(-2)
        if (AppConfig.language.indexOf("es") !== 0)
            return d.toLocaleDateString(loc, "ddd d MMM") + "  " + d.toLocaleTimeString(loc, "h:mm AP")
        return days[d.getDay()] + " " + d.getDate() + " " + months[d.getMonth()] + " " + h + ":" + m + (pm ? " p.m." : " a.m.")
    }

    // Elemento de la barra con resaltado al pasar / abrir (Golden Gate: cápsula redondeada suave)
    component BarItem: Item {
        id: bi
        property bool open: false
        property alias hovered: ma.containsMouse
        signal clicked(real x)
        height: bar.height
        Rectangle {
            anchors.fill: parent; anchors.topMargin: Math.round(3 * bar.s); anchors.bottomMargin: Math.round(3 * bar.s)
            radius: Theme.barHoverRadius * bar.s
            color: Qt.rgba(1, 1, 1, bi.open ? 0.22 : (ma.containsMouse ? 0.12 : 0))
            Behavior on color { ColorAnimation { duration: Theme.d(Theme.durHover) } }
        }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: bi.clicked(bi.mapToItem(bar, 0, 0).x) }
    }

    // ---- Izquierda: logo, app activa, menús --------------------------------------------------
    Row {
        id: leftRow
        x: Math.round((Theme.barLogoX - 9) * bar.s)
        height: bar.height
        BarItem {
            id: logoItem
            width: Math.round((Theme.barLogoH * 2103 / 856) * bar.s) + Math.round(18 * bar.s)
            open: UiState.menu === "system"
            onClicked: (x) => UiState.openMenu("system", x)
            Brand { anchors.centerIn: parent; logoHeight: Math.round(Theme.barLogoH * bar.s) }
        }
        BarItem {
            width: appName.implicitWidth + Math.round(Theme.barItemGap * bar.s)
            open: UiState.menu === "app"
            onClicked: (x) => UiState.openMenu("app", x)
            Text {
                id: appName; anchors.centerIn: parent
                text: AppMenus.nameFor(Sway.focusedAppId)
                color: bar.ink; font.family: Theme.font; font.pixelSize: Math.round(Theme.barTextPx * bar.s)
                font.weight: Font.Bold; font.letterSpacing: Theme.letterSpacing
            }
        }
        Repeater {
            model: bar.menus
            delegate: BarItem {
                id: mi
                required property var modelData
                required property int index
                width: t.implicitWidth + Math.round(Theme.barItemGap * bar.s)
                open: UiState.menu === "m" + mi.index
                // Al pasar con un menú abierto se cambia de menú, como en macOS
                onHoveredChanged: if (hovered && UiState.menu !== "" && UiState.menu !== "m" + mi.index) UiState.openMenu("m" + mi.index, mi.mapToItem(bar, 0, 0).x)
                onClicked: (x) => UiState.openMenu("m" + mi.index, x)
                Text {
                    id: t; anchors.centerIn: parent; text: mi.modelData.title; color: bar.ink
                    font.family: Theme.font; font.pixelSize: Math.round(Theme.barTextPx * bar.s); font.letterSpacing: Theme.letterSpacing
                }
            }
        }
    }

    // ---- Derecha: estado y reloj -------------------------------------------------------------
    Row {
        id: rightRow
        anchors.right: parent.right
        anchors.rightMargin: Math.round((Theme.barRightMargin - 8) * bar.s)
        height: bar.height
        spacing: 0
        readonly property int cell: Math.round((Theme.barIconPx + Theme.barStatusGap) * bar.s)

        // Mosaico (función propia de BC OS, integrada como un icono de estado más)
        BarItem {
            width: rightRow.cell
            open: Sway.tiling
            onClicked: Sway.toggleTiling()
            Icon { anchors.centerIn: parent; name: Sway.tiling ? "view-grid-symbolic" : "view-restore-symbolic"; size: Math.round(Theme.barIconPx * bar.s); color: bar.ink }
        }
        // Concentración (luna) — visible cuando hay un modo activo o «No molestar»
        BarItem {
            visible: SystemStatus.dnd || UiState.mode !== ""
            width: rightRow.cell
            onClicked: UiState.toggleCenter()
            Icon { anchors.centerIn: parent; name: "weather-clear-night-fill-symbolic"; size: Math.round((Theme.barIconPx - 1) * bar.s); color: bar.ink }
        }
        // Fuente de entrada: «ES» en una placa redondeada rellena
        BarItem {
            visible: Sway.layout !== ""
            width: rightRow.cell
            Rectangle {
                anchors.centerIn: parent
                width: Math.round(22 * bar.s); height: Math.round(15 * bar.s); radius: Math.round(4 * bar.s); color: bar.ink
                Text { anchors.centerIn: parent; text: Sway.layout; color: "#101018"; font.family: Theme.font
                       font.pixelSize: Math.round(9.5 * bar.s); font.weight: Font.Black }
            }
        }
        // Batería con el porcentaje DENTRO del icono (captura)
        BarItem {
            visible: SystemStatus.hasBattery
            width: Math.round(34 * bar.s) + Math.round(Theme.barStatusGap * bar.s)
            onClicked: UiState.toggleCenter()
            Item {
                anchors.centerIn: parent
                width: Math.round(29 * bar.s); height: Math.round(13 * bar.s)
                Rectangle {
                    id: shell; width: parent.width - Math.round(3 * bar.s); height: parent.height; radius: Math.round(3.5 * bar.s)
                    color: Qt.rgba(1, 1, 1, 0.35)
                    Rectangle { width: parent.width * Math.max(0.06, SystemStatus.batteryPercent / 100); height: parent.height; radius: parent.radius
                                color: SystemStatus.batteryPercent <= 10 ? "#FF453A" : bar.ink }
                    Text { anchors.centerIn: parent; text: SystemStatus.batteryCharging ? "⚡" : SystemStatus.batteryPercent
                           color: "#101018"; font.family: Theme.font; font.pixelSize: Math.round(9 * bar.s); font.weight: Font.Black }
                }
                Rectangle { anchors.left: shell.right; anchors.leftMargin: Math.round(1 * bar.s); anchors.verticalCenter: parent.verticalCenter
                            width: Math.round(2 * bar.s); height: Math.round(5 * bar.s); radius: 1; color: Qt.rgba(1, 1, 1, 0.45) }
            }
        }
        // Red
        BarItem {
            width: rightRow.cell
            onClicked: UiState.openCenterPanel("wifi")
            Icon { anchors.centerIn: parent; size: Math.round(Theme.barIconPx * bar.s); color: bar.ink
                   name: Icons.networkIcon(SystemStatus.online, SystemStatus.wired, SystemStatus.signalBars(SystemStatus.signal)) }
        }
        // Control Center
        BarItem {
            width: rightRow.cell
            open: UiState.centerOpen
            onClicked: UiState.toggleCenter()
            Icon { anchors.centerIn: parent; name: Icons.toggles; size: Math.round(Theme.barIconPx * bar.s); color: bar.ink }
        }
        Item { width: Math.round((Theme.barClockGap - Theme.barStatusGap) * bar.s); height: 1 }
        // Fecha y hora → Centro de notificaciones
        BarItem {
            width: clock.implicitWidth + Math.round(16 * bar.s)
            open: UiState.notifCenterOpen
            onClicked: UiState.toggleNotifCenter()
            Text { id: clock; anchors.centerIn: parent; text: bar.clockText(bar.now); color: bar.ink
                   font.family: Theme.font; font.pixelSize: Math.round(Theme.barTextPx * bar.s); font.letterSpacing: Theme.letterSpacing }
        }
    }
}
