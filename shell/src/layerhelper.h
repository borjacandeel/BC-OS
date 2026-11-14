#pragma once
#include <QObject>
#include <QVariantMap>
#include <QWindow>

// Configura una ventana como superficie wlr-layer-shell (si layer-shell-qt está disponible; si no, no hace nada).
class LayerHelper : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool supported READ supported CONSTANT)
public:
    explicit LayerHelper(QObject *parent = nullptr) : QObject(parent) {}
    bool supported() const;
    // opts: layer ("background"|"bottom"|"top"|"overlay"), anchors (["top","bottom","left","right"]), exclusive (px),
    //       margins ([arriba, derecha, abajo, izquierda]), keyboard ("none"|"ondemand"|"exclusive"), scope, width, height.
    Q_INVOKABLE void configure(QWindow *window, const QVariantMap &opts);
};
