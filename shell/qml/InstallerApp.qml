import QtQuick
import BCShell

// «Instalar BC OS»: asistente de instalación al estilo del instalador de macOS. Pasos a la izquierda, contenido a la
// derecha y botones Atrás / Continuar abajo. Por debajo usa bc-install --auto (Installer, con pkexec).
AppWindow {
    id: win
    sidebarWidth: 220
    canClose: !Installer.running   // no se cierra a mitad de instalación
    width: 820 + 2 * sh
    height: 580 + 2 * sh
    title: qsTr("Instalar BC OS")
    property int page: 0
    readonly property var steps: [qsTr("Introducción"), qsTr("Licencia"), qsTr("Destino"), qsTr("Tu cuenta"), qsTr("Región"),
                                  qsTr("Resumen"), qsTr("Instalación")]
    // Elecciones
    property string disk: ""
    property string diskText: ""
    property bool encrypt: false
    property bool accepted: false
    property string fullName: ""
    property string user: ""
    property bool userEdited: false
    property string pass: ""
    property string pass2: ""
    property string host: "bcos"
    property string keymap: "es"
    property string timezone: "Europe/Madrid"
    property string problem: ""
    readonly property bool installing: page === 6

    readonly property var zones: [ { v: "Europe/Madrid", t: qsTr("Madrid (España peninsular)") }, { v: "Atlantic/Canary", t: qsTr("Canarias") },
        { v: "Europe/Lisbon", t: qsTr("Lisboa") }, { v: "Europe/London", t: qsTr("Londres") }, { v: "Europe/Paris", t: qsTr("París") },
        { v: "Europe/Berlin", t: qsTr("Berlín") }, { v: "America/Mexico_City", t: qsTr("Ciudad de México") }, { v: "America/Bogota", t: qsTr("Bogotá") },
        { v: "America/Lima", t: qsTr("Lima") }, { v: "America/Santiago", t: qsTr("Santiago de Chile") },
        { v: "America/Argentina/Buenos_Aires", t: qsTr("Buenos Aires") }, { v: "America/New_York", t: qsTr("Nueva York") },
        { v: "America/Los_Angeles", t: qsTr("Los Ángeles") }, { v: "UTC", t: "UTC" } ]
    readonly property var keymaps: [ { v: "es", t: qsTr("Español (España)") }, { v: "la-latin1", t: qsTr("Español (Latinoamérica)") },
        { v: "us", t: "English (US)" }, { v: "uk", t: "English (UK)" }, { v: "fr", t: "Français" }, { v: "de", t: "Deutsch" },
        { v: "it", t: "Italiano" }, { v: "pt-latin9", t: "Português" } ]

    // Nombre de cuenta propuesto a partir del nombre completo (como macOS): minúsculas, sin acentos ni espacios
    onFullNameChanged: if (!userEdited) {
        const s = fullName.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase().replace(/[^a-z0-9]+/g, "")
        user = s.replace(/^[0-9]+/, "").slice(0, 31)
    }
    Component.onCompleted: {
        Installer.refreshDisks()
        // --open <n>: abrir en un paso (capturas y pruebas)
        const n = parseInt(AppConfig.openArg); if (n >= 0 && n <= 6) page = n
    }

    function canContinue() {
        if (page === 2) return disk !== ""
        if (page === 3) return fullName.trim() !== "" && /^[a-z_][a-z0-9_-]{0,31}$/.test(user) && user !== "root" && pass.length >= 4 && pass === pass2
                               && /^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$/.test(host)
        return true
    }
    function next() {
        problem = ""
        if (page === 1 && !accepted) { licenseSheet.open = true; return }
        if (page === 5) {
            const why = Installer.start({ disk: disk, user: user, fullName: fullName, password: pass, hostname: host,
                                          keymap: keymap, timezone: timezone, encrypt: encrypt })
            if (why !== "") { problem = why; return }
            pass = ""; pass2 = ""
        }
        if (page < 6) page++
    }

    // ---- Barra lateral: logo y lista de pasos (el actual en negrita con punto azul, como el instalador de macOS) ----
    Item {
        id: side
        y: -win.titlebarHeight; width: win.sidebarWidth; height: parent.height + win.titlebarHeight
        SidebarGlass { anchors.fill: parent; active: win.active; z: -1 }
        Image { x: 24; y: win.titlebarHeight + 18; width: 64; height: 64; sourceSize: Qt.size(128, 128); smooth: true
                source: "file://" + (Quick.iconPath("system-software-install") || Quick.iconPath("bc-store")) }
        Column {
            x: 24; y: win.titlebarHeight + 104; spacing: 12
            Repeater {
                model: win.steps
                Row {
                    required property string modelData
                    required property int index
                    spacing: 10
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 4
                                color: index === win.page ? Theme.accent : (index < win.page ? Theme.textSecondary : "transparent")
                                border.width: index > win.page ? 1 : 0; border.color: Theme.textSecondary }
                    Text { text: modelData; color: index === win.page ? Theme.textPrimary : Theme.textSecondary; font.family: Theme.fontFamily
                           font.pixelSize: 13; font.weight: index === win.page ? Font.Bold : Font.Normal }
                }
            }
        }
    }

    // ---- Contenido ----
    Item {
        id: content
        x: side.width + 28; y: 4; width: parent.width - side.width - 56; height: parent.height - 70
        component Title: Text { width: content.width; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 22; font.weight: Font.Bold; wrapMode: Text.WordWrap }
        component Body: Text { width: content.width; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 13; wrapMode: Text.WordWrap; lineHeight: 1.15 }
        component Field: Rectangle {
            id: fld
            property alias text: inp.text
            property string label
            property string placeholder
            property bool secret: false
            width: content.width; height: 56; color: "transparent"
            Text { text: fld.label; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
            Rectangle {
                y: 20; width: parent.width; height: 32; radius: 8; color: Theme.tileFill
                border.width: inp.activeFocus ? 2 : 1; border.color: inp.activeFocus ? Theme.accent : Theme.hairline
                TextInput {
                    cursorDelegate: TextCursor {}
                    id: inp; x: 10; width: parent.width - 20; anchors.verticalCenter: parent.verticalCenter; color: Theme.textPrimary
                            font.family: Theme.fontFamily; font.pixelSize: 13; clip: true; echoMode: fld.secret ? TextInput.Password : TextInput.Normal
                            selectByMouse: true
                            Text { visible: !parent.text; text: fld.placeholder; color: Theme.textSecondary; font: parent.font } }
            }
        }
        component Choice: Rectangle {
            id: ch
            property string label
            property bool selected: false
            signal picked()
            width: content.width; height: 34; radius: 8
            color: selected ? Theme.accent : (cm.containsMouse ? Theme.tileFill : "transparent")
            Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: ch.label; color: ch.selected ? "white" : Theme.textPrimary
                   font.family: Theme.fontFamily; font.pixelSize: 13 }
            MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; onClicked: ch.picked() }
        }

        // 0 Introducción
        Column {
            visible: win.page === 0; width: parent.width; spacing: 16; y: 40
            Title { text: qsTr("Te damos la bienvenida al instalador de BC OS") }
            Body { text: qsTr("Este asistente instala BC OS en el disco de este equipo en unos minutos. Te pedirá el disco, tu cuenta y la región.\n\nAntes de seguir, guarda una copia de lo que tengas en el disco: la instalación lo borra por completo.") }
            Row { spacing: 10
                  Rectangle { width: 6; height: 6; radius: 3; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                  Body { width: content.width - 20; text: qsTr("Requisitos: un disco de 12 GB o más; arranca en equipos UEFI y en PCs antiguos con BIOS.") } }
        }

        // 1 Licencia
        Column {
            visible: win.page === 1; width: parent.width; spacing: 12; y: 20
            Title { text: qsTr("Licencia") }
            Rectangle {
                width: parent.width; height: content.height - 90; radius: 10; color: Theme.tileFill; clip: true
                Flickable { anchors.fill: parent; anchors.margins: 14; contentHeight: lic.height; clip: true
                    Body { id: lic; width: parent.width; color: Theme.textPrimary
                           text: qsTr("BC OS es software libre. El código propio de BC OS se distribuye bajo la licencia GNU GPL versión 3 o posterior: puedes usarlo, estudiarlo, compartirlo y modificarlo, siempre que mantengas esas mismas libertades para los demás.\n\nIncluye programas de Arch Linux y de otros proyectos, cada uno con su licencia (GPL, LGPL, MIT, BSD, Apache y otras); las encontrarás en /usr/share/licenses. Los iconos MacOS-Like, el tema MacTahoe y el cursor McMojave son GPL-3.0.\n\nBC OS se ofrece TAL CUAL, SIN NINGUNA GARANTÍA, en la medida permitida por la ley. Esta es una versión beta: úsala bajo tu responsabilidad y guarda copia de tus datos.\n\nBC OS no está afiliado a Apple Inc. Golden Gate es el nombre del estilo de escritorio de BC OS.") } }
            }
        }

        // 2 Destino
        Column {
            visible: win.page === 2; width: parent.width; spacing: 12; y: 20
            Title { text: qsTr("Selecciona el disco donde quieres instalar BC OS") }
            Body { text: qsTr("El disco elegido se borrará por completo.") }
            Flow {
                width: parent.width; spacing: 14
                Repeater {
                    model: Installer.disks
                    Rectangle {
                        required property var modelData
                        readonly property bool usable: !modelData.inUse && !modelData.tooSmall
                        readonly property bool sel: win.disk === modelData.path
                        width: 150; height: 150; radius: 14
                        color: sel ? Theme.accentSelected : (dm.containsMouse && usable ? Theme.tileFill : "transparent")
                        border.width: sel ? 2 : 0; border.color: Theme.accent
                        opacity: usable ? 1 : 0.45
                        Image { anchors.horizontalCenter: parent.horizontalCenter; y: 14; width: 64; height: 64; sourceSize: Qt.size(128, 128)
                                source: "file://" + (Quick.iconPath(modelData.removable ? "drive-removable-media-usb" : "drive-harddisk") || Quick.iconPath("drive-harddisk")) }
                        Column { anchors.horizontalCenter: parent.horizontalCenter; y: 86; spacing: 2
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.model; color: Theme.textPrimary; font.family: Theme.fontFamily
                                   font.pixelSize: 13; font.weight: Font.DemiBold; width: 136; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 11
                                   text: modelData.inUse ? qsTr("En uso (arranque)") : (modelData.tooSmall ? qsTr("Demasiado pequeño") : modelData.sizeText + " · " + modelData.name) }
                        }
                        MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; enabled: parent.usable
                                    onClicked: { win.disk = modelData.path; win.diskText = modelData.model + " (" + modelData.sizeText + ")" } }
                    }
                }
            }
            Body { visible: Installer.disks.length === 0; text: qsTr("No se ha encontrado ningún disco. Comprueba que la máquina tiene un disco conectado.") }
            Rectangle {
                width: parent.width; height: 44; radius: 10; color: Theme.tileFill
                Text { x: 12; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 80; elide: Text.ElideRight
                       text: qsTr("Cifrar el disco (como FileVault; pide la contraseña al arrancar)"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13 }
                Rectangle { id: encSw; anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                            width: 38; height: 22; radius: 11; color: win.encrypt ? Theme.accent : (Theme.lightUi ? Qt.rgba(0, 0, 0, 0.12) : Qt.rgba(1, 1, 1, 0.22))
                            Rectangle { y: 2; x: win.encrypt ? parent.width - width - 2 : 2; width: 18; height: 18; radius: 9; color: "white"
                                        Behavior on x { NumberAnimation { duration: Theme.dur(160); easing.type: Theme.easing } } }
                            MouseArea { anchors.fill: parent; onClicked: win.encrypt = !win.encrypt } }
            }
        }

        // 3 Cuenta
        Column {
            visible: win.page === 3; width: parent.width; spacing: 6; y: 20
            Title { text: qsTr("Crea una cuenta de ordenador") }
            Body { text: qsTr("Será la cuenta de administrador de este equipo.") }
            Item { width: 1; height: 4 }
            Field { label: qsTr("Nombre completo"); placeholder: qsTr("Nombre y apellidos"); text: win.fullName; onTextChanged: win.fullName = text }
            Field { label: qsTr("Nombre de la cuenta"); placeholder: "nombre"; text: win.user
                    onTextChanged: if (text !== win.user) { win.userEdited = true; win.user = text } }
            Row { spacing: 12
                Field { width: (content.width - 12) / 2; label: qsTr("Contraseña"); secret: true; text: win.pass; onTextChanged: win.pass = text }
                Field { width: (content.width - 12) / 2; label: qsTr("Verificar"); secret: true; text: win.pass2; onTextChanged: win.pass2 = text } }
            Field { label: qsTr("Nombre del equipo"); placeholder: "bcos"; text: win.host; onTextChanged: win.host = text }
            Body { visible: win.pass2 !== "" && win.pass !== win.pass2; color: "#FF453A"; text: qsTr("Las contraseñas no coinciden.") }
            Body { visible: win.user !== "" && !/^[a-z_][a-z0-9_-]{0,31}$/.test(win.user); color: "#FF453A"
                   text: qsTr("El nombre de la cuenta solo admite minúsculas, números, «-» y «_».") }
        }

        // 4 Región
        Item {
            visible: win.page === 4; width: parent.width; height: content.height
            Title { y: 20; text: qsTr("Región") }
            Column {
                y: 64; width: (parent.width - 20) / 2; spacing: 2
                Text { text: qsTr("Zona horaria"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12; bottomPadding: 6 }
                Flickable { width: parent.width; height: content.height - 110; contentHeight: zc.height; clip: true
                    Column { id: zc; width: parent.width
                        Repeater { model: win.zones
                            Choice { required property var modelData; width: parent.width; label: modelData.t; selected: win.timezone === modelData.v
                                     onPicked: win.timezone = modelData.v } } } }
            }
            Column {
                x: (parent.width + 20) / 2; y: 64; width: (parent.width - 20) / 2; spacing: 2
                Text { text: qsTr("Teclado"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12; bottomPadding: 6 }
                Repeater { model: win.keymaps
                    Choice { required property var modelData; width: parent.width; label: modelData.t; selected: win.keymap === modelData.v
                             onPicked: win.keymap = modelData.v } }
            }
        }

        // 5 Resumen
        Column {
            visible: win.page === 5; width: parent.width; spacing: 10; y: 20
            Title { text: qsTr("Listo para instalar") }
            Body { text: qsTr("Revisa los datos. Al pulsar «Instalar» se borrará el disco elegido.") }
            Rectangle {
                width: parent.width; height: sumCol.height + 8; radius: 12; color: Theme.tileFill
                Column {
                    id: sumCol; y: 4; width: parent.width
                    Repeater {
                        model: [ { k: qsTr("Disco"), v: win.diskText + " · " + win.disk }, { k: qsTr("Cifrado"), v: win.encrypt ? qsTr("Sí") : qsTr("No") },
                                 { k: qsTr("Cuenta"), v: win.fullName + " (" + win.user + ")" }, { k: qsTr("Equipo"), v: win.host },
                                 { k: qsTr("Zona horaria"), v: win.timezone }, { k: qsTr("Teclado"), v: win.keymap } ]
                        Item {
                            required property var modelData
                            required property int index
                            width: sumCol.width; height: 36
                            Rectangle { visible: index > 0; x: 12; width: parent.width - 24; height: 1; color: Theme.hairline }
                            Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: modelData.k; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13 }
                            Text { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; width: parent.width * 0.6
                                   horizontalAlignment: Text.AlignRight; elide: Text.ElideMiddle; text: modelData.v; color: Theme.textSecondary
                                   font.family: Theme.fontFamily; font.pixelSize: 13 }
                        }
                    }
                }
            }
            Body { visible: win.problem !== ""; color: "#FF453A"; text: win.problem }
        }

        // 6 Instalación
        Column {
            visible: win.page === 6; width: parent.width; spacing: 14; y: 60
            Image { anchors.horizontalCenter: parent.horizontalCenter; width: 96; height: 96; sourceSize: Qt.size(192, 192)
                    source: "file://" + (Quick.iconPath("system-software-install") || Quick.iconPath("bc-store")) }
            Title { horizontalAlignment: Text.AlignHCenter
                    text: Installer.finished ? qsTr("BC OS se ha instalado") : (Installer.error !== "" ? qsTr("No se pudo instalar BC OS") : qsTr("Instalando BC OS…")) }
            // Barra de progreso fina como la del instalador de macOS
            Rectangle {
                visible: !Installer.finished && Installer.error === ""
                anchors.horizontalCenter: parent.horizontalCenter; width: Math.min(parent.width, 380); height: 6; radius: 3
                color: Theme.lightUi ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(1, 1, 1, 0.14)
                Rectangle { width: parent.width * Installer.progress / 100; height: parent.height; radius: 3; color: Theme.accent
                            Behavior on width { NumberAnimation { duration: Theme.dur(400); easing.type: Easing.OutCubic } } }
            }
            Body { horizontalAlignment: Text.AlignHCenter
                   text: Installer.finished ? qsTr("Retira el medio de instalación y reinicia el equipo para empezar a usar BC OS.")
                         : (Installer.error !== "" ? Installer.error : (Installer.step !== "" ? Installer.step + "  ·  " : "") + Installer.progress + " %") }
        }
    }

    // ---- Botones (abajo a la derecha, como en macOS) ----
    Row {
        anchors.right: parent.right; anchors.rightMargin: 28; anchors.bottom: parent.bottom; anchors.bottomMargin: 22; spacing: 10
        component Btn: Rectangle {
            id: b
            property string text
            property bool primary: false
            signal clicked()
            width: Math.max(96, bt.implicitWidth + 32); height: 30; radius: 15
            color: !enabled ? Theme.tileFill : (primary ? Theme.accent : Theme.tileFill)
            opacity: enabled ? 1 : 0.5
            Text { id: bt; anchors.centerIn: parent; text: b.text; color: b.primary && b.enabled ? "white" : Theme.textPrimary
                   font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: b.primary ? Font.DemiBold : Font.Normal }
            MouseArea { anchors.fill: parent; enabled: b.enabled; onClicked: b.clicked() }
        }
        Btn { visible: win.page > 0 && !win.installing; text: qsTr("Atrás"); onClicked: { win.problem = ""; win.page-- } }
        Btn { visible: !win.installing; primary: true; enabled: win.canContinue(); text: win.page === 5 ? qsTr("Instalar") : qsTr("Continuar"); onClicked: win.next() }
        Btn { visible: win.installing && Installer.finished; primary: true; text: qsTr("Reiniciar"); onClicked: Installer.reboot() }
        Btn { visible: win.installing && Installer.error !== ""; text: qsTr("Volver"); onClicked: win.page = 5 }
    }

    // ---- Hoja de licencia (baja desde la barra de título, como las hojas de macOS) ----
    Item {
        id: licenseSheet
        property bool open: false
        anchors.fill: parent; z: 60; visible: opacity > 0; opacity: open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.d(Theme.durSheet * 0.6) } }
        Rectangle { anchors.fill: parent; anchors.topMargin: -win.titlebarHeight; radius: Theme.radiusWindow; color: Theme.scrim; opacity: 0.35 }
        MouseArea { anchors.fill: parent }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter; y: licenseSheet.open ? 0 : -20; width: 420; height: 150; radius: 14
            color: Theme.windowFill; border.width: 1; border.color: Theme.hairline
            Behavior on y { NumberAnimation { duration: Theme.dur(Theme.durSheet); easing.type: Easing.OutCubic } }
            Text { x: 20; y: 18; width: parent.width - 40; wrapMode: Text.WordWrap; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13
                   text: qsTr("Para continuar con la instalación, debes aceptar los términos de la licencia.") }
            Row { anchors.right: parent.right; anchors.rightMargin: 16; anchors.bottom: parent.bottom; anchors.bottomMargin: 16; spacing: 10
                Rectangle { width: 96; height: 30; radius: 15; color: Theme.tileFill
                    Text { anchors.centerIn: parent; text: qsTr("No acepto"); color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 13 }
                    MouseArea { anchors.fill: parent; onClicked: licenseSheet.open = false } }
                Rectangle { width: 96; height: 30; radius: 15; color: Theme.accent
                    Text { anchors.centerIn: parent; text: qsTr("Acepto"); color: "white"; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.DemiBold }
                    MouseArea { anchors.fill: parent; onClicked: { win.accepted = true; licenseSheet.open = false; win.page = 2 } } }
            }
        }
    }
}
