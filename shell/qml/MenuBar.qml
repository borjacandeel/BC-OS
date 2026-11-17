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
    // Como macOS: texto oscuro si el fondo bajo la barra es claro, blanco si es oscuro (no depende del modo claro/oscuro)
    readonly property color ink: Quick.wallpaperTopLight(Settings.wallpaper) ? "#1D1D1F" : Theme.barText

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
        if (Settings.clock24) return days[d.getDay()] + " " + d.getDate() + " " + months[d.getMonth()] + " " + d.getHours() + ":" + m
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
            // Resalte con el color de la tinta: blanco sobre fondos oscuros, negro sobre fondos claros (como macOS)
            readonly property bool lightBg: bar.ink.hslLightness < 0.5
            color: lightBg ? Qt.rgba(0, 0, 0, bi.open ? 0.12 : (ma.containsMouse ? 0.07 : 0))
                           : Qt.rgba(1, 1, 1, bi.open ? 0.22 : (ma.containsMouse ? 0.12 : 0))
            Behavior on color { ColorAnimation { duration: Theme.d(Theme.durHover) } }
        }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: bi.clicked(bi.mapToItem(bar, 0, 0).x) }
    }

    // Anchura que ocuparían todos los iconos de estado (estimación fija: sin depender de su visibilidad)
    readonly property real rightFull: Math.round((Theme.barIconPx + Theme.barStatusGap) * bar.s) * 6 + clock.implicitWidth + Math.round(110 * bar.s)
    readonly property bool overflow: leftRow.x + leftRow.implicitWidth + rightFull > width
    property bool expanded: false
    onOverflowChanged: if (!overflow) expanded = false

    // ---- Izquierda: logo, app activa, menús --------------------------------------------------
    Row {
        id: leftRow
        opacity: bar.expanded ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.d(Theme.durHover * 2) } }
        x: Math.round((Theme.barLogoX - 9) * bar.s)
        height: bar.height
        BarItem {
            id: logoItem
            width: Math.round((Theme.barLogoH * 2103 / 856) * bar.s) + Math.round(18 * bar.s)
            open: UiState.menu === "system"
            onClicked: (x) => UiState.openMenu("system", x)
            Brand { anchors.centerIn: parent; logoHeight: Math.round(Theme.barLogoH * bar.s); color: bar.ink }
        }
        BarItem {
            width: appName.implicitWidth + Math.round(Theme.barItemGap * bar.s)
            open: UiState.menu === "app"
            onClicked: (x) => UiState.openMenu("app", x)
            Text {
                id: appName; anchors.centerIn: parent
                text: AppMenus.nameFor(Sway.focusedAppId)
                color: bar.ink; font.family: Theme.font; font.pixelSize: Math.round(Theme.barTextPx * bar.s)
                font.weight: Font.Bold; font.letterSpacing: 0     // captura: «Ajustes del Sistema» = 127 px
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

        // Golden Gate: si los iconos no caben (pantalla estrecha o menús largos), se ocultan los menos importantes tras
        // una flecha nativa; al pulsarla se muestran todos sobre la zona de los menús.
        BarItem {
            visible: bar.overflow
            width: rightRow.cell
            open: bar.expanded
            onClicked: bar.expanded = !bar.expanded
            Icon { anchors.centerIn: parent; name: "menubar-overflow-symbolic"; size: Math.round((Theme.barIconPx - 2) * bar.s); color: bar.ink
                   rotation: bar.expanded ? 180 : 0
                   Behavior on rotation { NumberAnimation { duration: Theme.d(Theme.durHover * 2) } } }
        }
        // Mosaico (función propia de BC OS, integrada como un icono de estado más). En Golden Gate solo se ve
        // mientras está activo, como la luna de Concentración; se activa desde el Centro de control.
        BarItem {
            visible: (!bar.overflow || bar.expanded) && (!Theme.gg || Sway.tiling)
            width: rightRow.cell
            open: Sway.tiling
            onClicked: Sway.toggleTiling()
            Icon { anchors.centerIn: parent; name: Sway.tiling ? "view-grid-symbolic" : "view-restore-symbolic"; size: Math.round(Theme.barIconPx * bar.s); color: bar.ink }
        }
        // Micrófono (naranja) o cámara (verde) en uso: punto de privacidad de macOS
        BarItem {
            visible: SystemStatus.micActive || SystemStatus.camActive
            width: Math.round(14 * bar.s)
            Rectangle { anchors.centerIn: parent; width: Math.round(7 * bar.s); height: width; radius: width / 2
                        color: SystemStatus.camActive ? "#30D158" : "#FF9F0A" }
        }
        // Concentración (luna) — visible cuando hay un modo activo o «No molestar»
        BarItem {
            visible: SystemStatus.dnd || UiState.mode !== ""
            width: rightRow.cell
            onClicked: UiState.toggleCenter()
            Icon { anchors.centerIn: parent; name: "focus-moon-fill-symbolic"; size: Math.round((Theme.barIconPx - 1) * bar.s); color: bar.ink }
        }
        // Fuente de entrada: «ES» en una placa redondeada rellena
        BarItem {
            visible: Sway.layout !== "" && (!bar.overflow || bar.expanded)
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
                    color: Qt.rgba(bar.ink.r, bar.ink.g, bar.ink.b, 0.35)
                    Rectangle { width: parent.width * Math.max(0.06, SystemStatus.batteryPercent / 100); height: parent.height; radius: parent.radius
                                color: SystemStatus.batteryPercent <= 10 ? "#FF453A" : SystemStatus.batteryCharging ? "#30D158" : bar.ink }
                    Text { anchors.centerIn: parent; text: SystemStatus.batteryCharging ? "⚡" : SystemStatus.batteryPercent
                           color: bar.ink.hslLightness > 0.5 ? "#101018" : "#ffffff"; font.family: Theme.font; font.pixelSize: Math.round(9 * bar.s); font.weight: Font.Black }
                }
                Rectangle { anchors.left: shell.right; anchors.leftMargin: Math.round(1 * bar.s); anchors.verticalCenter: parent.verticalCenter
                            width: Math.round(2 * bar.s); height: Math.round(5 * bar.s); radius: 1; color: Qt.rgba(bar.ink.r, bar.ink.g, bar.ink.b, 0.45) }
            }
        }
        // Red
        BarItem {
            width: rightRow.cell
            onClicked: UiState.openCenterPanel("wifi")
            Icon { anchors.centerIn: parent; size: Math.round(Theme.barIconPx * bar.s); color: bar.ink
                   name: Icons.networkIcon(SystemStatus.online, SystemStatus.wired, SystemStatus.signalBars(SystemStatus.signal)) }
        }
        // Spotlight (lupa), como en la barra de macOS
        BarItem {
            visible: !bar.overflow || bar.expanded
            width: rightRow.cell
            open: UiState.spotlightOpen
            onClicked: UiState.toggleSpotlight()
            Icon { anchors.centerIn: parent; name: "system-search-symbolic"; size: Math.round((Theme.barIconPx - 1) * bar.s); color: bar.ink }
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
                   font.family: Theme.font; font.pixelSize: Math.round(Theme.barTextPx * bar.s); font.letterSpacing: 0.3 }   // captura: reloj = 142 px
        }
    }
}
