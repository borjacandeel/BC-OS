import QtQuick
import BCShell

// Spotlight (Súper+Espacio): barra de vidrio centrada; resultados de apps, cálculos, acciones del sistema y archivos.
Item {
    id: sp
    readonly property real s: Theme.s
    function px(v) { return Math.round(v * s) }
    // macOS 27: barra de 520 pt muy redondeada y, debajo, los resultados en una tarjeta de vidrio aparte
    readonly property int barH: px(64)
    width: px(560)
    height: barH + (results.length ? px(12) + list.contentHeight + px(16) : 0)
    property var results: []
    property int selected: 0
    signal done()

    readonly property var actions: [
        { t: qsTr("Bloquear pantalla"), c: "bc:lock", k: ["bloquear", "lock"] },
        { t: qsTr("Cerrar sesión"), c: "bc:power:logout", k: ["cerrar sesion", "salir", "logout"] },
        { t: qsTr("Reiniciar"), c: "bc:power:reboot", k: ["reiniciar", "reboot"] },
        { t: qsTr("Apagar"), c: "bc:power:poweroff", k: ["apagar", "shutdown"] },
        { t: qsTr("Reposo"), c: "bc:power:suspend", k: ["reposo", "suspender", "dormir"] },
        { t: qsTr("Modo oscuro / claro"), c: "bc:appearance", k: ["oscuro", "claro", "aspecto", "modo"] },
        { t: qsTr("Mission Control"), c: "bc:mission", k: ["mission", "escritorios", "ventanas"] },
        { t: qsTr("Ajustes del Sistema"), c: "sway:exec bc-shell --app settings", k: ["ajustes", "configuracion", "preferencias"] },
        { t: qsTr("Vaciar papelera"), c: "bc:trash:empty", k: ["papelera", "vaciar"] }
    ]
    function norm(x) { const s = x.toLowerCase(); try { return s.normalize("NFD").replace(/[\u0300-\u036f]/g, "") } catch (e) { return s } }
    function setText(t) { field.text = t }
    function reset() { field.text = ""; refresh(); field.forceActiveFocus() }
    function refresh() {
        const q = field.text.trim(), out = []
        if (q.length === 0) { results = []; return }   // (los accesos de la derecha pueden rellenar la lista)
        const calc = Quick.calculate(q)
        if (calc !== "") out.push({ kind: "calc", title: calc, sub: q + " =", icon: "accessories-calculator" })
        for (const a of Apps.search(q).slice(0, 6)) out.push({ kind: "app", title: a.name, sub: qsTr("Aplicación"), iconPath: a.iconPath, id: a.id })
        const nq = norm(q)
        for (const a of actions) if (a.k.some(k => k.indexOf(nq) === 0 || nq.indexOf(k) === 0) || norm(a.t).indexOf(nq) >= 0) out.push({ kind: "action", title: a.t, sub: qsTr("Acción del sistema"), cmd: a.c })
        for (const f of Quick.fileResults) out.push({ kind: "file", title: f.name, sub: f.parent, path: f.path, dir: f.dir })
        // Secciones como en macOS: «Mejor resultado» y luego cada tipo con su encabezado
        const names = { calc: qsTr("Calculadora"), app: qsTr("Aplicaciones"), action: qsTr("Acciones"), file: qsTr("Documentos") }
        const grouped = []
        if (out.length) { grouped.push({ kind: "header", title: qsTr("Mejor resultado") }); grouped.push(out[0]) }
        for (const k of ["calc", "app", "action", "file"]) {
            const g = out.slice(1).filter(r => r.kind === k)
            if (g.length) { grouped.push({ kind: "header", title: names[k] }); for (const r of g) grouped.push(r) }
        }
        results = grouped
        selected = grouped.length > 1 ? 1 : 0
    }
    function stepSel(d) {
        let i = selected + d
        while (i >= 0 && i < results.length && results[i].kind === "header") i += d
        if (i >= 0 && i < results.length) selected = i
    }
    Connections { target: Quick; function onFilesChanged() { if (sp.visible) sp.refresh() } }
    Timer { id: fileDelay; interval: 220; onTriggered: Quick.searchFiles(field.text) }
    function run(r) {
        if (!r) return
        done()
        if (r.kind === "app") { if (!Apps.launch(r.id)) Notifications.push("BC OS", r.title, qsTr("No se pudo abrir la aplicación"), "", 4000) }
        else if (r.kind === "action") UiState.run(r.cmd)
        else if (r.kind === "file") Quick.open(r.path)
        else if (r.kind === "calc") Launcher.run("wl-copy", [r.title])
    }

    Glass { width: parent.width; height: sp.barH; radius: height / 2; tintBoost: 0.55 }
    Glass { visible: sp.results.length > 0; y: sp.barH + px(12); width: parent.width; height: list.contentHeight + px(16); radius: px(28); tintBoost: 0.4 }
    Icon { x: px(24); y: (sp.barH - height) / 2; name: Icons.search; size: px(22); color: Theme.labelSecondary }
    TextInput {
        id: field
        x: px(58); width: parent.width - px(80); height: sp.barH
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.label; selectionColor: Theme.selection
        font.family: Theme.font; font.pixelSize: px(24); font.weight: Font.Normal
        focus: true
        onTextChanged: { sp.refresh(); fileDelay.restart() }
        Keys.onEscapePressed: sp.done()
        Keys.onReturnPressed: sp.run(sp.results[sp.selected])
        Keys.onDownPressed: sp.stepSel(1)
        Keys.onUpPressed: sp.stepSel(-1)
        Text { visible: field.text.length === 0; anchors.verticalCenter: parent.verticalCenter; text: qsTr("Búsqueda Spotlight"); color: Theme.labelTertiary; font: field.font }
    }
    // Accesos de la barra vacía (como en Tahoe/Golden Gate): Aplicaciones, Archivos, Acciones y Portapapeles
    Row {
        visible: field.text.length === 0
        anchors.right: parent.right; anchors.rightMargin: px(14); y: (sp.barH - height) / 2; spacing: px(6)
        Repeater {
            model: [ { i: "view-app-grid-symbolic", t: qsTr("Aplicaciones"), c: "bc:launcher" },
                     { i: "folder-symbolic", t: qsTr("Archivos"), c: "sway:exec bc-shell --app files" },
                     { i: "preferences-system-symbolic", t: qsTr("Acciones"), c: "actions" },
                     { i: "edit-paste-symbolic", t: qsTr("Portapapeles"), c: "bc:clipboard" } ]
            Rectangle {
                required property var modelData
                width: px(34); height: width; radius: width / 2; color: qa.containsMouse ? Theme.fillHover : Theme.fill
                Icon { anchors.centerIn: parent; name: modelData.i; size: px(16); color: Theme.label }
                MouseArea { id: qa; anchors.fill: parent; hoverEnabled: true
                            onClicked: { if (modelData.c === "actions") { sp.results = sp.actions.map(a => ({ kind: "action", title: a.t, sub: qsTr("Acción del sistema"), cmd: a.c })); sp.selected = 0 }
                                         else { sp.done(); UiState.run(modelData.c) } } }
            }
        }
    }
    ListView {
        id: list
        y: sp.barH + px(20); x: px(8); width: parent.width - px(16); height: contentHeight
        interactive: false
        model: sp.results.slice(0, 14)
        delegate: Rectangle {
            required property var modelData
            required property int index
            readonly property bool header: modelData.kind === "header"
            width: list.width; height: header ? px(26) : px(60); radius: px(16)
            Text { visible: parent.header; x: px(12); anchors.bottom: parent.bottom; anchors.bottomMargin: px(3); text: parent.modelData.title
                   color: Theme.labelSecondary; font.family: Theme.font; font.pixelSize: px(11); font.weight: Font.Bold }
            // macOS 27: la fila elegida se aclara (no se pinta en azul); título arriba y detalle gris debajo
            color: index === sp.selected && !header ? (Theme.dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.07)) : "transparent"
            Image { visible: modelData.kind === "app"; x: px(12); anchors.verticalCenter: parent.verticalCenter; width: px(40); height: width
                    source: modelData.iconPath ? "file://" + modelData.iconPath : ""; sourceSize: Qt.size(96, 96); smooth: true; mipmap: true }
            Rectangle { visible: modelData.kind !== "app" && !parent.header; x: px(12); anchors.verticalCenter: parent.verticalCenter; width: px(40); height: width; radius: px(10)
                        color: Theme.dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)
                        Icon { anchors.centerIn: parent; size: px(22); color: Theme.label
                               name: modelData.kind === "file" ? (modelData.dir ? "folder-symbolic" : "document-open-symbolic")
                                   : modelData.kind === "calc" ? "view-grid-symbolic" : "preferences-system-symbolic" } }
            Column {
                visible: !parent.header; x: px(66); anchors.verticalCenter: parent.verticalCenter; width: parent.width - px(80); spacing: px(1)
                Text { width: parent.width; elide: Text.ElideRight; text: modelData.title; color: Theme.label; font.family: Theme.font
                       font.pixelSize: px(modelData.kind === "calc" ? 20 : 16); font.weight: modelData.kind === "calc" ? Font.DemiBold : Font.Normal }
                Text { visible: text !== ""; width: parent.width; elide: Text.ElideRight
                       text: modelData.sub || ""; color: Theme.labelSecondary; font.family: Theme.font; font.pixelSize: px(13) }
            }
            MouseArea { anchors.fill: parent; hoverEnabled: true; enabled: !parent.header; onEntered: sp.selected = index; onClicked: sp.run(modelData) }
        }
    }
}
