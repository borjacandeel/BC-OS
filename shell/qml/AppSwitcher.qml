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
    readonly property real cell: px(112)
    width: Math.max(px(140), apps.length * cell + px(24))
    height: px(150)
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
                       kind: ({ "bc-files": "archivos", "bc-settings": "ajustes", "bc-monitor": "monitor", "bc-store": "tienda" })[w.appId] || "" })
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

    Glass { anchors.fill: parent; radius: px(26); tintBoost: 0.35 }
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
        x: px(12); anchors.verticalCenter: parent.verticalCenter
        Repeater {
            model: sw.apps
            delegate: Item {
                required property var modelData
                required property int index
                width: sw.cell; height: px(126)
                Rectangle { anchors.fill: parent; anchors.margins: px(4); radius: px(16); color: Qt.rgba(1, 1, 1, 0.16); visible: index === sw.index }
                AppIcon { visible: modelData.kind !== ""; kind: modelData.kind; size: px(84); anchors.horizontalCenter: parent.horizontalCenter; y: px(10) }
                Image { visible: modelData.kind === ""; width: px(84); height: width; anchors.horizontalCenter: parent.horizontalCenter; y: px(10)
                        source: modelData.icon ? "file://" + modelData.icon : "qrc:/BCShell/apps/system-file-manager.svg"; sourceSize: Qt.size(168, 168); smooth: true }
                Text { visible: index === sw.index; anchors.horizontalCenter: parent.horizontalCenter; y: px(100); width: parent.width - px(8)
                       horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: modelData.name; color: Theme.label
                       font.family: Theme.font; font.pixelSize: px(12) }
                MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: sw.index = index; onClicked: sw.commit() }
            }
        }
    }
}
