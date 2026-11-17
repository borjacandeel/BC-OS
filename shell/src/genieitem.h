#pragma once
#include <QImage>
#include <QQuickPaintedItem>
#include <QRectF>
#include <QPointF>

// Efecto genio de macOS dibujado fila a fila en C++ (sin franjas): cada fila de destino toma su fila de la captura
// (interpolando entre dos filas) y la estira entre los bordes curvos del embudo con muestreo bilineal y bordes
// suavizados (cobertura parcial del primer y último píxel). Funciona igual con render por software y con GPU.
class GenieItem : public QQuickPaintedItem {
    Q_OBJECT
    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY changed)
    Q_PROPERTY(QRectF from READ from WRITE setFrom NOTIFY changed)
    Q_PROPERTY(QPointF target READ target WRITE setTarget NOTIFY changed)
    Q_PROPERTY(qreal iconSize READ iconSize WRITE setIconSize NOTIFY changed)
    Q_PROPERTY(qreal progress READ progress WRITE setProgress NOTIFY changed)
public:
    explicit GenieItem(QQuickItem *parent = nullptr);
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
    void paint(QPainter *painter) override;
signals:
    void changed();
private:
    QString m_source;
    QImage m_img;          // captura en ARGB32 premultiplicado
    QImage m_frame;        // fotograma (reutilizado)
    QRectF m_from;
    QPointF m_target;
    qreal m_icon = 48, m_p = 0;
};
