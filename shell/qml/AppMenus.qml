pragma Singleton
import QtQuick

// Menús globales estilo macOS según la aplicación enfocada (id de app de sway).
QtObject {
    readonly property var names: ({
        "bc-files": qsTr("Archivos"), "bc-monitor": qsTr("Monitor del sistema"), "bc-settings": qsTr("Configuración"),
        "bc-store": qsTr("Tienda"), "foot": qsTr("Terminal"), "Alacritty": qsTr("Terminal"), "com.mitchellh.ghostty": qsTr("Terminal"), "firefox": qsTr("Firefox"), "": qsTr("Escritorio")
    })
    function nameFor(appId) {
        if (names[appId] !== undefined) return names[appId]
        return appId.length > 0 ? appId.charAt(0).toUpperCase() + appId.slice(1) : names[""]
    }

    readonly property var sep: ({ sep: true })

    function windowMenu() {
        return { title: qsTr("Ventana"), items: [
            { label: qsTr("Minimizar"), key: "Súper+M", cmd: "sway:move scratchpad" },
            { label: qsTr("Pantalla completa"), key: "Súper+F", cmd: "sway:fullscreen toggle" },
            { label: qsTr("Flotante / mosaico (esta ventana)"), key: "Súper+Mayús+F", cmd: "sway:floating toggle" },
            sep,
            { label: qsTr("Mostrar escritorio siguiente"), key: "Súper+Tab", cmd: "sway:exec swaymsg workspace next" } ] }
    }
    function viewMenu(extra) {
        const items = extra.concat(extra.length ? [sep] : [])
        items.push({ label: qsTr("Alternar mosaico / flotante"), key: "Súper+Mayús+Espacio", cmd: "bc:tiling" })
        return { title: qsTr("Ver"), items: items }
    }
    function helpMenu() {
        return { title: qsTr("Ayuda"), items: [ { label: qsTr("Acerca de BC OS"), cmd: "bc:about" },
                                                 { label: qsTr("Atajos de teclado"), cmd: "sway:exec bc-terminal -e less /etc/bc/atajos.txt" } ] }
    }

    function menusFor(appId) {
        if (appId === "bc-files") return [
            { title: qsTr("Archivo"), items: [
                { label: qsTr("Nueva carpeta…"), key: "Ctrl+Mayús+N", cmd: "app:newFolder" },
                { label: qsTr("Abrir"), key: "Intro", cmd: "app:open" }, sep,
                { label: qsTr("Cerrar ventana"), key: "Ctrl+W", cmd: "app:close" } ] },
            { title: qsTr("Editar"), items: [
                { label: qsTr("Renombrar…"), key: "F2", cmd: "app:rename" },
                { label: qsTr("Mover a la papelera"), key: "Supr", cmd: "app:trash" }, sep,
                { label: qsTr("Vaciar papelera"), cmd: "app:emptyTrash" } ] },
            viewMenu([
                { label: qsTr("Inicio"), cmd: "app:go-home" }, { label: qsTr("Escritorio"), cmd: "app:go-desktop" },
                { label: qsTr("Documentos"), cmd: "app:go-documents" }, { label: qsTr("Descargas"), cmd: "app:go-downloads" },
                { label: qsTr("Imágenes"), cmd: "app:go-pictures" }, { label: qsTr("Música"), cmd: "app:go-music" },
                { label: qsTr("Papelera"), cmd: "app:go-trash" } ]),
            windowMenu(), helpMenu() ]
        if (appId === "bc-store") return [
            { title: qsTr("Archivo"), items: [
                { label: qsTr("Buscar software"), key: "Ctrl+F", cmd: "app:search" }, sep,
                { label: qsTr("Cerrar ventana"), key: "Ctrl+W", cmd: "app:close" } ] },
            { title: qsTr("Editar"), items: [ { label: qsTr("Actualizar sistema"), cmd: "app:update" } ] },
            viewMenu([ { label: qsTr("Resultados"), cmd: "app:modeSearch" }, { label: qsTr("Instaladas"), cmd: "app:modeInstalled" } ]),
            windowMenu(), helpMenu() ]
        if (appId === "bc-settings") return [
            { title: qsTr("Archivo"), items: [ { label: qsTr("Cerrar ventana"), key: "Ctrl+W", cmd: "app:close" } ] },
            { title: qsTr("Editar"), items: [ { label: qsTr("Sin acciones"), disabled: true } ] },
            viewMenu([ { label: qsTr("Apariencia"), cmd: "app:page0" }, { label: qsTr("Sonido"), cmd: "app:page1" },
                       { label: qsTr("Red"), cmd: "app:page2" }, { label: qsTr("Energía"), cmd: "app:page3" },
                       { label: qsTr("Usuarios"), cmd: "app:page4" }, { label: qsTr("Acerca de"), cmd: "app:page5" } ]),
            windowMenu(), helpMenu() ]
        if (appId === "") return [
            { title: qsTr("Archivo"), items: [ { label: qsTr("Nueva ventana de Archivos"), cmd: "sway:exec bc-shell --app files" },
                                                { label: qsTr("Nueva terminal"), key: "Ctrl+Intro", cmd: "sway:exec bc-terminal" } ] },
            viewMenu([]), helpMenu() ]
        // Aplicaciones externas (Terminal, Firefox…)
        return [
            { title: qsTr("Archivo"), items: [
                { label: qsTr("Nueva ventana"), cmd: "sway:exec " + (appId === "firefox" ? "firefox" : appId) },
                { label: qsTr("Cerrar ventana"), key: "Súper+W", cmd: "sway:kill" } ] },
            { title: qsTr("Editar"), items: [ { label: qsTr("Sin acciones"), disabled: true } ] },
            viewMenu([]), windowMenu(), helpMenu() ]
    }

    readonly property var systemItems: [
        { label: qsTr("Acerca de BC OS"), cmd: "bc:about" }, sep,
        { label: qsTr("Configuración…"), cmd: "sway:exec bc-shell --app settings" }, sep,
        { label: qsTr("Bloquear pantalla"), key: "Ctrl+Súper+Q", cmd: "bc:lock" },
        { label: qsTr("Cerrar sesión…"), cmd: "bc:power:logout" }, sep,
        { label: qsTr("Reiniciar…"), cmd: "bc:power:reboot" },
        { label: qsTr("Apagar…"), cmd: "bc:power:poweroff" }
    ]
}
