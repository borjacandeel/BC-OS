pragma Singleton
import QtQuick

// Nombres del tema de iconos BC (Freedesktop) usados por el shell.
QtObject {
    readonly property string wifi: "network-wireless-signal-excellent-symbolic"
    readonly property string volume: "audio-volume-high-symbolic"
    readonly property string battery: "battery-level-100-symbolic"
    readonly property string toggles: "control-center-symbolic"
    readonly property string bluetooth: "bluetooth-active-symbolic"
    readonly property string moon: "weather-clear-night-fill-symbolic"
    readonly property string sun: "weather-clear-symbolic"
    readonly property string bolt: "preferences-system-power-fill-symbolic"
    readonly property string chevronRight: "pan-end-symbolic"
    readonly property string chevronLeft: "pan-start-symbolic"
    readonly property string chevronUp: "pan-up-symbolic"
    readonly property string closeX: "window-close-symbolic"
    readonly property string refresh: "view-refresh-symbolic"
    readonly property string home: "user-home-symbolic"
    readonly property string desktop: "user-desktop-symbolic"
    readonly property string document: "folder-documents-symbolic"
    readonly property string download: "folder-download-symbolic"
    readonly property string image: "folder-pictures-symbolic"
    readonly property string music: "folder-music-symbolic"
    readonly property string trash: "user-trash-symbolic"
    readonly property string search: "edit-find-symbolic"
    readonly property string gear: "preferences-system-symbolic"
    readonly property string reboot: "system-reboot-symbolic"
    readonly property string suspend: "system-suspend-symbolic"
    readonly property string shutdown: "system-shutdown-symbolic"
    readonly property string logout: "system-log-out-symbolic"
    readonly property string lock: "system-lock-screen-symbolic"
    readonly property string user: "system-users-symbolic"
    readonly property string next: "go-next-symbolic"

    function volumeIcon(v, muted) {
        if (muted || v <= 0.001) return "audio-volume-muted-symbolic"
        return v < 0.34 ? "audio-volume-low-symbolic" : (v < 0.67 ? "audio-volume-medium-symbolic" : "audio-volume-high-symbolic")
    }
    function networkIcon(online, wired, bars) {
        if (!online) return "network-wireless-offline-symbolic"
        if (wired) return "network-wired-symbolic"
        return ["network-wireless-signal-none-symbolic", "network-wireless-signal-weak-symbolic",
                "network-wireless-signal-ok-symbolic", "network-wireless-signal-excellent-symbolic"][Math.max(0, Math.min(3, bars))]
    }
    function batteryIcon(percent, charging) {
        const lv = percent >= 90 ? 100 : (percent >= 70 ? 80 : (percent >= 50 ? 60 : (percent >= 30 ? 40 : (percent >= 10 ? 20 : 0))))
        return "battery-level-" + lv + (charging ? "-charging" : "") + "-symbolic"
    }
}
