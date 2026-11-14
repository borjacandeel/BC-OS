pragma Singleton
import QtQuick
import BCShell

QtObject {
    // Paleta de marca (assets/branding)
    readonly property color midnight: "#04111F"
    readonly property color white: "#F5F5F7"
    readonly property color silverLight: "#F6F8FC"
    readonly property color silverMid: "#D5DCE8"
    readonly property color silverDark: "#A1ADC0"

    // Acento y semánticos
    readonly property color accent: AppConfig.accent
    readonly property color accentSelected: Qt.darker(AppConfig.accent, 1.18)
    readonly property color close: "#FF5F57"
    readonly property color minimize: "#FEBC2E"
    readonly property color zoom: "#28C840"

    // Superficies (cristal ligero, sin desenfoque por CPU)
    // «Medianoche refinado»: azul noche más apagado y sobrio, con un solo acento
    readonly property color panelFill: Qt.rgba(0.06, 0.09, 0.16, 0.86)
    readonly property color panelFillSoft: Qt.rgba(0.09, 0.12, 0.20, 0.55)
    readonly property color sidebarFill: Qt.rgba(0.02, 0.04, 0.09, 0.45)
    readonly property color barFill: Qt.rgba(0.03, 0.05, 0.10, 0.72)
    readonly property color popupFill: Qt.rgba(0.06, 0.09, 0.16, 0.97)    // menús, lanzador, Centro de control
    readonly property color windowFill: Qt.rgba(0.05, 0.08, 0.14, 0.92)   // marco de las apps de BC
    readonly property color widgetFill: Qt.rgba(0.04, 0.07, 0.13, 0.62)
    readonly property color scrim: Qt.rgba(0.01, 0.03, 0.07, 0.55)        // velo bajo los diálogos
    readonly property color tileFill: Qt.rgba(1, 1, 1, 0.06)
    readonly property color hairline: Qt.rgba(1, 1, 1, 0.10)
    readonly property color textPrimary: white
    readonly property color textSecondary: Qt.rgba(1, 1, 1, 0.60)

    // Radios
    readonly property int radiusWindow: 22
    readonly property int radiusPanel: 26
    readonly property int radiusTile: 18
    readonly property int radiusControl: 10

    // Tipografía
    readonly property string fontFamily: "CaskaydiaCove Nerd Font"
    readonly property string fontMono: "CaskaydiaCove Nerd Font Mono"
    readonly property int sizeBody: 16
    readonly property int sizeSmall: 14

    // Movimiento
    readonly property bool reducedMotion: AppConfig.reducedMotion || Settings.reducedMotion
    function dur(ms) { return reducedMotion ? 0 : ms }
    readonly property int easing: Easing.OutCubic
}
