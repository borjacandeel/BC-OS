pragma Singleton
import QtQuick

// Menús globales (Golden Gate) de la app enfocada (app_id de sway):
//   [menú de la app en negrita] Archivo · Edición · Visualización · Ventana · Ayuda
// Elemento: { label, key, cmd, disabled, checked, items (submenú) } o { sep: true }.
// En las apps externas, Edición envía las pulsaciones reales a la ventana (wtype).
QtObject {
    readonly property var names: ({
        "bc-files": qsTr("Archivos"), "bc-monitor": qsTr("Monitor de Actividad"), "bc-settings": qsTr("Ajustes del Sistema"),
        "bc-store": qsTr("Tienda"), "bc-calculator": qsTr("Calculadora"), "bc-notes": qsTr("Notas"), "bc-preview": qsTr("Vista previa"), "bc-reminders": qsTr("Recordatorios"), "bc-calendar": qsTr("Calendario"), "foot": qsTr("Terminal"), "Alacritty": qsTr("Terminal"), "com.mitchellh.ghostty": qsTr("Terminal"),
        "firefox": qsTr("Firefox"), "": qsTr("Archivos")
    })
    function nameFor(appId) {
        if (names[appId] !== undefined) return names[appId]
        const base = appId.split(".").pop()
        return base.length > 0 ? base.charAt(0).toUpperCase() + base.slice(1) : names[""]
    }

    readonly property var sep: ({ sep: true })
    function keys(combo) { return "sway:exec wtype " + combo }

    // Menú de la app (nombre en negrita)
    function appMenu(appId) {
        const n = nameFor(appId)
        const quit = appId === "" ? [] : [sep, { label: qsTr("Salir de %1").arg(n), key: "Ctrl+Q", cmd: appId.indexOf("bc-") === 0 ? "app:close" : "sway:kill" }]
        return [
            { label: qsTr("Acerca de %1").arg(n), cmd: "bc:about" }, sep,
            { label: qsTr("Ajustes…"), key: "Ctrl+,", cmd: appId.indexOf("bc-") === 0 && appId !== "bc-settings" ? "sway:exec bc-shell --app settings" : "app:settings", disabled: appId !== "" && appId.indexOf("bc-") !== 0 },
            sep,
            { label: qsTr("Ocultar %1").arg(n), key: "Súper+H", cmd: "sway:move scratchpad", disabled: appId === "" },
            { label: qsTr("Ocultar otros"), key: "Súper+Alt+H", cmd: "bc:hideOthers", disabled: appId === "" },
            { label: qsTr("Mostrar todo"), cmd: "bc:showAll" }
        ].concat(quit)
    }

    function editMenu(external) {
        if (!external) return { title: qsTr("Edición"), items: [
            { label: qsTr("Deshacer"), key: "Ctrl+Z", disabled: true }, { label: qsTr("Rehacer"), key: "Ctrl+Mayús+Z", disabled: true }, sep,
            { label: qsTr("Cortar"), key: "Ctrl+X", cmd: "app:cut" }, { label: qsTr("Copiar"), key: "Ctrl+C", cmd: "app:copy" },
            { label: qsTr("Pegar"), key: "Ctrl+V", cmd: "app:paste" }, { label: qsTr("Seleccionar todo"), key: "Ctrl+A", cmd: "app:selectAll" }, sep,
            { label: qsTr("Historial del portapapeles"), key: "Súper+V", cmd: "bc:clipboard" } ] }
        return { title: qsTr("Edición"), items: [
            { label: qsTr("Deshacer"), key: "Ctrl+Z", cmd: keys("-M ctrl z -m ctrl") },
            { label: qsTr("Rehacer"), key: "Ctrl+Mayús+Z", cmd: keys("-M ctrl -M shift z -m shift -m ctrl") }, sep,
            { label: qsTr("Cortar"), key: "Ctrl+X", cmd: keys("-M ctrl x -m ctrl") },
            { label: qsTr("Copiar"), key: "Ctrl+C", cmd: keys("-M ctrl c -m ctrl") },
            { label: qsTr("Pegar"), key: "Ctrl+V", cmd: keys("-M ctrl v -m ctrl") },
            { label: qsTr("Seleccionar todo"), key: "Ctrl+A", cmd: keys("-M ctrl a -m ctrl") }, sep,
            { label: qsTr("Buscar"), items: [ { label: qsTr("Buscar…"), key: "Ctrl+F", cmd: keys("-M ctrl f -m ctrl") },
                                              { label: qsTr("Buscar siguiente"), key: "Ctrl+G", cmd: keys("-M ctrl g -m ctrl") } ] },
            { label: qsTr("Historial del portapapeles"), key: "Súper+V", cmd: "bc:clipboard" } ] }
    }
    function windowMenu() {
        return { title: qsTr("Ventana"), items: [
            { label: qsTr("Minimizar"), key: "Súper+M", cmd: "sway:move scratchpad" },
            { label: qsTr("Zoom"), cmd: "sway:fullscreen toggle" },
            { label: qsTr("Mover y redimensionar"), items: [
                { label: qsTr("Mitad izquierda"), cmd: "bc:tile:left" }, { label: qsTr("Mitad derecha"), cmd: "bc:tile:right" },
                { label: qsTr("Rellenar"), cmd: "bc:tile:fill" }, { label: qsTr("Centrar"), cmd: "bc:tile:center" } ] },
            { label: qsTr("Pantalla completa"), key: "Súper+F", cmd: "sway:fullscreen toggle" },
            { label: qsTr("Flotante"), key: "Súper+Mayús+F", cmd: "sway:floating toggle" }, sep,
            { label: qsTr("Mission Control"), key: "Ctrl+↑", cmd: "bc:mission" },
            { label: qsTr("Escritorio siguiente"), key: "Ctrl+→", cmd: "sway:exec swaymsg workspace next" },
            { label: qsTr("Traer todo al frente"), cmd: "bc:showAll" } ] }
    }
    function viewMenu(extra) {
        const items = extra.concat(extra.length ? [sep] : [])
        items.push({ label: qsTr("Mosaico automático"), key: "Súper+Mayús+Espacio", cmd: "bc:tiling", checked: tilingState })
        items.push({ label: qsTr("Pantalla completa"), key: "Súper+F", cmd: "sway:fullscreen toggle" })
        return { title: qsTr("Visualización"), items: items }
    }
    property bool tilingState: false
    function helpMenu() {
        return { title: qsTr("Ayuda"), items: [ { label: qsTr("Ayuda de BC OS"), cmd: "sway:exec xdg-open https://github.com/borjacandeel/BC-OS" },
                                                 { label: qsTr("Atajos de teclado"), cmd: "sway:exec bc-terminal -e less /etc/bc/atajos.txt" } ] }
    }

    function menusFor(appId) {
        if (appId === "bc-files") return [
            { title: qsTr("Archivo"), items: [
                { label: qsTr("Nueva ventana"), key: "Ctrl+N", cmd: "sway:exec bc-shell --app files" },
                { label: qsTr("Nueva carpeta"), key: "Ctrl+Mayús+N", cmd: "app:newFolder" },
                { label: qsTr("Nueva pestaña"), key: "Ctrl+T", cmd: "app:newTab" }, sep,
                { label: qsTr("Abrir"), key: "Ctrl+O", cmd: "app:open" },
                { label: qsTr("Vista rápida"), key: "Espacio", cmd: "app:quickLook" }, sep,
                { label: qsTr("Etiquetas"), items: [
                    { label: qsTr("Rojo"), cmd: "app:tag:rojo" }, { label: qsTr("Naranja"), cmd: "app:tag:naranja" },
                    { label: qsTr("Amarillo"), cmd: "app:tag:amarillo" }, { label: qsTr("Verde"), cmd: "app:tag:verde" },
                    { label: qsTr("Azul"), cmd: "app:tag:azul" }, { label: qsTr("Morado"), cmd: "app:tag:morado" }, sep,
                    { label: qsTr("Quitar etiquetas"), cmd: "app:tag:" } ] }, sep,
                { label: qsTr("Mover a la papelera"), key: "Supr", cmd: "app:trash" },
                { label: qsTr("Cerrar ventana"), key: "Ctrl+W", cmd: "app:close" } ] },
            { title: qsTr("Edición"), items: [
                { label: qsTr("Copiar"), key: "Ctrl+C", cmd: "app:copy" }, { label: qsTr("Pegar"), key: "Ctrl+V", cmd: "app:paste" },
                { label: qsTr("Seleccionar todo"), key: "Ctrl+A", cmd: "app:selectAll" }, sep,
                { label: qsTr("Renombrar"), key: "F2", cmd: "app:rename" }, { label: qsTr("Vaciar papelera…"), cmd: "app:emptyTrash" } ] },
            viewMenu([
                { label: qsTr("Como iconos"), key: "Ctrl+1", cmd: "app:view-icons" }, { label: qsTr("Como lista"), key: "Ctrl+2", cmd: "app:view-list" },
                { label: qsTr("Como columnas"), key: "Ctrl+3", cmd: "app:view-columns" }, { label: qsTr("Como galería"), key: "Ctrl+4", cmd: "app:view-gallery" }, sep,
                { label: qsTr("Mostrar barra de ruta"), cmd: "app:togglePath" }, { label: qsTr("Ocultar barra lateral"), cmd: "app:toggleSidebar" } ]),
            { title: qsTr("Ir"), items: [
                { label: qsTr("Atrás"), key: "Ctrl+[", cmd: "app:back" }, { label: qsTr("Adelante"), key: "Ctrl+]", cmd: "app:forward" },
                { label: qsTr("Carpeta superior"), key: "Ctrl+↑", cmd: "app:up" }, sep,
                { label: qsTr("Inicio"), cmd: "app:go-home" }, { label: qsTr("Escritorio"), cmd: "app:go-desktop" },
                { label: qsTr("Documentos"), cmd: "app:go-documents" }, { label: qsTr("Descargas"), cmd: "app:go-downloads" },
                { label: qsTr("Imágenes"), cmd: "app:go-pictures" }, { label: qsTr("Música"), cmd: "app:go-music" },
                { label: qsTr("Papelera"), cmd: "app:go-trash" } ] },
            windowMenu(), helpMenu() ]
        if (appId === "bc-store") return [
            { title: qsTr("Archivo"), items: [ { label: qsTr("Buscar software"), key: "Ctrl+F", cmd: "app:search" }, sep,
                                                { label: qsTr("Cerrar ventana"), key: "Ctrl+W", cmd: "app:close" } ] },
            editMenu(false),
            viewMenu([ { label: qsTr("Resultados"), cmd: "app:modeSearch" }, { label: qsTr("Instaladas"), cmd: "app:modeInstalled" } ]),
            { title: qsTr("Tienda"), items: [ { label: qsTr("Actualizar sistema"), cmd: "app:update" } ] },
            windowMenu(), helpMenu() ]
        if (appId === "bc-settings") return [
            editMenu(false),
            viewMenu([ { label: qsTr("Aspecto"), cmd: "app:page0" }, { label: qsTr("Sonido"), cmd: "app:page1" },
                       { label: qsTr("Red"), cmd: "app:page2" }, { label: qsTr("Energía"), cmd: "app:page3" },
                       { label: qsTr("Usuarios"), cmd: "app:page4" }, { label: qsTr("General"), cmd: "app:page5" } ]),
            windowMenu(), helpMenu() ]
        if (appId === "bc-monitor") return [
            { title: qsTr("Archivo"), items: [ { label: qsTr("Cerrar ventana"), key: "Ctrl+W", cmd: "app:close" } ] },
            editMenu(false), viewMenu([]), windowMenu(), helpMenu() ]
        if (appId === "") return [
            { title: qsTr("Archivo"), items: [ { label: qsTr("Nueva ventana de Archivos"), key: "Ctrl+N", cmd: "sway:exec bc-shell --app files" },
                                                { label: qsTr("Nueva carpeta en el escritorio"), cmd: "bc:desktopNewFolder" },
                                                { label: qsTr("Nueva terminal"), key: "Ctrl+Intro", cmd: "sway:exec bc-terminal" } ] },
            editMenu(false),
            viewMenu([ { label: qsTr("Ordenar escritorio por nombre"), cmd: "bc:desktopSort" } ]),
            { title: qsTr("Ir"), items: [
                { label: qsTr("Inicio"), cmd: "sway:exec bc-shell --app files" },
                { label: qsTr("Aplicaciones"), cmd: "bc:launcher" } ] },
            windowMenu(), helpMenu() ]
        // Aplicaciones externas (Terminal, Firefox…)
        return [
            { title: qsTr("Archivo"), items: [
                { label: qsTr("Nueva ventana"), key: "Ctrl+N", cmd: keys("-M ctrl n -m ctrl") },
                { label: qsTr("Nueva pestaña"), key: "Ctrl+T", cmd: keys("-M ctrl t -m ctrl") }, sep,
                { label: qsTr("Cerrar ventana"), key: "Ctrl+Q", cmd: "sway:kill" } ] },
            editMenu(true), viewMenu([]), windowMenu(), helpMenu() ]
    }

    // Menú del logo BC (equivalente al menú Apple)
    readonly property var systemItems: [
        { label: qsTr("Acerca de este equipo"), cmd: "bc:about" }, sep,
        { label: qsTr("Ajustes del Sistema…"), cmd: "sway:exec bc-shell --app settings" },
        { label: qsTr("Tienda…"), cmd: "sway:exec bc-shell --app store" }, sep,
        { label: qsTr("Forzar salida…"), key: "Ctrl+Alt+Esc", cmd: "sway:kill" }, sep,
        { label: qsTr("Reposo"), cmd: "bc:power:suspend" },
        { label: qsTr("Reiniciar…"), cmd: "bc:power:reboot" },
        { label: qsTr("Apagar…"), cmd: "bc:power:poweroff" }, sep,
        { label: qsTr("Bloquear pantalla"), key: "Ctrl+Súper+Q", cmd: "bc:lock" },
        { label: qsTr("Cerrar sesión…"), key: "Ctrl+Mayús+Q", cmd: "bc:power:logout" }
    ]
}
