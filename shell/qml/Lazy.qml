import QtQuick

// Panel emergente que solo existe mientras está abierto (y lo que dura su fundido de salida).
// Motivo (medido con callgrind): al mostrarse, la capa emergente vuelve a generar los nodos de TODO lo que contiene,
// también lo oculto. Con todos los paneles cargados, abrir Spotlight costaba 12–19 ms de sincronización en el
// anfitrión (rectángulos redondeados y glifos del Centro de control, Launchpad, emoji…); así, 3 ms.
// Uso: Lazy { open: UiState.xOpen; sourceComponent: Item { width: pop.width; height: pop.height; … opacity: lz.on … } }
//   «on» pasa a true un instante después de crearse el panel, para que su animación de entrada se vea.
Loader {
    id: lz
    property bool open: false
    property int hold: 480
    property bool on: false
    active: open || keep.running
    Timer { id: keep; interval: lz.hold }
    onOpenChanged: {
        if (open) { keep.stop(); if (status === Loader.Ready) on = true }
        else { on = false; keep.restart() }
    }
    onLoaded: Qt.callLater(() => lz.on = lz.open)
    onActiveChanged: if (!active) on = false
}
