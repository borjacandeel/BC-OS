import QtQuick
import BCShell

// Panel de capturas (⌘⇧5), como el de macOS: barra de cristal abajo en el centro con
//   ✕ · pantalla completa · ventana · selección | grabar pantalla · grabar selección | Opciones ▾ · Capturar/Grabar
// Recuerda el último modo. Opciones: dónde guardar y temporizador. Intro captura; Esc cierra.
Item {
    id: sp
    anchors.fill: parent
    property bool on: false
    readonly property real s: Theme.s
    function px(v) { return Math.round(v * s) }
    property string mode: UiState.shotMode    // pantalla, ventana, seleccion, grabar-pantalla, grabar-seleccion
    property int timer: 0
    property string where: Quick.capturePref()
    property bool optionsOpen: false
    readonly property bool record: mode.indexOf("grabar") === 0
    visible: opacity > 0
    opacity: on ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.d(Theme.durPopover); easing.type: Theme.easeStandard } }
    Component.onCompleted: bar.forceActiveFocus()

    function go() {
        UiState.shotMode = mode
        UiState.closePopups()
        const t = timer > 0 ? "-t " + timer + " " : ""
        const cmd = UiState.recording ? "detener"
                  : mode === "pantalla" ? t + "pantalla"
                  : mode === "grabar-pantalla" ? "grabar-pantalla"
                  : mode === "grabar-seleccion" ? "grabar-area"
                  : t + "area"   // ventana y selección: clic en una ventana o arrastrar una zona
        // un instante para que el panel desaparezca antes de capturar
        Launcher.run("sh", ["-c", "sleep 0.3; exec bc-screenshot " + cmd])
    }

    MouseArea { anchors.fill: parent; onClicked: UiState.closePopups() }

    component ModeBtn: Rectangle {
        id: mb
        property string m
        property string tip
        default property alias glyph: g.data
        width: sp.px(44); height: sp.px(40); radius: sp.px(10)
        color: sp.mode === m ? Qt.rgba(1, 1, 1, Theme.dark ? 0.22 : 0.55) : (ma.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent")
        Item { id: g; anchors.centerIn: parent; width: sp.px(24); height: sp.px(18) }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: sp.mode = mb.m; onDoubleClicked: { sp.mode = mb.m; sp.go() } }
        Rectangle {   // nombre al pasar el puntero, como macOS
            visible: ma.containsMouse; anchors.horizontalCenter: parent.horizontalCenter; y: -height - sp.px(8)
            width: tt.implicitWidth + sp.px(16); height: sp.px(24); radius: sp.px(6); color: Theme.dark ? "#2A2A30" : "#FFFFFF"
            border.width: 1; border.color: Theme.separator
            Text { id: tt; anchors.centerIn: parent; text: mb.tip; color: Theme.label; font.family: Theme.font; font.pixelSize: sp.px(11) }
        }
    }
    component Sep: Rectangle { width: 1; height: sp.px(26); color: Theme.separator; anchors.verticalCenter: parent ? parent.verticalCenter : undefined }

    Item {
        id: bar
        focus: true
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height - height - sp.px(120) + (sp.on ? 0 : sp.px(12))
        Behavior on y { NumberAnimation { duration: Theme.d(Theme.durPopover); easing.type: Theme.easeEmphasized } }
        width: row.width + sp.px(20); height: sp.px(56)
        Keys.onEscapePressed: UiState.closePopups()
        Keys.onReturnPressed: sp.go()
        Keys.onEnterPressed: sp.go()
        MouseArea { anchors.fill: parent }
        Glass { anchors.fill: parent; radius: sp.px(16); tintBoost: 0.5 }
        Row {
            id: row
            anchors.centerIn: parent; spacing: sp.px(6)
            Rectangle {   // cerrar
                width: sp.px(28); height: width; radius: width / 2; anchors.verticalCenter: parent.verticalCenter
                color: cx.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.12)
                Text { anchors.centerIn: parent; text: "✕"; color: Theme.label; font.pixelSize: sp.px(12) }
                MouseArea { id: cx; anchors.fill: parent; hoverEnabled: true; onClicked: UiState.closePopups() }
            }
            Sep {}
            ModeBtn { m: "pantalla"; tip: qsTr("Capturar toda la pantalla")
                Rectangle { anchors.fill: parent; radius: sp.px(3); color: "transparent"; border.width: sp.px(1.6); border.color: Theme.label } }
            ModeBtn { m: "ventana"; tip: qsTr("Capturar la ventana seleccionada")
                Rectangle { anchors.fill: parent; radius: sp.px(3); color: "transparent"; border.width: sp.px(1.6); border.color: Theme.label
                    Rectangle { x: sp.px(4); y: sp.px(4); width: parent.width - sp.px(8); height: parent.height - sp.px(8); radius: sp.px(2); color: Theme.label; opacity: 0.85 } } }
            ModeBtn { m: "seleccion"; tip: qsTr("Capturar una parte de la pantalla")
                Canvas { anchors.fill: parent; property color ink: Theme.label; onInkChanged: requestPaint()
                    onPaint: { const c = getContext("2d"); c.reset(); c.strokeStyle = ink; c.lineWidth = sp.px(1.6); c.setLineDash([sp.px(3), sp.px(2.5)])
                               c.strokeRect(sp.px(1), sp.px(1), width - sp.px(2), height - sp.px(2)) } } }
            Sep {}
            ModeBtn { m: "grabar-pantalla"; tip: qsTr("Grabar toda la pantalla")
                Rectangle { anchors.fill: parent; radius: sp.px(3); color: "transparent"; border.width: sp.px(1.6); border.color: Theme.label
                    Rectangle { anchors.centerIn: parent; width: sp.px(8); height: width; radius: width / 2; color: Theme.label } } }
            ModeBtn { m: "grabar-seleccion"; tip: qsTr("Grabar una parte de la pantalla")
                Canvas { anchors.fill: parent; property color ink: Theme.label; onInkChanged: requestPaint()
                    onPaint: { const c = getContext("2d"); c.reset(); c.strokeStyle = ink; c.lineWidth = sp.px(1.6); c.setLineDash([sp.px(3), sp.px(2.5)])
                               c.strokeRect(sp.px(1), sp.px(1), width - sp.px(2), height - sp.px(2)); c.setLineDash([])
                               c.fillStyle = ink; c.beginPath(); c.arc(width / 2, height / 2, sp.px(4), 0, 2 * Math.PI); c.fill() } } }
            Sep {}
            Rectangle {   // Opciones ▾
                width: ot.implicitWidth + sp.px(24); height: sp.px(32); radius: sp.px(8); anchors.verticalCenter: parent.verticalCenter
                color: om.containsMouse || sp.optionsOpen ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
                Text { id: ot; anchors.centerIn: parent; text: qsTr("Opciones") + "  ▾"; color: Theme.label; font.family: Theme.font; font.pixelSize: sp.px(13) }
                MouseArea { id: om; anchors.fill: parent; hoverEnabled: true; onClicked: sp.optionsOpen = !sp.optionsOpen }
            }
            Rectangle {   // Capturar / Grabar / Detener
                width: ct.implicitWidth + sp.px(28); height: sp.px(32); radius: sp.px(8); anchors.verticalCenter: parent.verticalCenter
                color: cm.containsMouse ? Qt.lighter(Theme.accent, 1.12) : Theme.accent
                Text { id: ct; anchors.centerIn: parent; color: "white"; font.family: Theme.font; font.pixelSize: sp.px(13); font.weight: Font.DemiBold
                       text: UiState.recording ? qsTr("Detener") : (sp.record ? qsTr("Grabar") : qsTr("Capturar")) }
                MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; onClicked: sp.go() }
            }
        }
        // Menú de opciones
        Item {
            visible: sp.optionsOpen
            x: bar.width - width - sp.px(80); y: -height - sp.px(10)
            width: sp.px(210); height: oc.height + sp.px(16)
            MouseArea { anchors.fill: parent }
            Glass { anchors.fill: parent; radius: sp.px(12); tintBoost: 0.6 }
            Column {
                id: oc; x: sp.px(8); y: sp.px(8); width: parent.width - sp.px(16)
                Text { leftPadding: sp.px(8); text: qsTr("Guardar en"); color: Theme.labelSecondary; font.family: Theme.font; font.pixelSize: sp.px(11); font.weight: Font.DemiBold; height: sp.px(22); verticalAlignment: Text.AlignVCenter }
                Repeater {
                    model: [{ k: "escritorio", t: qsTr("Escritorio") }, { k: "documentos", t: qsTr("Documentos") }, { k: "imagenes", t: qsTr("Imágenes") }, { k: "portapapeles", t: qsTr("Portapapeles") }]
                    Rectangle {
                        required property var modelData
                        width: oc.width; height: sp.px(26); radius: sp.px(6); color: wm.containsMouse ? Theme.accent : "transparent"
                        Text { x: sp.px(8); anchors.verticalCenter: parent.verticalCenter; text: (sp.where === modelData.k ? "✓  " : "     ") + modelData.t
                               color: wm.containsMouse ? "white" : Theme.label; font.family: Theme.font; font.pixelSize: sp.px(13) }
                        MouseArea { id: wm; anchors.fill: parent; hoverEnabled: true; onClicked: { if (Quick.setCapturePref(modelData.k)) sp.where = modelData.k } }
                    }
                }
                Rectangle { width: oc.width; height: sp.px(9); color: "transparent"; Rectangle { anchors.centerIn: parent; width: parent.width - sp.px(12); height: 1; color: Theme.separator } }
                Text { leftPadding: sp.px(8); text: qsTr("Temporizador"); color: Theme.labelSecondary; font.family: Theme.font; font.pixelSize: sp.px(11); font.weight: Font.DemiBold; height: sp.px(22); verticalAlignment: Text.AlignVCenter }
                Repeater {
                    model: [{ k: 0, t: qsTr("Ninguno") }, { k: 5, t: qsTr("5 segundos") }, { k: 10, t: qsTr("10 segundos") }]
                    Rectangle {
                        required property var modelData
                        width: oc.width; height: sp.px(26); radius: sp.px(6); color: tm.containsMouse ? Theme.accent : "transparent"
                        Text { x: sp.px(8); anchors.verticalCenter: parent.verticalCenter; text: (sp.timer === modelData.k ? "✓  " : "     ") + modelData.t
                               color: tm.containsMouse ? "white" : Theme.label; font.family: Theme.font; font.pixelSize: sp.px(13) }
                        MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; onClicked: sp.timer = modelData.k }
                    }
                }
            }
        }
    }
}
