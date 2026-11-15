pragma Singleton
import QtQuick
import BCShell

QtObject {
    id: t
    // Paleta de marca (assets/branding)
    readonly property color midnight: "#04111F"
    readonly property color white: "#F5F5F7"
    readonly property color silverLight: "#F6F8FC"
    readonly property color silverMid: "#D5DCE8"
    readonly property color silverDark: "#A1ADC0"

    // Acento y semánticos
    readonly property color accent: AppConfig.accent
    readonly property color accentSelected: Qt.darker(AppConfig.accent, 1.18)
    readonly property color close: "#FF5F57"
    readonly property color minimize: "#FEBC2E"
    readonly property color zoom: "#28C840"

    // Superficies (cristal ligero, sin desenfoque por CPU)
    // «Medianoche refinado»: azul noche más apagado y sobrio, con un solo acento
    readonly property color panelFill: lightUi ? Qt.rgba(0.97, 0.97, 0.98, 0.92) : Qt.rgba(0.06, 0.09, 0.16, 0.86)
    readonly property color panelFillSoft: lightUi ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(0.09, 0.12, 0.20, 0.55)
    readonly property color sidebarFill: gg ? sidebarBg : Qt.rgba(0.02, 0.04, 0.09, 0.45)
    readonly property color barFill: Qt.rgba(0.03, 0.05, 0.10, 0.72)
    readonly property color popupFill: gg ? (dark ? Qt.rgba(0.13, 0.13, 0.15, 0.98) : Qt.rgba(0.97, 0.97, 0.98, 0.98)) : Qt.rgba(0.06, 0.09, 0.16, 0.97)    // menús, lanzador, Centro de control
    readonly property color windowFill: gg ? windowBg : Qt.rgba(0.05, 0.08, 0.14, 0.92)   // marco de las apps de BC
    readonly property color widgetFill: Qt.rgba(0.04, 0.07, 0.13, 0.62)
    readonly property color scrim: Qt.rgba(0.01, 0.03, 0.07, 0.55)        // velo bajo los diálogos
    readonly property color tileFill: lightUi ? Qt.rgba(0, 0, 0, 0.05) : Qt.rgba(1, 1, 1, 0.06)
    readonly property color hairline: lightUi ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(1, 1, 1, 0.10)
    readonly property color textPrimary: lightUi ? "#1D1D1F" : white
    readonly property color textSecondary: lightUi ? Qt.rgba(0, 0, 0, 0.55) : Qt.rgba(1, 1, 1, 0.60)

    // Radios
    readonly property int radiusWindow: gg ? windowRadius : 22
    readonly property int radiusPanel: 26
    readonly property int radiusTile: 18
    readonly property int radiusControl: 10

    // Tipografía
    readonly property string fontFamily: gg ? font : "CaskaydiaCove Nerd Font"
    readonly property string fontMono: "CaskaydiaCove Nerd Font Mono"
    readonly property int sizeBody: 16
    readonly property int sizeSmall: 14

    // Movimiento
    readonly property bool reducedMotion: AppConfig.reducedMotion || Settings.reducedMotion
    function dur(ms) { return reducedMotion ? 0 : ms }
    readonly property int easing: Easing.OutCubic

// ============================================================================================
    //  Tokens de diseño de BC OS «Golden Gate» — ÚNICO sitio para afinar medidas, colores,
    //  cristal, tipografía, duraciones y curvas. Los componentes no llevan números mágicos.
    //
    //  Medidas «captura»: tomadas de la captura de referencia (1920×1080, modo oscuro) del creador.
    //  Lo marcado «sin confirmar» es la aproximación más probable sin fuente pública verificable.
    //  Todas las medidas están en píxeles a 1920×1080 y se escalan con `s` (alto de pantalla / 1080).
    // ============================================================================================
    readonly property real s: Math.max(0.7, Math.min(2.0, UiState.sh / 1080))
    function px(v) { return Math.round(v * s) }

    // ---- Aspecto -------------------------------------------------------------------------
    readonly property bool gg: !AppConfig.classic                  // escritorio Golden Gate (no «BC clásico»)
    readonly property bool lightUi: gg && !dark
    readonly property bool dark: Settings.appearance !== "light"
    // Deslizador de Liquid Glass (Ajustes ▸ Aspecto): 0 = ultratransparente · 1 = totalmente tintado
    readonly property real tint: Settings.glassTint

    // ---- Barra de menús (captura) --------------------------------------------------------
    readonly property int barH: 30                 // captura: textos centrados en y≈14–15
    readonly property int barLogoX: 20             // captura: logo de 20 a 34 px
    readonly property int barLogoH: 13
    readonly property int barAppX: 53              // captura: «Ajustes del Sistema» empieza en x=53
    readonly property int barItemGap: 20           // captura: separación entre menús ≈20 px
    readonly property int barTextPx: 13            // captura: alto de mayúscula ≈9 px → 13 px
    readonly property int barRightMargin: 21       // captura: la hora termina a 21 px del borde
    readonly property int barStatusGap: 18         // captura: centros de iconos cada ≈38 px (icono 20 + 18)
    readonly property int barIconPx: 17
    readonly property int barClockGap: 26          // captura: último icono (1727) → hora (1757)
    readonly property int barHoverRadius: 6        // sin confirmar
    readonly property real barFillGG: 0.0           // captura: barra totalmente transparente sobre el fondo

    // ---- Widgets de escritorio (captura) -------------------------------------------------
    readonly property int widgetX: 16              // captura: 16 → 360
    readonly property int widgetY: 47              // captura: primer widget empieza en y=47
    readonly property int widgetW: 344
    readonly property int widgetGap: 19            // captura: 388→407 y 568→588
    readonly property int widgetLargeH: 341        // captura: baterías y recordatorios
    readonly property int widgetMediumH: 161       // captura: widget de app de terceros
    readonly property int widgetRadius: 24         // captura: esquinas muy redondeadas
    readonly property int widgetPad: 18            // captura: textos a 34 px del borde de la pantalla
    readonly property int batteryRowH: 57          // captura: filas en y 75, 132, 189, 247
    readonly property int batteryIconX: 25         // captura: icono centrado en x=41 (16+25)
    readonly property int batteryTextX: 50         // captura: nombre en x=66 (16+50)
    readonly property int widgetTitlePx: 15
    readonly property int widgetBodyPx: 12
    readonly property int widgetSmallPx: 11
    readonly property int reminderCountPx: 29      // captura: «3» grande
    readonly property int reminderRowH: 34         // captura: filas en y 694, 728, 762
    readonly property int reminderCircle: 20

    // ---- Dock (captura) ------------------------------------------------------------------
    readonly property int dockIcon: Settings.dockSize   // captura: iconos de ≈46 px; por defecto 48 (ajustable)
    readonly property int dockPitch: dockIcon + 1       // captura: centros cada 47 px con iconos de 46
    readonly property int dockPadX: 8                   // captura: placa 195 → primer icono 199
    readonly property int dockPadY: 6
    readonly property int dockBottom: 4                 // captura: placa a ≈4 px del borde inferior
    readonly property int dockRadius: 20                // captura: ≈18–20
    readonly property int dockDot: 4                    // captura: punto pequeño bajo la app abierta
    readonly property int dockDotY: 2                   // distancia del punto al borde inferior de la placa
    readonly property int dockSeparatorW: 1
    readonly property int dockSeparatorGap: 10
    readonly property real dockMagnify: Settings.dockMagnify ? 0.75 : 0.0   // sin confirmar (ajuste de macOS «Ampliación» a mitad)
    readonly property int dockMagnifyRange: 150         // sin confirmar: alcance de la ampliación en px

    // ---- Ventanas ------------------------------------------------------------------------
    readonly property int windowRadius: 20         // Golden Gate: radio único ≈20 pt (Tahoe 26, antes 10) — fuentes secundarias
    readonly property int titlebarH: 52            // barra de herramientas unificada (sin confirmar)
    readonly property int trafficSize: 12          // sin confirmar (12 pt en macOS desde Big Sur)
    readonly property int trafficGap: 8
    readonly property int trafficLeft: 14
    readonly property int sidebarW: 220            // barra lateral de borde a borde (Golden Gate)
    readonly property int menuRadius: 12           // sin confirmar
    readonly property int menuItemH: 24
    readonly property int menuPad: 5

    // ---- Tipografía ----------------------------------------------------------------------
    // Inter: fuente abierta (OFL) de métricas próximas a SF Pro. Interletrado ajustado para igualar la captura.
    readonly property string font: "Inter"
    readonly property real letterSpacing: -0.15

    // ---- Colores -------------------------------------------------------------------------
    readonly property color label: dark ? "#FFFFFF" : "#1D1D1F"
    readonly property color labelSecondary: dark ? Qt.rgba(1, 1, 1, 0.62) : Qt.rgba(0, 0, 0, 0.55)
    readonly property color labelTertiary: dark ? Qt.rgba(1, 1, 1, 0.38) : Qt.rgba(0, 0, 0, 0.32)
    readonly property color separator: dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.10)
    readonly property color fill: dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)
    readonly property color fillHover: dark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.10)
    readonly property color selection: AppConfig.accent
    readonly property color barText: "#FFFFFF"    // la barra transparente va sobre el fondo oscuro: texto blanco
    readonly property color windowBg: dark ? "#1E1E22" : "#F5F5F7"
    readonly property color windowBgInactive: dark ? "#26262A" : "#ECECEE"
    readonly property color sidebarBg: dark ? "#232328" : "#E8E8EC"
    readonly property color sidebarBgActive: dark ? "#1B1B20" : "#E1E1E6"  // Golden Gate: barra lateral más oscura en la ventana activa
    readonly property color controlBg: dark ? Qt.rgba(1, 1, 1, 0.08) : "#FFFFFF"
    readonly property color trafficInactive: dark ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(0, 0, 0, 0.18)

    // ---- Liquid Glass --------------------------------------------------------------------
    // Material = fondo desenfocado (capa precalculada del fondo) + tinte + reflejo de borde + sombra.
    readonly property real glassBlur: 48                       // radio de desenfoque del fondo (px a 1080p)
    readonly property color glassTintColor: dark ? Qt.rgba(0.035, 0.04, 0.11, 1) : Qt.rgba(0.97, 0.97, 0.99, 1)
    readonly property real glassTintMin: dark ? 0.12 : 0.30    // ultratransparente
    readonly property real glassTintMax: dark ? 0.86 : 0.92    // totalmente tintado
    readonly property real glassOpacity: glassTintMin + (glassTintMax - glassTintMin) * tint
    readonly property color glassRim: dark ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.75)       // borde fino luminoso (captura)
    readonly property color glassRimLow: dark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(1, 1, 1, 0.30)
    readonly property real glassSpecular: dark ? 0.10 : 0.25   // reflejo superior (refracción uniforme Golden Gate)
    readonly property color shadow: Qt.rgba(0, 0, 0, dark ? 0.45 : 0.18)

    // ---- Movimiento: duraciones (ms) y curvas ---------------------------------------------
    // Ninguna duración de Golden Gate está publicada: todas «sin confirmar», medidas a ojo sobre vídeos.
    readonly property bool reduced: AppConfig.reducedMotion || Settings.reducedMotion
    function d(ms) { return reduced ? 0 : ms }
    readonly property int durMenuOpen: 120
    readonly property int durMenuClose: 90
    readonly property int durPopover: 220
    readonly property int durSheet: 300
    readonly property int durWindowOpen: 240
    readonly property int durWindowClose: 200
    readonly property int durMinimize: 500         // efecto «genio» hacia el Dock
    readonly property int durRestore: 450
    readonly property int durFullscreen: 600
    readonly property int durDockMagnify: 90
    readonly property int durDockHide: 280
    readonly property int durDockBounceUp: 180
    readonly property int durDockBounceDown: 520
    readonly property int dockBounces: 2
    readonly property int durMissionControl: 330
    readonly property int durSpaceSwitch: 420
    readonly property int durSwitcher: 120
    readonly property int durSpotlight: 200
    readonly property int durLaunchpad: 300
    readonly property int durQuickLook: 280
    readonly property int durControlCenter: 240
    readonly property int durNotifyIn: 420
    readonly property int durNotifyOut: 260
    readonly property int durLock: 450
    readonly property int durUnlock: 380
    readonly property int durAppearance: 350
    readonly property int durHover: 120

    // Curvas (Easing de Qt). Springs de AppKit aproximados con OutBack/OutCubic.
    readonly property int easeStandard: Easing.OutCubic
    readonly property int easeEmphasized: Easing.OutQuint
    readonly property int easeIn: Easing.InCubic
    readonly property int easeInOut: Easing.InOutCubic
    readonly property int easeSpring: Easing.OutBack
    readonly property real springOvershoot: 0.9
}
