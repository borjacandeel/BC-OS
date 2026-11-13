import QtQuick
import BCShell

// BC Archivos: sidebar, ruta, búsqueda y cuadrícula.
Rectangle {
    id: win
    width: 995
    height: 458
    radius: Theme.radiusWindow
    color: Theme.panelFill
    border.width: 1
    border.color: Theme.hairline
    clip: true

    signal closeRequested()
    property int current: -1
    readonly property var places: [
        { key: "home", name: qsTr("Inicio"), icon: Icons.home },
        { key: "desktop", name: qsTr("Escritorio"), icon: Icons.desktop },
        { key: "documents", name: qsTr("Documentos"), icon: Icons.document },
        { key: "downloads", name: qsTr("Descargas"), icon: Icons.download },
        { key: "pictures", name: qsTr("Imágenes"), icon: Icons.image },
        { key: "music", name: qsTr("Música"), icon: Icons.music }
    ]
    Connections { target: Files; function onPathChanged() { win.current = -1 } }

    // Barra de título
    Rectangle {
        id: titlebar
        width: parent.width
        height: 60
        color: Qt.rgba(1, 1, 1, 0.04)
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.hairline }

        Row {
            x: 21; anchors.verticalCenter: parent.verticalCenter; spacing: 20
            Repeater {
                model: [Theme.close, Theme.minimize, Theme.zoom]
                Rectangle {
                    width: 22; height: 22; radius: 11; color: modelData
                    MouseArea { anchors.fill: parent; enabled: index === 0; onClicked: win.closeRequested() }
                }
            }
        }
        Row {
            x: 145; anchors.verticalCenter: parent.verticalCenter; spacing: 5
            Repeater {
                model: [
                    { path: Icons.chevronLeft, on: Files.canBack, act: 0 },
                    { path: Icons.chevronRight, on: Files.canForward, act: 1 },
                    { path: Icons.chevronUp, on: Files.canUp, act: 2 }
                ]
                Rectangle {
                    width: 39; height: 37; radius: 10
                    color: modelData.on ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05)
                    Icon { anchors.centerIn: parent; path: modelData.path; size: 22; strokeWidth: 2
                           color: modelData.on ? Theme.textPrimary : Theme.textSecondary; opacity: modelData.on ? 1 : 0.5 }
                    MouseArea {
                        anchors.fill: parent; enabled: modelData.on
                        onClicked: modelData.act === 0 ? Files.back() : (modelData.act === 1 ? Files.forward() : Files.up())
                    }
                }
            }
        }
        Item {
            id: crumbBox
            x: 295; width: 345; height: parent.height; clip: true
            Row {
                id: crumbRow
                x: Math.min(0, crumbBox.width - width)
                anchors.verticalCenter: parent.verticalCenter; spacing: 6
                Repeater {
                    model: Files.crumbs
                    delegate: Row {
                        spacing: 6
                        anchors.verticalCenter: parent.verticalCenter
                        Icon { visible: index > 0; path: Icons.chevronRight; size: 16; strokeWidth: 2
                               anchors.verticalCenter: parent.verticalCenter; color: Theme.textSecondary }
                        Item {
                            width: crumbLabel.width + (modelData.home ? 30 : 0); height: 30
                            anchors.verticalCenter: parent.verticalCenter
                            Icon { visible: modelData.home; path: Icons.home; size: 22; strokeWidth: 1.9
                                   anchors.verticalCenter: parent.verticalCenter }
                            Text {
                                id: crumbLabel
                                x: modelData.home ? 30 : 0
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.home ? "" : modelData.name
                                color: index === Files.crumbs.length - 1 ? Theme.textPrimary : Theme.textSecondary
                                font.family: Theme.fontFamily; font.pixelSize: 16
                                font.weight: index === Files.crumbs.length - 1 ? Font.DemiBold : Font.Normal
                            }
                            MouseArea { anchors.fill: parent; onClicked: Files.open(modelData.path) }
                        }
                    }
                }
            }
        }
        Rectangle {
            x: 655; width: 324; height: 38; radius: 19
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(1, 1, 1, 0.10)
            Icon { x: 15; anchors.verticalCenter: parent.verticalCenter; path: Icons.search; size: 24; strokeWidth: 1.9 }
            TextInput {
                id: search
                x: 49; width: parent.width - 49 - 36; anchors.verticalCenter: parent.verticalCenter
                text: Files.filter
                onTextEdited: Files.filter = text
                color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 16
                selectionColor: Theme.accent; clip: true
                Keys.onEscapePressed: { Files.filter = ""; focus = false }
                Text { visible: !search.text && !search.activeFocus; text: qsTr("Buscar")
                       color: Theme.textSecondary; font: search.font }
            }
            Item {
                visible: search.text !== ""
                x: parent.width - 34; width: 28; height: 28; anchors.verticalCenter: parent.verticalCenter
                Icon { anchors.centerIn: parent; path: Icons.closeX; size: 14; strokeWidth: 2 }
                MouseArea { anchors.fill: parent; onClicked: Files.filter = "" }
            }
        }
    }

    // Barra lateral
    Rectangle {
        y: titlebar.height
        width: 239
        height: parent.height - titlebar.height
        color: Theme.sidebarFill
        Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.hairline }

        Repeater {
            model: win.places
            delegate: Rectangle {
                x: 12; y: 14 + index * 46.5
                width: 213; height: 46; radius: Theme.radiusControl
                color: Files.path === Files.placePath(modelData.key) ? Theme.accentSelected : (hov.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                Icon { x: 16; anchors.verticalCenter: parent.verticalCenter; path: modelData.icon; size: 24; strokeWidth: 1.8
                       filled: Files.path === Files.placePath(modelData.key) }
                Text { x: 59; anchors.verticalCenter: parent.verticalCenter; text: modelData.name
                       color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 16 }
                MouseArea { id: hov; anchors.fill: parent; hoverEnabled: true; onClicked: Files.place(modelData.key) }
            }
        }
        Rectangle { x: 12; y: 313; width: 213; height: 1; color: Theme.hairline }
        Rectangle {
            x: 12; y: 332; width: 213; height: 46; radius: Theme.radiusControl; color: "transparent"
            Icon { x: 16; anchors.verticalCenter: parent.verticalCenter; path: Icons.trash; size: 24; strokeWidth: 1.8 }
            Text { x: 59; anchors.verticalCenter: parent.verticalCenter; text: qsTr("Papelera")
                   color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 16 }
        }
    }

    // Cuadrícula de archivos (directorio real)
    Item {
        x: 239; y: titlebar.height
        width: parent.width - 239; height: parent.height - titlebar.height
        GridView {
            id: grid
            anchors.fill: parent
            anchors.margins: 12
            clip: true
            cellWidth: Math.floor(width / 4)
            cellHeight: 136
            model: Files
            boundsBehavior: Flickable.StopAtBounds
            delegate: Item {
                id: cell
                required property int index
                required property string name
                required property string kind
                width: grid.cellWidth; height: grid.cellHeight
                Rectangle {
                    anchors.fill: parent; anchors.margins: 4; radius: Theme.radiusControl
                    color: win.current === cell.index ? Theme.accentSelected : (ma.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                }
                FileGlyph { kind: cell.kind; anchors.horizontalCenter: parent.horizontalCenter; y: 6 }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 88; width: parent.width - 16
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideMiddle
                    text: cell.name
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                }
                MouseArea {
                    id: ma
                    anchors.fill: parent; hoverEnabled: true
                    onClicked: win.current = cell.index
                    onDoubleClicked: Files.activate(cell.index)
                }
            }
        }
        Column {
            visible: Files.count === 0
            anchors.centerIn: parent; spacing: 8
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: !Files.available ? qsTr("La carpeta no existe o no se puede leer")
                      : (Files.filter !== "" ? qsTr("Sin resultados") : qsTr("Carpeta vacía"))
                color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 17; font.weight: Font.DemiBold
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: Files.available && Files.filter !== ""
                text: qsTr("Ningún nombre contiene «%1»").arg(Files.filter)
                color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 14
            }
        }
    }
}
