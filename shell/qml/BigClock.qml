import QtQuick
import BCShell

// Fecha y hora grandes de la pantalla de login y de bloqueo.
Item {
    id: root
    property date now: new Date()
    readonly property var loc: Qt.locale(AppConfig.language)
    readonly property string dateFormat: AppConfig.language.indexOf("en") === 0 ? "dddd, MMMM d" : (Theme.gg ? "dddd, d 'de' MMMM" : "dddd d 'de' MMMM")
    width: col.width
    height: col.height

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.now = AppConfig.fixedTime !== "" ? new Date(AppConfig.fixedTime) : new Date()
    }
    Column {
        id: col
        spacing: 2
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: { const s = root.now.toLocaleDateString(root.loc, root.dateFormat); return s.charAt(0).toUpperCase() + s.slice(1) }
            color: Qt.rgba(1, 1, 1, 0.88)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.gg ? 22 : 24
            font.weight: Theme.gg ? Font.DemiBold : Font.Medium
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.now.toLocaleTimeString(root.loc, Theme.gg ? "H:mm" : "HH:mm")   // macOS 27: «8:52», sin cero
            // Golden Gate: hora enorme y gruesa, blanca translúcida (efecto vidrio sobre el fondo)
            color: Theme.gg ? Qt.rgba(1, 1, 1, 0.82) : Theme.white
            font.family: Theme.fontFamily
            font.pixelSize: Theme.gg ? 132 : 112
            font.weight: Theme.gg ? Font.DemiBold : Font.Light
            font.letterSpacing: Theme.gg ? -4 : -2
            style: Theme.gg ? Text.Raised : Text.Normal; styleColor: Qt.rgba(0, 0, 0, 0.12)
        }
    }
}
