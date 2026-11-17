import QtQuick
import BCShell

// Música (como la app de macOS): barra lateral (Biblioteca: Canciones, Álbumes, Artistas), reproductor en la barra de
// herramientas (anterior · reproducir/pausa · siguiente, carátula, título, barra de progreso) y la tabla de canciones.
// Reproduce ~/Música con mpv.
AppWindow {
    id: win
    sidebarWidth: 210
    width: 1040
    height: 660
    titlebarHeight: 52
    title: qsTr("Música")
    property string section: "songs"     // songs | albums | artists
    property string query: ""
    readonly property color red: "#FA2D48"
    readonly property var cur: Music.current >= 0 ? Music.songs[Music.current] : null
    readonly property var list: Music.songs.map((s, i) => Object.assign({ i: i }, s)).filter(s => query === "" || (s.title + " " + s.artist + " " + s.album).toLowerCase().indexOf(query.toLowerCase()) >= 0)
    readonly property var groups: {
        const k = section === "albums" ? "album" : "artist", m = {}
        for (const s of list) { const g = s[k] || qsTr("Desconocido"); (m[g] = m[g] || []).push(s) }
        return Object.keys(m).sort().map(g => ({ name: g, songs: m[g] }))
    }
    function mmss(s) { s = Math.max(0, Math.floor(s)); return Math.floor(s / 60) + ":" + ("0" + s % 60).slice(-2) }
    Component.onCompleted: Music.scan()

    titlebarContent: [
        Row {
            x: side.width + 20; anchors.verticalCenter: parent.verticalCenter; spacing: 14
            Repeater {
                model: [ { t: "⏮", a: "prev" }, { t: Music.playing ? "⏸" : "▶", a: "toggle" }, { t: "⏭", a: "next" } ]
                Text { required property var modelData; anchors.verticalCenter: parent.verticalCenter; text: modelData.t; color: Theme.textPrimary
                       font.pixelSize: modelData.a === "toggle" ? 22 : 16
                       MouseArea { anchors.fill: parent; anchors.margins: -6
                                   onClicked: modelData.a === "toggle" ? Music.toggle() : (modelData.a === "next" ? Music.next() : Music.previous()) } }
            }
        },
        // «LCD» central con carátula, título y progreso
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.horizontalCenterOffset: 60; anchors.verticalCenter: parent.verticalCenter
            width: Math.min(440, parent.width - side.width - 420); height: 38; radius: 7; color: Theme.tileFill; border.width: 1; border.color: Theme.hairline
            Rectangle { x: 4; anchors.verticalCenter: parent.verticalCenter; width: 30; height: 30; radius: 4
                        gradient: Gradient { GradientStop { position: 0; color: "#FF6B81" } GradientStop { position: 1; color: win.red } }
                        Text { anchors.centerIn: parent; text: "♪"; color: "white"; font.pixelSize: 16 } }
            Column {
                x: 42; width: parent.width - 52; anchors.verticalCenter: parent.verticalCenter; spacing: 1
                Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.DemiBold
                       text: win.cur ? win.cur.title : (Music.available ? qsTr("Música") : qsTr("Falta mpv para reproducir")) }
                Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 10
                       text: win.cur ? [win.cur.artist, win.cur.album].filter(x => x).join(" — ") : "" }
                Rectangle {
                    width: parent.width; height: 3; radius: 1.5; color: Theme.fill; visible: win.cur !== null
                    Rectangle { width: Music.duration > 0 ? parent.width * Music.position / Music.duration : 0; height: parent.height; radius: 1.5; color: Theme.textSecondary }
                    MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: (m) => { if (Music.duration > 0) Music.seek(Music.duration * m.x / width) } }
                }
            }
        },
        Rectangle {
            anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
            width: 180; height: 26; radius: 7; color: Theme.tileFill
            Icon { x: 7; anchors.verticalCenter: parent.verticalCenter; name: Icons.search; size: 13; color: Theme.textSecondary }
            TextInput { x: 26; width: parent.width - 32; anchors.verticalCenter: parent.verticalCenter; color: Theme.textPrimary
                        font.family: Theme.fontFamily; font.pixelSize: 12; clip: true; onTextChanged: win.query = text
                        Text { visible: !parent.text; text: qsTr("Buscar"); color: Theme.textSecondary; font: parent.font } }
        }
    ]

    Rectangle {
        id: side
        y: -win.titlebarHeight; width: 210; height: parent.height + win.titlebarHeight; color: "transparent"
        SidebarGlass { anchors.fill: parent; active: win.active; z: -1 }
        Column {
            y: win.titlebarHeight + 8; x: 10; width: parent.width - 20; spacing: 2
            Text { leftPadding: 8; bottomPadding: 4; text: qsTr("Biblioteca"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold }
            Repeater {
                model: [ { k: "songs", t: qsTr("Canciones"), i: "audio-x-generic" }, { k: "albums", t: qsTr("Álbumes"), i: "folder-music-symbolic" }, { k: "artists", t: qsTr("Artistas"), i: "system-users-symbolic" } ]
                Rectangle {
                    required property var modelData
                    width: parent.width; height: 30; radius: 7; color: win.section === modelData.k ? Theme.tileFill : "transparent"
                    Icon { x: 9; anchors.verticalCenter: parent.verticalCenter; name: modelData.i; size: 16; color: win.active ? win.red : Theme.textSecondary }
                    Text { x: 34; anchors.verticalCenter: parent.verticalCenter; text: modelData.t; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13 }
                    MouseArea { anchors.fill: parent; onClicked: win.section = modelData.k }
                }
            }
        }
    }

    Item {
        x: side.width; width: parent.width - side.width; height: parent.height
        Text { x: 24; y: 10; text: win.section === "songs" ? qsTr("Canciones") : (win.section === "albums" ? qsTr("Álbumes") : qsTr("Artistas"))
               color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 24; font.weight: Font.Bold }
        // Canciones
        Item {
            visible: win.section === "songs"
            y: 50; width: parent.width; height: parent.height - 50
            Row {
                id: hdr; x: 16; width: parent.width - 32; height: 24
                Repeater { model: [ { t: qsTr("Título"), w: 0.45 }, { t: qsTr("Artista"), w: 0.27 }, { t: qsTr("Álbum"), w: 0.28 } ]
                    Text { required property var modelData; width: hdr.width * modelData.w; leftPadding: 30; text: modelData.t; color: Theme.textSecondary
                           font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.DemiBold } }
            }
            ListView {
                id: songs; x: 16; y: 26; width: parent.width - 32; height: parent.height - 26; clip: true
                OverlayScroll { flick: songs }
                model: win.list
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: songs.width; height: 28; radius: 5
                    color: modelData.i === Music.current ? Qt.rgba(0.98, 0.18, 0.28, 0.18) : (index % 2 ? Theme.tileFill : "transparent")
                    Text { x: 8; anchors.verticalCenter: parent.verticalCenter; text: modelData.i === Music.current ? (Music.playing ? "♪" : "‖") : ""; color: win.red; font.pixelSize: 12 }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        Repeater { model: [ { v: modelData.title, w: 0.45 }, { v: modelData.artist, w: 0.27 }, { v: modelData.album, w: 0.28 } ]
                            Text { required property var modelData; width: hdr.width * modelData.w; leftPadding: 30; rightPadding: 8; elide: Text.ElideRight; text: modelData.v
                                   color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12 } }
                    }
                    MouseArea { anchors.fill: parent; onDoubleClicked: Music.play(modelData.i) }
                }
                Column {
                    visible: Music.songs.length === 0; anchors.centerIn: parent; spacing: 8
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "♫"; color: win.red; font.pixelSize: 48 }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: qsTr("Tu biblioteca está vacía"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 15; font.weight: Font.Bold }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: qsTr("Copia canciones en la carpeta Música y aparecerán aquí."); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                }
            }
        }
        // Álbumes / Artistas: rejilla de tarjetas
        GridView {
            visible: win.section !== "songs"
            x: 16; y: 54; width: parent.width - 32; height: parent.height - 60; clip: true
            cellWidth: 170; cellHeight: 210
            model: win.groups
            delegate: Item {
                required property var modelData
                width: 170; height: 210
                Rectangle { x: 10; width: 150; height: 150; radius: win.section === "artists" ? 75 : 8
                            gradient: Gradient { GradientStop { position: 0; color: Qt.hsla((modelData.name.charCodeAt(0) * 37 % 360) / 360, 0.55, 0.55, 1) }
                                                 GradientStop { position: 1; color: Qt.hsla((modelData.name.charCodeAt(0) * 37 % 360) / 360, 0.6, 0.32, 1) } }
                            Text { anchors.centerIn: parent; text: win.section === "artists" ? modelData.name.charAt(0).toUpperCase() : "♪"; color: "white"; font.pixelSize: 54; font.weight: Font.Bold } }
                Text { x: 10; y: 158; width: 150; elide: Text.ElideRight; text: modelData.name; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12; font.weight: Font.DemiBold }
                Text { x: 10; y: 176; text: qsTr("%n canciones", "", modelData.songs.length); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11 }
                MouseArea { anchors.fill: parent; onDoubleClicked: Music.play(modelData.songs[0].i) }
            }
        }
    }
    Shortcut { sequence: "Space"; onActivated: Music.toggle() }
    Connections { target: AppActions; function onActionInvoked(a) { if (a === "close") win.closeRequested() } }
}
