import QtQuick
import BCShell

// Vista previa (como la de macOS): abre imágenes (y texto) de la carpeta, miniaturas en la barra lateral,
// zoom (ajustar / tamaño real / + / −), girar, flechas para pasar de imagen, y la información del archivo.
AppWindow {
    id: win
    sidebarWidth: showSidebar ? 180 : 0
    width: 980
    height: 680
    titlebarHeight: 52
    title: info ? info.name : qsTr("Vista previa")
    property int index: -1
    property real zoom: 0            // 0 = ajustar a la ventana
    property int rot: 0
    property bool showSidebar: true
    readonly property var info: index >= 0 ? folder.infoAt(index) : null

    FileModel {
        id: folder
        Component.onCompleted: {
            const p = AppConfig.openArg
            const dir = p !== "" ? p.substring(0, p.lastIndexOf("/")) : placePath("pictures")
            open(dir || "/")
            for (let i = 0; i < count; ++i) if (infoAt(i).path === p) { win.index = i; return }
            for (let i = 0; i < count; ++i) if (infoAt(i).kind === "imagen") { win.index = i; return }
        }
    }
    function step(d) {
        for (let i = index + d; i >= 0 && i < folder.count; i += d) {
            const k = folder.infoAt(i).kind
            if (k === "imagen" || k === "texto" || k === "codigo") { index = i; zoom = 0; rot = 0; return }
        }
    }

    titlebarContent: [
        Column {
            x: win.showSidebar ? 196 : 92; anchors.verticalCenter: parent.verticalCenter
            Text { text: win.info ? win.info.name : qsTr("Vista previa"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Bold; width: 300; elide: Text.ElideMiddle }
            Text { text: win.info ? win.info.size + (img.status === Image.Ready ? " · " + img.sourceSize.width + "×" + img.sourceSize.height : "") : ""; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
        },
        Row {
            anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 4
            Repeater {
                model: [ { i: "view-sidebar-symbolic", a: "side" }, { i: "zoom-out-symbolic", a: "out" }, { i: "zoom-in-symbolic", a: "in" },
                         { i: "view-restore-symbolic", a: "fit" }, { i: "view-refresh-symbolic", a: "rot" }, { i: "dialog-information-symbolic", a: "info" } ]
                Rectangle {
                    required property var modelData
                    width: 30; height: 26; radius: 7; color: tm.containsMouse ? Theme.tileFill : "transparent"
                    Icon { anchors.centerIn: parent; name: modelData.i; size: 16; color: Theme.textSecondary }
                    MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; onClicked: win.act(modelData.a) }
                }
            }
        }
    ]
    function act(a) {
        const fit = Math.min(view.width / Math.max(1, img.implicitWidth), view.height / Math.max(1, img.implicitHeight))
        const cur = zoom === 0 ? fit : zoom
        if (a === "side") showSidebar = !showSidebar
        else if (a === "in") zoom = Math.min(8, cur * 1.25)
        else if (a === "out") zoom = Math.max(0.05, cur / 1.25)
        else if (a === "fit") zoom = zoom === 0 ? 1 : 0
        else if (a === "rot") rot = (rot + 270) % 360
        else if (a === "info") infoPop.visible = !infoPop.visible
    }

    // Miniaturas
    Rectangle {
        id: side
        visible: win.showSidebar
        y: -win.titlebarHeight; width: 180; height: parent.height + win.titlebarHeight
        color: Theme.gg ? "transparent" : Theme.sidebarFill
        SidebarGlass { anchors.fill: parent; active: win.active; z: -1 }
        Rectangle { visible: !Theme.gg; anchors.right: parent.right; width: 1; height: parent.height; color: Theme.hairline }
        ListView {
            y: win.titlebarHeight + 8; x: 0; width: parent.width; height: parent.height - y - 8; clip: true; spacing: 6
            model: folder
            delegate: Item {
                required property int index
                required property string kind
                required property string filePath
                required property string name
                width: ListView.view.width; height: kind === "imagen" ? 120 : 0; visible: kind === "imagen"
                Rectangle { anchors.centerIn: th; width: th.paintedWidth + 8; height: th.paintedHeight + 8; radius: 5; color: "transparent"
                            border.width: 3; border.color: win.index === index ? Theme.accent : "transparent" }
                Image { id: th; anchors.horizontalCenter: parent.horizontalCenter; y: 6; width: parent.width - 40; height: 92; fillMode: Image.PreserveAspectFit
                        source: kind === "imagen" ? "file://" + filePath : ""; sourceSize: Qt.size(240, 184); asynchronous: true }
                Text { anchors.horizontalCenter: parent.horizontalCenter; y: 102; width: parent.width - 20; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideMiddle
                       text: name; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 10 }
                MouseArea { anchors.fill: parent; onClicked: { win.index = index; win.zoom = 0; win.rot = 0 } }
            }
        }
    }

    // Imagen
    Flickable {
        id: view
        OverlayScroll { flick: view }
        x: win.showSidebar ? side.width : 0; width: parent.width - x; height: parent.height
        contentWidth: Math.max(width, frame.width); contentHeight: Math.max(height, frame.height); clip: true
        boundsBehavior: Flickable.DragAndOvershootBounds
        // Fondo con la esquina inferior derecha de la ventana (las demás quedan fuera del recorte del Flickable)
        Rectangle { x: -Theme.radiusWindow; y: -Theme.radiusWindow; width: view.width + Theme.radiusWindow; height: view.height + Theme.radiusWindow
                    radius: Theme.radiusWindow; color: Theme.dark ? "#1C1C1E" : "#ECECEE"; z: -1 }
        Item {
            id: frame
            readonly property real fit: Math.min(view.width / Math.max(1, img.implicitWidth), view.height / Math.max(1, img.implicitHeight), 1)
            readonly property real s: win.zoom === 0 ? fit : win.zoom
            width: (win.rot % 180 === 0 ? img.implicitWidth : img.implicitHeight) * s
            height: (win.rot % 180 === 0 ? img.implicitHeight : img.implicitWidth) * s
            x: Math.max(0, (view.width - width) / 2); y: Math.max(0, (view.height - height) / 2)
            Image {
                id: img
                anchors.centerIn: parent
                width: implicitWidth * frame.s; height: implicitHeight * frame.s
                rotation: win.rot
                Behavior on rotation { NumberAnimation { duration: Theme.d(220); easing.type: Theme.easeStandard } }
                visible: win.info && win.info.kind === "imagen"
                source: visible ? "file://" + win.info.path : ""
                asynchronous: true; smooth: true; mipmap: true
            }
        }
        Rectangle {
            visible: win.info && (win.info.kind === "texto" || win.info.kind === "codigo")
            anchors.centerIn: parent; width: Math.min(parent.width - 60, 760); height: parent.height - 40; color: Theme.dark ? "#2A2A2C" : "white"; radius: 4
            Flickable { anchors.fill: parent; anchors.margins: 24; contentHeight: tx.height; clip: true
                Text { id: tx; width: parent.width; wrapMode: Text.Wrap; color: Theme.textPrimary; font.family: Theme.fontMono; font.pixelSize: 12
                       text: parent.parent.visible && win.info ? Files.textPreview(win.info.path, 100000) : "" } }
        }
        Text { visible: win.index < 0; anchors.centerIn: parent; text: qsTr("No hay imágenes en esta carpeta"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 14 }
        MouseArea { anchors.fill: parent; z: -1; onWheel: (w) => { if (w.modifiers & Qt.ControlModifier) win.act(w.angleDelta.y > 0 ? "in" : "out"); else w.accepted = false } }
    }

    // Inspector de información
    Rectangle {
        id: infoPop
        visible: false; z: 10
        anchors.right: parent.right; anchors.rightMargin: 12; y: 8; width: 260; height: infoCol.height + 24; radius: 12
        color: Theme.popupFill; border.width: 1; border.color: Theme.hairline
        Column {
            id: infoCol; x: 14; y: 12; width: parent.width - 28; spacing: 6
            Text { text: qsTr("Información"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Bold }
            Repeater {
                model: win.info ? [ [qsTr("Nombre"), win.info.name], [qsTr("Tipo"), win.info.mime], [qsTr("Tamaño"), win.info.size],
                                    [qsTr("Dimensiones"), img.status === Image.Ready ? img.implicitWidth + " × " + img.implicitHeight : "—"], [qsTr("Modificado"), win.info.modified] ] : []
                Row { required property var modelData; spacing: 8
                      Text { width: 80; text: modelData[0]; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11; horizontalAlignment: Text.AlignRight }
                      Text { width: infoCol.width - 88; text: modelData[1]; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 11; wrapMode: Text.WrapAnywhere } }
            }
        }
    }

    Item {
        focus: true
        Keys.onRightPressed: win.step(1); Keys.onDownPressed: win.step(1)
        Keys.onLeftPressed: win.step(-1); Keys.onUpPressed: win.step(-1)
        Keys.onPressed: (e) => { if (e.text === "+") win.act("in"); else if (e.text === "-") win.act("out"); else if (e.text === "0") win.zoom = 0 }
    }
    Shortcut { sequence: "Ctrl+R"; onActivated: win.act("rot") }
    Shortcut { sequence: "Ctrl+I"; onActivated: win.act("info") }
    Connections { target: AppActions; function onActionInvoked(a) { if (a === "close") win.closeRequested() } }
}
