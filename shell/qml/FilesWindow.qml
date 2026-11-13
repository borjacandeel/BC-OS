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

    property int selected: 0
    readonly property var places: [
        { name: qsTr("Inicio"), icon: Icons.home },
        { name: qsTr("Escritorio"), icon: Icons.desktop },
        { name: qsTr("Documentos"), icon: Icons.document },
        { name: qsTr("Descargas"), icon: Icons.download },
        { name: qsTr("Imágenes"), icon: Icons.image },
        { name: qsTr("Música"), icon: Icons.music }
    ]
    readonly property var items: [
        { name: qsTr("Proyectos"), kind: "carpeta" },
        { name: qsTr("Trabajo"), kind: "carpeta" },
        { name: qsTr("Personal"), kind: "carpeta" },
        { name: qsTr("Fotos"), kind: "carpeta" },
        { name: "README.md", kind: "codigo" },
        { name: "Notas.txt", kind: "texto" },
        { name: "Captura.png", kind: "imagen" },
        { name: "Curriculum.pdf", kind: "pdf" }
    ]

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
                Rectangle { width: 22; height: 22; radius: 11; color: modelData }
            }
        }
        Row {
            x: 145; anchors.verticalCenter: parent.verticalCenter; spacing: 5
            Repeater {
                model: [Icons.chevronLeft, Icons.chevronRight]
                Rectangle {
                    width: 39; height: 37; radius: 10; color: Qt.rgba(1, 1, 1, 0.12)
                    Icon { anchors.centerIn: parent; path: modelData; size: 22; color: Theme.textSecondary; strokeWidth: 2 }
                }
            }
        }
        Row {
            x: 261; anchors.verticalCenter: parent.verticalCenter; spacing: 10
            Icon { path: Icons.home; size: 24; strokeWidth: 1.9; anchors.verticalCenter: parent.verticalCenter }
            Text { text: qsTr("Inicio"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 16
                   anchors.verticalCenter: parent.verticalCenter }
            Icon { path: Icons.chevronRight; size: 18; strokeWidth: 2; anchors.verticalCenter: parent.verticalCenter }
            Text { text: qsTr("Documentos"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 16
                   anchors.verticalCenter: parent.verticalCenter }
        }
        Rectangle {
            x: 655; width: 324; height: 38; radius: 19
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(1, 1, 1, 0.10)
            Icon { x: 15; anchors.verticalCenter: parent.verticalCenter; path: Icons.search; size: 24; strokeWidth: 1.9 }
            Text { x: 49; anchors.verticalCenter: parent.verticalCenter; text: qsTr("Buscar")
                   color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 16 }
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
                color: index === win.selected ? Theme.accentSelected : (hov.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                Icon { x: 16; anchors.verticalCenter: parent.verticalCenter; path: modelData.icon; size: 24; strokeWidth: 1.8
                       filled: index === win.selected }
                Text { x: 59; anchors.verticalCenter: parent.verticalCenter; text: modelData.name
                       color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 16 }
                MouseArea { id: hov; anchors.fill: parent; hoverEnabled: true; onClicked: win.selected = index }
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

    // Cuadrícula de archivos
    Item {
        x: 239; y: titlebar.height
        width: parent.width - 239; height: parent.height - titlebar.height
        Repeater {
            model: win.items
            delegate: Item {
                readonly property int col: index % 4
                readonly property int row: Math.floor(index / 4)
                readonly property var cx: [107, 293, 476, 658]
                x: cx[col] - 70; y: 48 + row * 155
                width: 140; height: 140
                FileGlyph { kind: modelData.kind; anchors.horizontalCenter: parent.horizontalCenter }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 90
                    text: modelData.name
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                }
            }
        }
    }
}
