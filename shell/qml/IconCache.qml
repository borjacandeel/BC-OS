pragma Singleton
import QtQuick

// Carga los SVG symbolic del tema BC y sustituye currentColor por el color pedido.
QtObject {
    property var raw: ({})
    property var tinted: ({})

    function svg(name) {
        if (raw[name] === undefined) {
            var x = new XMLHttpRequest()
            x.open("GET", "qrc:/BCShell/icons/" + name + ".svg", false)
            x.send()
            raw[name] = x.responseText
        }
        return raw[name]
    }

    function uri(name, c) {
        var rgb = "rgb(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + ")"
        var key = name + "|" + rgb
        if (tinted[key] === undefined) {
            var s = svg(name)
            tinted[key] = s ? "data:image/svg+xml;utf8," + encodeURIComponent(s.replace(/currentColor/g, rgb)) : ""
        }
        return tinted[key]
    }
}
