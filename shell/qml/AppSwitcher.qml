import QtQuick
import BCShell

// Selector de aplicaciones (Alt+Tab / Súper+Tab, como ⌘Tab): placa de vidrio centrada con los iconos de las apps
// abiertas. Cada pulsación avanza; al soltar Alt (o Intro, clic, o tras una pausa) se activa la elegida.
Item {
    id: sw
    readonly property real s: Theme.s
    function px(v) { return Math.round(v * s) }
    property var apps: []
    property int index: 0
    // macOS 27: iconos de 104 cada 134 pt, placa muy redondeada de 176 de alto, nombre bajo el elegido
    readonly property real cell: px(134)
    width: Math.max(px(176), apps.length * cell + px(36))
    height: px(176)
    signal done()

    function build() {
        const seen = {}, out = []
        const f = Sway.windows.find(w => w.focused)
        const ordered = f ? [f].concat(Sway.windows.filter(w => w !== f)) : Sway.windows
        for (const w of ordered) {
            if (!w.appId || seen[w.appId]) continue
            seen[w.appId] = true
            const info = Apps.infoFor(w.appId)
            out.push({ appId: w.appId, id: w.id, name: info.name || AppMenus.nameFor(w.appId), icon: info.iconPath || "",
                       kind: ({ "bc-files": "archivos", "bc-settings": "ajustes", "bc-monitor": "monitor", "bc-store": "tienda", "bc-notes": "notas", "bc-calculator": "calculadora", "bc-preview": "vista", "bc-music": "musica" })[w.appId] || "" })
        }
        apps = out
    }
    function step(d) {
        if (!UiState.switcherOpen) { build(); if (apps.length === 0) return; index = apps.length > 1 ? (d > 0 ? 1 : apps.length - 1) : 0; UiState.switcherOpen = true }
        else index = (index + d + apps.length) % apps.length
        commitTimer.restart()
        keys.forceActiveFocus()
    }
    function commit() {
        commitTimer.stop()
        if (!UiState.switcherOpen) return
        const a = apps[index]
        UiState.switcherOpen = false
        if (a) Sway.focusApp(a.appId)
        done()
    }
    Timer { id: commitTimer; interval: 1100; onTriggered: sw.commit() }

    Glass { anchors.fill: parent; radius: px(44); tintBoost: 0.30 }
    Item {
        id: keys
        focus: true
        Keys.onReleased: (e) => { if (e.key === Qt.Key_Alt || e.key === Qt.Key_Meta || e.key === Qt.Key_Super_L) sw.commit() }
        Keys.onReturnPressed: sw.commit()
        Keys.onEscapePressed: { commitTimer.stop(); UiState.switcherOpen = false; sw.done() }
        Keys.onRightPressed: sw.step(1)
        Keys.onLeftPressed: sw.step(-1)
        Keys.onTabPressed: sw.step(1)
    }
    Row {
        x: px(18); anchors.verticalCenter: parent.verticalCenter
        Repeater {
            model: sw.apps
            delegate: Item {
                required property var modelData
                required property int index
                width: sw.cell; height: px(156)
                Rectangle { x: (parent.width - width) / 2; y: px(6); width: px(124); height: px(124); radius: px(26); color: Qt.rgba(0, 0, 0, Theme.dark ? 0.30 : 0.16); visible: index === sw.index }
                AppIcon { visible: modelData.kind !== ""; kind: modelData.kind; size: px(104); anchors.horizontalCenter: parent.horizontalCenter; y: px(16) }
                Image { visible: modelData.kind === ""; width: px(104); height: width; anchors.horizontalCenter: parent.horizontalCenter; y: px(16)
                        source: modelData.icon ? "file://" + modelData.icon : (Quick.iconPath("application-x-executable") !== "" ? "file://" + Quick.iconPath("application-x-executable") : "qrc:/BCShell/apps/text-x-script.svg"); sourceSize: Qt.size(208, 208); smooth: true; mipmap: true }
                Text { visible: index === sw.index; anchors.horizontalCenter: parent.horizontalCenter; y: px(134); width: parent.width - px(4)
                       horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: modelData.name; color: Theme.label
                       font.family: Theme.font; font.pixelSize: px(13); font.weight: Font.DemiBold }
                MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: sw.index = index; onClicked: sw.commit() }
            }
        }
    }
}
