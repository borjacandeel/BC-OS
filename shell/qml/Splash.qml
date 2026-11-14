import QtQuick
import BCShell

// Pantalla de carga con el logo al iniciar la sesión del escritorio.
Rectangle {
    id: root
    anchors.fill: parent
    z: 9000
    color: Theme.midnight
    visible: opacity > 0
    opacity: AppConfig.splash ? 1 : 0

    Rectangle {
        anchors.centerIn: parent
        width: Math.max(parent.width, parent.height) * 0.9
        height: width
        radius: width / 2
        gradient: Gradient { GradientStop { position: 0; color: "#0B2347" } GradientStop { position: 1; color: "transparent" } }
        opacity: 0.55
    }
    Brand { id: logo; anchors.centerIn: parent; logoHeight: 64; scale: 0.94 }

    // Se arranca con un temporizador (no ligado a la visibilidad de la capa) y un seguro garantiza
    // que la pantalla de carga nunca se quede encima del escritorio aunque la animación no corra.
    Timer { interval: 60; running: AppConfig.splash; onTriggered: intro.start() }
    Timer { interval: 4500; running: AppConfig.splash; onTriggered: { intro.stop(); root.opacity = 0; UiState.splashing = false } }
    SequentialAnimation {
        id: intro
        onFinished: UiState.splashing = false
        NumberAnimation { target: logo; property: "scale"; to: 1.0; duration: Theme.dur(700); easing.type: Easing.OutCubic }
        PauseAnimation { duration: Theme.dur(350) }
        NumberAnimation { target: root; property: "opacity"; to: 0; duration: Theme.dur(600); easing.type: Easing.InOutCubic }
    }
}
