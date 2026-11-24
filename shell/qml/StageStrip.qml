import QtQuick
import BCShell

// Organizador visual (Stage Manager de macOS), con Hyprland: la app activa queda sola en el centro y las demás pasan
// a una tira a la izquierda, con su miniatura girada en perspectiva. Pulsar una miniatura la trae al centro y manda la
// actual a la tira. Las ventanas apartadas van al escritorio especial «stage» (no se cierran ni se minimizan).
Item {
    id: st
    readonly property real s: Theme.s
    function px(v) { return Math.round(v * s) }
    property bool active: UiState.stageManager
    property var shots: ({})        // app → captura (file://…)
    property var order: []          // apps apartadas, la más reciente primero
    property string current: ""     // app en el centro
    property var pending: ({})      // etiqueta de captura → ids de ventanas que hay que apartar tras capturarlas

    function onStage(w) { return w.workspace === "__i3_scratch" && !w.minimized }
    function visibleOf(app) { return Sway.windows.filter(w => w.appId === app && !w.minimized && w.workspace !== "__i3_scratch") }
    function stagedOf(app) { return Sway.windows.filter(w => w.appId === app && st.onStage(w)) }

    // Apartar una app: primero se captura su ventana (para la miniatura) y, cuando la captura está, se mueve
    function stageAway(app) {
        const ws = visibleOf(app)
        if (!app || ws.length === 0) return
        const w = ws[0], tag = "stage-" + app.replace(/[^A-Za-z0-9_.-]/g, "_")
        const p = Object.assign({}, pending); p[tag] = ws.map(x => x.id); pending = p
        Quick.capture(tag, w.decoX + "," + w.decoY + " " + w.rectW + "x" + w.rectH)
        order = [app].concat(order.filter(a => a !== app)).slice(0, 6)
    }
    Connections {
        target: Quick
        function onCaptured(tag, path, ok) {
            const ids = st.pending[tag]
            if (!ids) return
            const p = Object.assign({}, st.pending); delete p[tag]; st.pending = p
            if (ok) { const sh = Object.assign({}, st.shots); sh[tag.substring(6)] = "file://" + path + "?" + Date.now(); st.shots = sh }
            for (const id of ids) Sway.moveToWorkspace(id, "special:stage")
        }
    }
    function bring(app) {
        if (st.current && st.current !== app) stageAway(st.current)
        const ws = stagedOf(app)
        for (const w of ws) Sway.command("[con_id=" + w.id + "] scratchpad show")
        if (ws.length) Sway.focusWindow(ws[ws.length - 1].id)
        order = order.filter(a => a !== app)
        st.current = app
    }

    onActiveChanged: {
        if (active) {
            st.current = Sway.focusedAppId
            const apps = []
            for (const w of Sway.windows) if (!w.minimized && w.workspace !== "__i3_scratch" && w.appId !== st.current && apps.indexOf(w.appId) < 0) apps.push(w.appId)
            for (const a of apps) stageAway(a)
        } else {
            // Al desactivarlo vuelven todas las ventanas apartadas
            for (const w of Sway.windows) if (st.onStage(w)) Sway.command("[con_id=" + w.id + "] scratchpad show")
            order = []; current = ""
        }
    }
    // Abrir o enfocar otra app (Dock, ⌘Tab…) con el organizador activo: la anterior pasa a la tira
    Connections {
        target: Sway
        enabled: st.active
        function onWindowsChanged() {
            const f = Sway.focusedAppId
            if (!f || f === st.current) return
            if (st.current && st.visibleOf(st.current).length) st.stageAway(st.current)
            st.order = st.order.filter(a => a !== f)
            st.current = f
        }
    }

    // ---- Tira de la izquierda -------------------------------------------------------------------
    Column {
        x: px(14); y: px(24); spacing: px(18)
        opacity: st.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.d(220); easing.type: Easing.OutCubic } }
        Repeater {
            model: st.order.filter(a => st.stagedOf(a).length > 0).slice(0, 5)
            delegate: Item {
                id: card
                required property string modelData
                width: px(150); height: px(108)
                // Miniatura en perspectiva (girada hacia el centro de la pantalla, como macOS)
                Rectangle {
                    id: thumb
                    anchors.fill: parent; radius: px(10); color: Theme.fill; clip: true
                    Image { anchors.fill: parent; anchors.margins: px(2); fillMode: Image.PreserveAspectFit; asynchronous: true
                            sourceSize.width: 300; source: st.shots[card.modelData] || "" }
                    transform: Rotation { origin.x: 0; origin.y: thumb.height / 2; axis { x: 0; y: 1; z: 0 }
                                          angle: cma.containsMouse ? 8 : 22
                                          Behavior on angle { NumberAnimation { duration: Theme.d(180); easing.type: Easing.OutCubic } } }
                    scale: cma.containsMouse ? 1.04 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.d(180); easing.type: Easing.OutCubic } }
                }
                Image {
                    readonly property var info: Apps.infoFor(card.modelData)
                    x: -px(6); y: parent.height - px(22); width: px(30); height: width; smooth: true; mipmap: true
                    sourceSize: Qt.size(64, 64); source: info.iconPath ? "file://" + info.iconPath : ""
                }
                MouseArea { id: cma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: st.bring(card.modelData) }
            }
        }
    }
}
