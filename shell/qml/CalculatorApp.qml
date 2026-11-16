import QtQuick
import BCShell

// Calculadora (como la de macOS): ventana compacta sin barra de título visible, pantalla grande alineada a la derecha,
// teclado de botones redondos — funciones en gris claro, números en gris oscuro, operadores en naranja.
// Teclado físico: dígitos, + - * / , Intro (=), Supr/Esc (C), % y Retroceso.
AppWindow {
    id: win
    width: 250
    height: 440
    minimumWidth: 250
    minimumHeight: 440
    titlebarHeight: 30
    title: ""
    property string display: "0"
    property real acc: 0
    property string op: ""
    property bool fresh: true          // el siguiente dígito empieza número nuevo
    property string pendingOp: ""

    function fmt(v) {
        if (!isFinite(v)) return qsTr("Error")
        let s = Number(v.toPrecision(12)).toString()
        if (s.indexOf("e") >= 0) return s.replace(".", ",")
        const neg = s.charAt(0) === "-"; if (neg) s = s.substring(1)
        const parts = s.split(".")
        parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ".")
        return (neg ? "-" : "") + parts.join(",")
    }
    function value() { return parseFloat(display.replace(/\./g, "").replace(",", ".")) || 0 }
    function digit(d) {
        if (fresh) { display = d === "," ? "0," : d; fresh = false; return }
        if (d === "," && display.indexOf(",") >= 0) return
        if (display.replace(/[.,-]/g, "").length >= 9) return
        const raw = display.replace(/\./g, "") + d
        if (d === "," || raw.indexOf(",") >= 0) { display = display + d; return }
        display = fmt(parseFloat(raw))
    }
    function apply(a, b, o) { return o === "+" ? a + b : o === "−" ? a - b : o === "×" ? a * b : o === "÷" ? a / b : b }
    function operator(o) {
        if (op !== "" && !fresh) { acc = apply(acc, value(), op); display = fmt(acc) } else acc = value()
        op = o; fresh = true
    }
    function equals() { if (op === "") return; acc = apply(acc, value(), op); display = fmt(acc); op = ""; fresh = true }
    function clear() { if (!fresh && display !== "0") { display = "0"; fresh = true } else { display = "0"; acc = 0; op = ""; fresh = true } }
    function press(k) {
        if (/^[0-9]$/.test(k) || k === ",") digit(k)
        else if (k === "AC") clear()
        else if (k === "±") display = fmt(-value())
        else if (k === "%") { display = fmt(value() / 100); fresh = true }
        else if (k === "=") equals()
        else operator(k)
    }

    Rectangle { anchors.fill: parent; color: Theme.dark ? "#2A2A2C" : "#E6E6E8" }
    Text {
        id: screen
        anchors.right: parent.right; anchors.rightMargin: 18; y: 18
        width: parent.width - 36; horizontalAlignment: Text.AlignRight
        text: win.display; color: Theme.textPrimary; font.family: Theme.fontFamily; font.weight: Font.Light
        font.pixelSize: 52; fontSizeMode: Text.HorizontalFit; minimumPixelSize: 20; height: 66; verticalAlignment: Text.AlignBottom
    }
    Grid {
        id: keys
        // Teclas redondas que caben a lo ancho y a lo alto (ventana redimensionada o maximizada), centradas
        x: Math.round((parent.width - 4 * k - 3 * 8) / 2); y: 98; columns: 4; spacing: 8
        readonly property real k: Math.floor(Math.min((parent.width - 20 - 3 * 8) / 4, (parent.height - 98 - 10 - 4 * 8) / 5))
        Repeater {
            model: [ { t: win.fresh && win.op === "" || win.display === "0" ? "AC" : "C", k: "AC", s: 1 }, { t: "±", k: "±", s: 1 }, { t: "%", k: "%", s: 1 }, { t: "÷", k: "÷", s: 2 },
                     { t: "7", k: "7" }, { t: "8", k: "8" }, { t: "9", k: "9" }, { t: "×", k: "×", s: 2 },
                     { t: "4", k: "4" }, { t: "5", k: "5" }, { t: "6", k: "6" }, { t: "−", k: "−", s: 2 },
                     { t: "1", k: "1" }, { t: "2", k: "2" }, { t: "3", k: "3" }, { t: "+", k: "+", s: 2 } ]
            Key { required property var modelData; m: modelData }
        }
    }
    // Última fila: «0» ancho (dos columnas), coma e igual
    Row {
        x: keys.x; y: keys.y + 4 * (keys.k + 8); spacing: 8
        Key { m: ({ t: "0", k: "0" }); width: keys.k * 2 + 8; wide: true }
        Key { m: ({ t: ",", k: "," }) }
        Key { m: ({ t: "=", k: "=", s: 2 }) }
    }
    component Key: Rectangle {
                id: key
                property var m
                property bool wide: false
                readonly property var modelData: m
                width: keys.k; height: keys.k; radius: height / 2
                readonly property bool activeOp: modelData.s === 2 && win.op === modelData.k && win.fresh
                color: modelData.s === 2 ? (activeOp ? "white" : (km.pressed ? "#FFC266" : "#FF9F0A"))
                     : modelData.s === 1 ? (km.pressed ? "#8E8E93" : (Theme.dark ? "#5C5C60" : "#C7C7CC"))
                     : (km.pressed ? "#8E8E93" : (Theme.dark ? "#3A3A3C" : "#F5F5F7"))
                Behavior on color { ColorAnimation { duration: Theme.d(120) } }
                Text { x: key.wide ? keys.k / 2 - width / 2 : (key.width - width) / 2; anchors.verticalCenter: parent.verticalCenter; text: modelData.t; font.family: Theme.fontFamily; font.pixelSize: Math.round(keys.k * (modelData.s === 2 ? 0.46 : 0.39))
                       color: parent.activeOp ? "#FF9F0A" : (modelData.s === 2 ? "white" : Theme.textPrimary); font.weight: Font.Medium }
                MouseArea { id: km; anchors.fill: parent; onClicked: win.press(modelData.k) }
    }
    Item {
        anchors.fill: parent; focus: true
        Keys.onPressed: (e) => {
            const map = { "+": "+", "-": "−", "*": "×", "/": "÷", "%": "%", ",": ",", ".": ",", "=": "=" }
            if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) win.press("=")
            else if (e.key === Qt.Key_Escape || e.key === Qt.Key_Delete) win.press("AC")
            else if (e.key === Qt.Key_Backspace) { if (!win.fresh) win.display = win.display.length > 1 ? win.fmt(parseFloat(win.display.replace(/\./g, "").slice(0, -1).replace(",", ".")) || 0) : "0" }
            else if (/^[0-9]$/.test(e.text)) win.press(e.text)
            else if (map[e.text] !== undefined) win.press(map[e.text])
            else return
            e.accepted = true
        }
    }
    Connections { target: AppActions; function onActionInvoked(a) { if (a === "close") win.closeRequested(); else if (a === "copy") Launcher.run("wl-copy", [win.display]) } }
}
