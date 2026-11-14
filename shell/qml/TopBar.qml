import QtQuick
import BCShell

Rectangle {
    id: bar
    color: Theme.barFill
    readonly property var menus: AppMenus.menusFor(Sway.focusedAppId)

    property date now: new Date()
    readonly property var loc: Qt.locale(AppConfig.language)

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: bar.now = AppConfig.fixedTime !== "" ? new Date(AppConfig.fixedTime) : new Date()
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.hairline
    }

    Row {
        id: leftRow
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0
        Item {
            id: logoBtn
            width: brandLogo.implicitWidth + 24
            height: bar.height
            Rectangle { anchors.fill: parent; anchors.margins: 4; radius: 7; color: UiState.menu === "system" ? Qt.rgba(1, 1, 1, 0.18) : (logoMa.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent") }
            Brand { id: brandLogo; logoHeight: 15; anchors.centerIn: parent }
            MouseArea { id: logoMa; anchors.fill: parent; hoverEnabled: true
                        onClicked: UiState.openMenu("system", leftRow.x + logoBtn.x) }
        }
        // Semáforo de la ventana enfocada cuando no es de BC (las apps de BC lo llevan en su propia barra de título)
        Row {
            visible: Sway.focusedId >= 0 && Sway.focusedAppId.indexOf("bc-") !== 0 && Sway.focusedAppId !== ""
            anchors.verticalCenter: parent.verticalCenter
            leftPadding: 4; rightPadding: 6; spacing: 8
            Repeater {
                model: [{ c: Theme.close, a: 0 }, { c: Theme.minimize, a: 1 }, { c: Theme.zoom, a: 2 }]
                delegate: Rectangle {
                    required property var modelData
                    width: 13; height: 13; radius: 6.5; color: modelData.c
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea { anchors.fill: parent; anchors.margins: -3
                                onClicked: modelData.a === 0 ? Sway.closeWindow(Sway.focusedId)
                                         : (modelData.a === 1 ? Sway.minimizeWindow(Sway.focusedId) : Sway.toggleFullscreen(Sway.focusedId)) }
                }
            }
        }
        Item {
            width: appName.implicitWidth + 24
            height: bar.height
            Text { id: appName; anchors.centerIn: parent; text: AppMenus.nameFor(Sway.focusedAppId)
                   color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 15; font.weight: Font.DemiBold }
        }
        Repeater {
            model: bar.menus
            delegate: Item {
                id: mi
                required property var modelData
                required property int index
                width: t.implicitWidth + 22
                height: bar.height
                Rectangle { anchors.fill: parent; anchors.margins: 4; radius: 7
                            color: UiState.menu === "m" + mi.index ? Qt.rgba(1, 1, 1, 0.18) : (ma.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent") }
                Text { id: t; anchors.centerIn: parent; text: mi.modelData.title; color: Theme.textPrimary
                       font.family: Theme.fontFamily; font.pixelSize: 15 }
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true
                            onClicked: UiState.openMenu("m" + mi.index, leftRow.x + mi.x) }
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 18
        Rectangle {
            width: 32; height: 28; radius: 8
            anchors.verticalCenter: parent.verticalCenter
            color: tileArea.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : (Sway.tiling ? Qt.rgba(0.18, 0.48, 0.96, 0.55) : Qt.rgba(1, 1, 1, 0.12))
            Icon { anchors.centerIn: parent; name: Sway.tiling ? "view-grid-symbolic" : "window-restore-symbolic"; size: 18 }
            MouseArea { id: tileArea; anchors.fill: parent; hoverEnabled: true; onClicked: Sway.toggleTiling() }
        }
        Icon { name: Icons.networkIcon(SystemStatus.online, SystemStatus.wired, SystemStatus.signalBars(SystemStatus.signal))
               size: 22; anchors.verticalCenter: parent.verticalCenter }
        Icon { name: Icons.volumeIcon(SystemStatus.volume, SystemStatus.muted); size: 22
               visible: SystemStatus.audioAvailable; anchors.verticalCenter: parent.verticalCenter }
        Icon { name: Icons.batteryIcon(SystemStatus.batteryPercent, SystemStatus.batteryCharging); size: 26
               visible: SystemStatus.hasBattery; anchors.verticalCenter: parent.verticalCenter }
        Rectangle {
            width: 36; height: 28; radius: 9
            anchors.verticalCenter: parent.verticalCenter
            color: ccArea.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.12)
            Icon { anchors.centerIn: parent; name: Icons.toggles; size: 20; }
            MouseArea {
                id: ccArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: UiState.toggleCenter()
            }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 15
            text: bar.now.toLocaleDateString(bar.loc, "ddd d MMM").replace(".", "")
                  + "  " + bar.now.toLocaleTimeString(bar.loc, "HH:mm")
        }
    }
}
