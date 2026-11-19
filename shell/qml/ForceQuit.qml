import QtQuick
import BCShell

// «Forzar salida de las aplicaciones» (⌥⌘⎋ en macOS; aquí Ctrl+Alt+Esc o menú BC ▸ Forzar salida…): ventana compacta
// con las apps abiertas; la elegida se cierra sin guardar (SIGKILL a su proceso).
Item {
    id: fq
    anchors.fill: parent
    visible: opacity > 0
    opacity: UiState.forceQuitOpen ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.d(160); easing.type: Easing.OutCubic } }
    readonly property real s: Theme.s
    function px(v) { return Math.round(v * s) }
    property var apps: []
    property int sel: 0
    function build() {
        const seen = {}, out = []
        for (const w of Sway.windows) {
            if (!w.appId || seen[w.appId] || !(w.pid > 0)) continue
            seen[w.appId] = true
            const info = Apps.infoFor(w.appId)
            out.push({ appId: w.appId, pid: w.pid, name: info.name || AppMenus.nameFor(w.appId), icon: info.iconPath || "",
                       kind: ({ "bc-files": "archivos", "bc-settings": "ajustes", "bc-monitor": "monitor", "bc-store": "tienda", "bc-notes": "notas",
                                "bc-calculator": "calculadora", "bc-preview": "vista", "bc-music": "musica" })[w.appId] || "" })
        }
        apps = out; sel = 0
    }
    Connections { target: UiState; function onForceQuitOpenChanged() { if (UiState.forceQuitOpen) { fq.build(); card.forceActiveFocus() } } }
    Component.onCompleted: if (UiState.forceQuitOpen) { fq.build(); card.forceActiveFocus() }   // se crea al abrirse (Lazy)
    function doQuit() {
        const a = apps[sel]; if (!a) return
        Processes.quit(a.pid, true)
        UiState.forceQuitOpen = false
    }

    MouseArea { anchors.fill: parent; enabled: UiState.forceQuitOpen; onClicked: UiState.forceQuitOpen = false }
    Item {
        id: card
        width: px(380); height: col.height + px(32)
        anchors.centerIn: parent
        scale: UiState.forceQuitOpen ? 1 : 0.96
        Behavior on scale { NumberAnimation { duration: Theme.d(180); easing.type: Easing.OutCubic } }
        focus: UiState.forceQuitOpen
        Keys.onEscapePressed: UiState.forceQuitOpen = false
        Keys.onUpPressed: fq.sel = Math.max(0, fq.sel - 1)
        Keys.onDownPressed: fq.sel = Math.min(fq.apps.length - 1, fq.sel + 1)
        Keys.onReturnPressed: fq.doQuit()
        MouseArea { anchors.fill: parent }
        Glass { anchors.fill: parent; radius: px(18); tintBoost: 0.6 }
        Column {
            id: col
            x: px(18); y: px(16); width: parent.width - px(36); spacing: px(10)
            Text { width: parent.width; text: qsTr("Forzar salida de las aplicaciones"); color: Theme.label; font.family: Theme.font
                   font.pixelSize: px(14); font.weight: Font.Bold; horizontalAlignment: Text.AlignHCenter }
            Text { width: parent.width; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; color: Theme.labelSecondary
                   font.family: Theme.font; font.pixelSize: px(12)
                   text: qsTr("Si una aplicación no responde, selecciónala y haz clic en «Forzar salida». Se perderán los cambios sin guardar.") }
            Rectangle {
                width: parent.width; height: Math.max(px(60), Math.min(px(260), fq.apps.length * px(34) + px(8))); radius: px(10)
                color: Theme.dark ? Qt.rgba(0, 0, 0, 0.25) : Qt.rgba(1, 1, 1, 0.55); border.width: 1; border.color: Theme.separator; clip: true
                ListView {
                    id: lv; anchors.fill: parent; anchors.margins: px(4); model: fq.apps; spacing: 0
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: lv.width; height: px(34); radius: px(7)
                        color: fq.sel === index ? Theme.accent : "transparent"
                        AppIcon { visible: modelData.kind !== ""; kind: modelData.kind; size: px(24); x: px(8); anchors.verticalCenter: parent.verticalCenter }
                        Image { visible: modelData.kind === ""; width: px(24); height: width; x: px(8); anchors.verticalCenter: parent.verticalCenter
                                sourceSize: Qt.size(48, 48); smooth: true
                                source: modelData.icon ? "file://" + modelData.icon : "qrc:/BCShell/apps/text-x-script.svg" }
                        Text { x: px(40); anchors.verticalCenter: parent.verticalCenter; text: modelData.name
                               color: fq.sel === index ? "white" : Theme.label; font.family: Theme.font; font.pixelSize: px(13) }
                        MouseArea { anchors.fill: parent; onClicked: fq.sel = index; onDoubleClicked: { fq.sel = index; fq.doQuit() } }
                    }
                }
                Text { anchors.centerIn: parent; visible: fq.apps.length === 0; text: qsTr("No hay aplicaciones abiertas")
                       color: Theme.labelSecondary; font.family: Theme.font; font.pixelSize: px(12) }
            }
            Row {
                anchors.right: parent.right; spacing: px(8)
                Rectangle {
                    width: px(96); height: px(28); radius: height / 2; color: Theme.dark ? Qt.rgba(1, 1, 1, cma.containsMouse ? 0.2 : 0.12) : Qt.rgba(0, 0, 0, cma.containsMouse ? 0.12 : 0.07)
                    Text { anchors.centerIn: parent; text: qsTr("Cancelar"); color: Theme.label; font.family: Theme.font; font.pixelSize: px(13) }
                    MouseArea { id: cma; anchors.fill: parent; hoverEnabled: true; onClicked: UiState.forceQuitOpen = false }
                }
                Rectangle {
                    width: px(120); height: px(28); radius: height / 2; opacity: fq.apps.length ? 1 : 0.4
                    color: qma.containsMouse ? Theme.accentSelected : Theme.accent
                    Text { anchors.centerIn: parent; text: qsTr("Forzar salida"); color: "white"; font.family: Theme.font; font.pixelSize: px(13); font.weight: Font.DemiBold }
                    MouseArea { id: qma; anchors.fill: parent; hoverEnabled: true; enabled: fq.apps.length > 0; onClicked: fq.doQuit() }
                }
            }
        }
    }
}
