import QtQuick
import BCShell

// «Emoji y símbolos» (Ctrl+Súper+Espacio o Edición ▸ Emoji y símbolos): panel con categorías y búsqueda en español.
// Al elegir uno se escribe en la app que tenía el foco (wtype) y queda también en el portapapeles.
Item {
    id: ep
    anchors.fill: parent
    visible: opacity > 0
    opacity: UiState.emojiOpen ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.d(150); easing.type: Easing.OutCubic } }
    readonly property real s: Theme.s
    function px(v) { return Math.round(v * s) }
    property int cat: 0
    property string query: ""
    // [emoji, palabras para buscar]
    readonly property var cats: [
        { name: qsTr("Caras"), icon: "😀", items: [
            ["😀","cara sonrisa feliz"],["😃","sonrisa alegre"],["😄","risa ojos"],["😁","sonrisa dientes"],["😆","carcajada"],["😅","sudor risa"],
            ["🤣","partirse risa"],["😂","lágrimas risa llorar de risa"],["🙂","sonrisa leve"],["🙃","al revés"],["😉","guiño"],["😊","ruborizado feliz"],
            ["😇","ángel"],["🥰","enamorado corazones"],["😍","ojos corazón enamorado"],["🤩","estrellas asombro"],["😘","beso"],["😋","rico delicioso"],
            ["😛","lengua"],["😜","guiño lengua"],["🤪","loco"],["🤗","abrazo"],["🤭","tapar boca"],["🤫","silencio"],["🤔","pensar pensativo"],
            ["😐","neutral serio"],["😑","sin expresión"],["😶","sin boca"],["😏","sonrisa pícara"],["😒","aburrido"],["🙄","ojos en blanco"],
            ["😬","mueca"],["😌","aliviado"],["😔","triste pensativo"],["😪","sueño"],["😴","dormir"],["😷","mascarilla enfermo"],["🤒","fiebre"],
            ["🤢","asco náusea"],["🤮","vomitar"],["🥵","calor"],["🥶","frío"],["😵","mareado"],["🤯","explota cabeza"],["🥳","fiesta celebrar"],
            ["😎","gafas de sol guay"],["🤓","empollón gafas"],["😕","confuso"],["😟","preocupado"],["😮","sorpresa"],["😲","asombro"],["🥺","suplicar"],
            ["😢","llorar triste"],["😭","llorar mucho"],["😱","miedo grito"],["😖","frustrado"],["😞","decepcionado"],["😓","sudor"],["😩","cansado"],
            ["😤","enfadado resoplar"],["😡","enfadado rabia"],["🤬","insultos"],["😈","diablo"],["💀","calavera"],["💩","caca"],["🤡","payaso"],
            ["👻","fantasma"],["👽","extraterrestre"],["🤖","robot"]] },
        { name: qsTr("Gestos"), icon: "👍", items: [
            ["👋","hola adiós mano"],["🤚","mano"],["✋","alto mano"],["🖖","vulcano"],["👌","ok perfecto"],["🤌","italiano"],["✌️","paz victoria"],
            ["🤞","dedos cruzados suerte"],["🤟","te quiero"],["🤘","rock"],["🤙","llámame"],["👈","izquierda"],["👉","derecha"],["👆","arriba"],
            ["👇","abajo"],["☝️","índice"],["👍","bien me gusta pulgar"],["👎","mal no me gusta"],["✊","puño"],["👊","puñetazo"],["👏","aplausos"],
            ["🙌","celebrar manos"],["👐","manos abiertas"],["🤝","acuerdo apretón"],["🙏","por favor gracias rezar"],["💪","fuerza músculo"],
            ["🧠","cerebro"],["👀","ojos mirar"],["👁️","ojo"]] },
        { name: qsTr("Corazones"), icon: "❤️", items: [
            ["❤️","corazón rojo amor"],["🧡","corazón naranja"],["💛","corazón amarillo"],["💚","corazón verde"],["💙","corazón azul"],
            ["💜","corazón morado"],["🖤","corazón negro"],["🤍","corazón blanco"],["🤎","corazón marrón"],["💔","corazón roto"],["❣️","exclamación corazón"],
            ["💕","dos corazones"],["💞","corazones girando"],["💓","latido"],["💗","corazón creciendo"],["💖","corazón brillante"],["💘","flechazo"],
            ["💝","regalo corazón"],["💯","cien perfecto"],["💥","explosión"],["💫","mareo estrella"],["💬","mensaje bocadillo"],["💤","dormir zzz"]] },
        { name: qsTr("Animales"), icon: "🐶", items: [
            ["🐶","perro"],["🐱","gato"],["🐭","ratón"],["🐹","hámster"],["🐰","conejo"],["🦊","zorro"],["🐻","oso"],["🐼","panda"],["🐨","koala"],
            ["🐯","tigre"],["🦁","león"],["🐮","vaca"],["🐷","cerdo"],["🐸","rana"],["🐵","mono"],["🐔","gallina"],["🐧","pingüino"],["🐦","pájaro"],
            ["🦆","pato"],["🦅","águila"],["🦉","búho"],["🐺","lobo"],["🐴","caballo"],["🦄","unicornio"],["🐝","abeja"],["🦋","mariposa"],["🐢","tortuga"],
            ["🐍","serpiente"],["🐙","pulpo"],["🐠","pez"],["🐬","delfín"],["🐳","ballena"],["🦈","tiburón"],["🌲","árbol pino bosque"],["🌳","árbol"],
            ["🌵","cactus"],["🌸","flor cerezo"],["🌹","rosa"],["🌻","girasol"],["🍀","trébol suerte"],["🍁","hoja otoño"],["🌙","luna"],["⭐","estrella"],
            ["☀️","sol"],["⛅","nubes"],["🌧️","lluvia"],["❄️","nieve copo"],["🔥","fuego"],["🌈","arcoíris"],["🌊","ola mar"]] },
        { name: qsTr("Comida"), icon: "🍎", items: [
            ["🍎","manzana"],["🍐","pera"],["🍊","naranja"],["🍋","limón"],["🍌","plátano"],["🍉","sandía"],["🍇","uvas"],["🍓","fresa"],["🍒","cerezas"],
            ["🍑","melocotón"],["🥭","mango"],["🍍","piña"],["🥥","coco"],["🥝","kiwi"],["🍅","tomate"],["🥑","aguacate"],["🥕","zanahoria"],["🌽","maíz"],
            ["🥔","patata"],["🥐","cruasán"],["🍞","pan"],["🧀","queso"],["🥚","huevo"],["🍳","huevo frito"],["🥓","beicon"],["🍔","hamburguesa"],
            ["🍟","patatas fritas"],["🍕","pizza"],["🌭","perrito"],["🥪","sándwich bocadillo"],["🌮","taco"],["🥘","paella"],["🍝","espaguetis pasta"],
            ["🍣","sushi"],["🍦","helado"],["🍩","dónut"],["🍪","galleta"],["🎂","tarta cumpleaños"],["🍫","chocolate"],["🍿","palomitas"],
            ["☕","café"],["🍵","té"],["🍺","cerveza"],["🍷","vino"],["🥂","brindis"],["🧃","zumo"],["💧","agua gota"]] },
        { name: qsTr("Actividad"), icon: "⚽", items: [
            ["⚽","fútbol balón"],["🏀","baloncesto"],["🏈","fútbol americano"],["⚾","béisbol"],["🎾","tenis"],["🏐","voleibol"],["🏓","pimpón"],
            ["🏸","bádminton"],["🥊","boxeo"],["🚴","bici ciclismo"],["🏃","correr"],["🏊","nadar"],["⛷️","esquí"],["🏆","trofeo copa"],["🥇","oro medalla"],
            ["🎮","videojuego mando"],["🕹️","joystick"],["🎲","dado"],["♟️","ajedrez"],["🎯","diana"],["🎨","arte pintura"],["🎬","cine película"],
            ["🎤","micrófono cantar"],["🎧","auriculares música"],["🎸","guitarra"],["🎹","piano"],["🥁","batería tambor"],["🎉","fiesta confeti"],
            ["🎁","regalo"],["🎈","globo"],["🎄","navidad árbol"]] },
        { name: qsTr("Viajes"), icon: "✈️", items: [
            ["🚗","coche"],["🚕","taxi"],["🚌","autobús"],["🚓","policía"],["🚑","ambulancia"],["🚒","bomberos"],["🏍️","moto"],["🚲","bicicleta"],
            ["🚂","tren"],["🚇","metro"],["✈️","avión"],["🚀","cohete"],["🛸","ovni"],["🚢","barco"],["⛵","velero"],["🏠","casa"],["🏢","oficina edificio"],
            ["🏥","hospital"],["🏫","escuela"],["⛪","iglesia"],["🏰","castillo"],["🗽","estatua libertad"],["🗼","torre"],["🌉","puente golden gate"],
            ["🏔️","montaña nieve"],["🏖️","playa"],["🏕️","acampada"],["🌋","volcán"],["🗺️","mapa"],["🧭","brújula"]] },
        { name: qsTr("Objetos"), icon: "💡", items: [
            ["💻","portátil ordenador"],["🖥️","ordenador pantalla"],["⌨️","teclado"],["🖱️","ratón"],["📱","móvil teléfono"],["☎️","teléfono"],
            ["📷","cámara foto"],["🎥","cámara vídeo"],["📺","tele"],["🔋","batería"],["🔌","enchufe"],["💡","bombilla idea"],["🔦","linterna"],
            ["📚","libros"],["📖","libro"],["📝","nota escribir"],["✏️","lápiz"],["📎","clip"],["📌","chincheta"],["📅","calendario"],["📁","carpeta"],
            ["🗑️","papelera"],["🔒","candado cerrado"],["🔓","abierto"],["🔑","llave"],["🔨","martillo"],["🔧","llave inglesa"],["⚙️","engranaje ajustes"],
            ["🧲","imán"],["💰","dinero bolsa"],["💳","tarjeta"],["✉️","sobre correo"],["📦","paquete caja"],["⏰","despertador"],["⌛","reloj de arena"]] },
        { name: qsTr("Símbolos"), icon: "✅", items: [
            ["✅","hecho bien"],["✔️","marca"],["❌","no mal cruz"],["❎","cruz"],["➕","más"],["➖","menos"],["✖️","por"],["➗","dividir"],
            ["❓","pregunta"],["❗","exclamación"],["⚠️","aviso atención"],["🚫","prohibido"],["⛔","sin entrada"],["♻️","reciclar"],["✨","brillo"],
            ["⚡","rayo"],["🔴","rojo círculo"],["🟠","naranja"],["🟡","amarillo"],["🟢","verde"],["🔵","azul"],["🟣","morado"],["⚫","negro"],
            ["⚪","blanco"],["⬆️","flecha arriba"],["⬇️","flecha abajo"],["⬅️","flecha izquierda"],["➡️","flecha derecha"],["🔄","actualizar"],
            ["©️","copyright"],["®️","registrado"],["™️","marca"],["⌘","comando"],["⌥","opción"],["⇧","mayúsculas"],["⌃","control"],["⏎","intro"],
            ["€","euro"],["£","libra"],["$","dólar"],["°","grado"],["±","más menos"],["≠","distinto"],["≈","aproximado"],["∞","infinito"],
            ["→","flecha"],["←","flecha"],["•","punto"],["…","puntos suspensivos"],["«","comillas"],["»","comillas"],["¿","interrogación"],["¡","exclamación"]] }
    ]
    readonly property var shown: {
        const q = query.trim().toLowerCase()
        if (q === "") return cats[cat].items
        const out = []
        for (const c of cats) for (const it of c.items) if (it[1].indexOf(q) >= 0) out.push(it)
        return out
    }
    Connections { target: UiState; function onEmojiOpenChanged() { if (UiState.emojiOpen) { ep.query = ""; search.text = ""; search.forceActiveFocus() } } }
    Component.onCompleted: if (UiState.emojiOpen) search.forceActiveFocus()   // se crea al abrirse (Lazy)
    function pick(e) {
        UiState.emojiOpen = false
        Quick.copyText(e)
        typer.e = e; typer.restart()
    }
    // Se escribe cuando el panel ya se cerró y el foco volvió a la app
    Timer { id: typer; interval: 180; property string e: ""; onTriggered: Launcher.run("wtype", [e]) }

    MouseArea { anchors.fill: parent; enabled: UiState.emojiOpen; onClicked: UiState.emojiOpen = false }
    Item {
        id: card
        width: px(360); height: px(400)
        anchors.horizontalCenter: parent.horizontalCenter; y: parent.height * 0.22
        scale: UiState.emojiOpen ? 1 : 0.96
        Behavior on scale { NumberAnimation { duration: Theme.d(170); easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent }
        Glass { anchors.fill: parent; radius: px(16); tintBoost: 0.6 }
        Rectangle {
            id: field
            x: px(12); y: px(12); width: parent.width - px(24); height: px(30); radius: px(8)
            color: Theme.dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)
            Text { x: px(10); anchors.verticalCenter: parent.verticalCenter; text: "⌕"; color: Theme.labelSecondary; font.pixelSize: px(15) }
            TextInput {
                id: search
                x: px(30); width: parent.width - px(40); anchors.verticalCenter: parent.verticalCenter
                color: Theme.label; font.family: Theme.font; font.pixelSize: px(13); selectionColor: Theme.textSelection; clip: true
                onTextChanged: ep.query = text
                Keys.onEscapePressed: UiState.emojiOpen = false
                Keys.onReturnPressed: if (ep.shown.length) ep.pick(ep.shown[0][0])
                Text { visible: !search.text; anchors.verticalCenter: parent.verticalCenter; text: qsTr("Buscar emoji")
                       color: Theme.labelSecondary; font: search.font }
            }
        }
        Text { x: px(14); y: px(50); text: ep.query ? qsTr("Resultados") : ep.cats[ep.cat].name; color: Theme.labelSecondary
               font.family: Theme.font; font.pixelSize: px(11); font.weight: Font.DemiBold }
        GridView {
            id: grid
            x: px(8); y: px(68); width: parent.width - px(16); height: parent.height - px(68) - px(44)
            cellWidth: width / 8; cellHeight: cellWidth; clip: true; model: ep.shown
            boundsBehavior: Flickable.DragAndOvershootBounds
            delegate: Item {
                required property var modelData
                width: grid.cellWidth; height: grid.cellHeight
                Rectangle { anchors.fill: parent; anchors.margins: px(2); radius: px(8); color: Theme.accent; opacity: ema.containsMouse ? 0.35 : 0 }
                Text { anchors.centerIn: parent; text: modelData[0]; font.pixelSize: px(24); color: Theme.label }
                MouseArea { id: ema; anchors.fill: parent; hoverEnabled: true; onClicked: ep.pick(modelData[0]) }
            }
        }
        OverlayScroll { flick: grid }
        Text { anchors.centerIn: grid; visible: ep.shown.length === 0; text: qsTr("Sin resultados"); color: Theme.labelSecondary
               font.family: Theme.font; font.pixelSize: px(13) }
        // Categorías abajo, como el visor de macOS
        Row {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: px(8)
            spacing: px(2)
            Repeater {
                model: ep.cats
                Rectangle {
                    required property var modelData
                    required property int index
                    width: px(34); height: px(28); radius: px(7)
                    color: ep.cat === index && !ep.query ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3) : "transparent"
                    Text { anchors.centerIn: parent; text: modelData.icon; font.pixelSize: px(16) }
                    MouseArea { anchors.fill: parent; onClicked: { ep.cat = index; search.text = "" } }
                }
            }
        }
    }
}
