#pragma once
#include <QImage>
#include <QPointF>
#include <QQuickItem>
#include <QRectF>

// Efecto genio en la GPU (BC Rendering Engine): la captura de la ventana es una textura y el embudo es una malla de
// tiras horizontales cuyos vértices se recalculan en cada fotograma (unos 200 vértices). Antes (GenieItem) la CPU
// pintaba cada píxel del embudo con QPainter y subía la imagen entera a la GPU en cada fotograma: en gráficas
// integradas no llegaba a 60 fps. Con renderizado por software se sigue usando GenieItem.
class GenieMesh : public QQuickItem {
    Q_OBJECT
    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY changed)
    Q_PROPERTY(QRectF from READ from WRITE setFrom NOTIFY changed)
    Q_PROPERTY(QPointF target READ target WRITE setTarget NOTIFY changed)
    Q_PROPERTY(qreal iconSize READ iconSize WRITE setIconSize NOTIFY changed)
    Q_PROPERTY(qreal progress READ progress WRITE setProgress NOTIFY changed)
public:
    explicit GenieMesh(QQuickItem *parent = nullptr);
    QString source() const { return m_source; }
    void setSource(const QString &s);
    QRectF from() const { return m_from; }
    void setFrom(const QRectF &r) { m_from = r; update(); emit changed(); }
    QPointF target() const { return m_target; }
    void setTarget(const QPointF &p) { m_target = p; update(); emit changed(); }
    qreal iconSize() const { return m_icon; }
    void setIconSize(qreal s) { m_icon = s; update(); emit changed(); }
    qreal progress() const { return m_p; }
    void setProgress(qreal p) { m_p = p; update(); emit changed(); }
    // Vértices del embudo para un progreso dado (x, y, u, v por vértice; tira de 2·(filas+1)). Público para pruebas.
    static QVector<float> strip(const QRectF &from, const QPointF &target, qreal icon, qreal p, int rows);
signals:
    void changed();
protected:
    QSGNode *updatePaintNode(QSGNode *old, UpdatePaintNodeData *) override;
private:
    QString m_source;
    QImage m_img;
    bool m_newImage = false;
    QRectF m_from;
    QPointF m_target;
    qreal m_icon = 48, m_p = 0;
};
