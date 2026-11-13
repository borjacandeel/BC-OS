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
    readonly property color accent: "#2F7BF5"
    readonly property color accentSelected: "#2D63D8"
    readonly property color close: "#FF5F57"
    readonly property color minimize: "#FEBC2E"
    readonly property color zoom: "#28C840"

    // Superficies (cristal ligero, sin desenfoque por CPU)
    readonly property color panelFill: Qt.rgba(0.07, 0.11, 0.25, 0.80)
    readonly property color panelFillSoft: Qt.rgba(0.10, 0.15, 0.30, 0.55)
    readonly property color sidebarFill: Qt.rgba(0.03, 0.06, 0.16, 0.45)
    readonly property color barFill: Qt.rgba(0.03, 0.07, 0.20, 0.60)
    readonly property color tileFill: Qt.rgba(1, 1, 1, 0.07)
    readonly property color hairline: Qt.rgba(1, 1, 1, 0.14)
    readonly property color textPrimary: white
    readonly property color textSecondary: Qt.rgba(1, 1, 1, 0.62)

    // Radios
    readonly property int radiusWindow: 22
    readonly property int radiusPanel: 26
    readonly property int radiusTile: 18
    readonly property int radiusControl: 10

    // Tipografía
    readonly property string fontFamily: "Inter"
    readonly property string fontMono: "DejaVu Sans Mono"
    readonly property int sizeBody: 16
    readonly property int sizeSmall: 14

    // Movimiento
    readonly property bool reducedMotion: AppConfig.reducedMotion
    function dur(ms) { return reducedMotion ? 0 : ms }
    readonly property int easing: Easing.OutCubic
}
