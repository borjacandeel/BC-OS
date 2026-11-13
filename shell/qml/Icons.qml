pragma Singleton
import QtQuick

// Iconos originales de BC OS sobre rejilla 24x24 (trazos SVG).
QtObject {
    readonly property string wifi: "M2 9a15 15 0 0 1 20 0 M5.5 12.6a10 10 0 0 1 13 0 M8.9 16a5 5 0 0 1 6.2 0 M12 19.4m-.6 0a.6.6 0 1 0 1.2 0a.6.6 0 1 0-1.2 0"
    readonly property string volume: "M3 9.5v5h3.6L12 19V5L6.6 9.5z M15.5 9a4.2 4.2 0 0 1 0 6 M18.3 6.3a8 8 0 0 1 0 11.4"
    readonly property string battery: "M3.5 7h14a2 2 0 0 1 2 2v6a2 2 0 0 1-2 2h-14a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2z M21.5 10.2v3.6 M4 9.5h11v5H4z"
    readonly property string toggles: "M7 4.5h10a3.5 3.5 0 0 1 0 7H7a3.5 3.5 0 0 1 0-7z M17 14.5H7a3.5 3.5 0 0 0 0 7h10a3.5 3.5 0 0 0 0-7z"
    readonly property string bluetooth: "M6.5 7.5l11 9-5.5 4.5V3l5.5 4.5-11 9"
    readonly property string moon: "M20 14.6A8.3 8.3 0 0 1 9.4 4a8.3 8.3 0 1 0 10.6 10.6z"
    readonly property string sun: "M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8z M12 2.5v2.2 M12 19.3v2.2 M2.5 12h2.2 M19.3 12h2.2 M5.3 5.3l1.6 1.6 M17.1 17.1l1.6 1.6 M5.3 18.7l1.6-1.6 M17.1 6.9l1.6-1.6"
    readonly property string bolt: "M13.5 2L4.5 13.5h6.5L10 22l9-12h-6.5z"
    readonly property string chevronRight: "M9 5l7 7-7 7"
    readonly property string chevronLeft: "M15 5l-7 7 7 7"
    readonly property string chevronUp: "M5 15l7-7 7 7"
    readonly property string closeX: "M6 6l12 12 M18 6L6 18"
    readonly property string refresh: "M20.2 12a8.2 8.2 0 0 1-14.3 5.5 M3.8 12a8.2 8.2 0 0 1 14.3-5.5 M18.5 2.8v4.2h-4.2 M5.5 21.2V17h4.2"
    readonly property string home: "M3 11.2L12 3.5l9 7.7 M5.2 9.8V20h5v-6h3.6v6h5V9.8"
    readonly property string desktop: "M3.5 4.5h17v11.5h-17z M8.5 20h7 M12 16v4"
    readonly property string document: "M6 2.5h8l4.5 4.5V21.5H6z M14 2.5V7h4.5 M9 13h6.5 M9 17h6.5"
    readonly property string download: "M12 3v12.5 M6.5 10.5l5.5 5.5 5.5-5.5 M4.5 20.5h15"
    readonly property string image: "M3.5 4.5h17v15h-17z M3.5 16l5-5 4 4 3-3 5 5 M15.5 8.5m-1.3 0a1.3 1.3 0 1 0 2.6 0a1.3 1.3 0 1 0-2.6 0"
    readonly property string music: "M9 18V5.5l11-2V16 M9 18a2.8 2.8 0 1 1-5.6 0A2.8 2.8 0 0 1 9 18z M20 16a2.8 2.8 0 1 1-5.6 0 2.8 2.8 0 0 1 5.6 0z"
    readonly property string trash: "M4 7h16 M9 7V4h6v3 M6 7l1 14h10l1-14 M10 11v6 M14 11v6"
    readonly property string search: "M10.8 4a6.8 6.8 0 1 0 0 13.6 6.8 6.8 0 0 0 0-13.6z M15.8 16l5 5"
    readonly property string gear: "M12 2l1.8 2.6 3.1-.7.7 3.1L20.3 9 19 12l1.3 3-2.7 1.8-.7 3.1-3.1-.7L12 22l-1.8-2.8-3.1.7-.7-3.1L3.7 15 5 12 3.7 9l2.7-1.8.7-3.1 3.1.7z M12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6z"
    readonly property string pulse: "M2 12.5h5l2.5-6 4 12 2.5-6H22"
    readonly property string prompt: "M5 6.5l6 5.5-6 5.5 M13 18h6.5"
    readonly property string bag: "M5 8h14l-1 12.5H6z M8.5 10.5V7a3.5 3.5 0 0 1 7 0v3.5"
    readonly property string compass: "M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18z M15.8 8.2l-2 5.6-5.6 2 2-5.6z"
    readonly property string folder: "M3 7.5a2 2 0 0 1 2-2h4.5l2 2.5H19a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"
}
