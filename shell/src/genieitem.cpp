#include "genieitem.h"
#include <QPainter>
#include <QUrl>
#include <QtMath>
#include <cstring>

GenieItem::GenieItem(QQuickItem *parent) : QQuickPaintedItem(parent) {
    setAntialiasing(true);
}

void GenieItem::setSource(const QString &s) {
    if (s == m_source) return;
    m_source = s;
    if (s.isEmpty()) m_img = QImage();
    else {
        const QUrl u(s);
        QImage img(u.isLocalFile() ? u.toLocalFile() : (s.startsWith("qrc:") ? s.mid(3) : s));
        m_img = img.convertToFormat(QImage::Format_ARGB32_Premultiplied);
    }
    update();
    emit changed();
}

static inline qreal clamp01(qreal x) { return x < 0 ? 0 : (x > 1 ? 1 : x); }
static inline qreal smoothstep(qreal t) { t = clamp01(t); return t * t * (3 - 2 * t); }

// Mezcla de dos píxeles premultiplicados con peso w (0..256)
static inline quint32 lerpPx(quint32 a, quint32 b, int w) {
    const quint32 iw = 256 - w;
    const quint32 rb = (((a & 0x00ff00ff) * iw + (b & 0x00ff00ff) * w) >> 8) & 0x00ff00ff;
    const quint32 ag = ((((a >> 8) & 0x00ff00ff) * iw + ((b >> 8) & 0x00ff00ff) * w)) & 0xff00ff00;
    return rb | ag;
}
static inline quint32 scalePx(quint32 a, int w) {   // multiplica por w/256 (cobertura)
    const quint32 rb = (((a & 0x00ff00ff) * w) >> 8) & 0x00ff00ff;
    const quint32 ag = (((a >> 8) & 0x00ff00ff) * w) & 0xff00ff00;
    return rb | ag;
}

QRect GenieItem::box() const {
    if (m_img.isNull() || m_from.width() < 2 || m_from.height() < 2 || m_p >= 0.999) return {};
    const qreal H = m_from.height(), y0 = m_from.y();
    const qreal dist = qMax<qreal>(1, m_target.y() - m_icon / 2 - y0);
    const qreal slide = qPow(clamp01((m_p - 0.3) / 0.7), 1.35), h = H / dist;
    const int top = qMax(0, int(qFloor(y0 + slide * (1 + h) * dist)));
    const int bottom = int(qCeil(qMin(y0 + dist, y0 + (h + slide * (1 + h)) * dist)));
    const int left = int(qFloor(qMin(m_from.x(), m_target.x() - m_icon / 2))) - 2;
    const int right = int(qCeil(qMax(m_from.right(), m_target.x() + m_icon / 2))) + 2;
    return bottom > top && right > left ? QRect(left, top, right - left, bottom - top) : QRect();
}

void GenieItem::paint(QPainter *painter) {
    // Repintado parcial: se limpia la zona sucia (si no, quedaban restos de fotogramas anteriores)
    painter->save();
    painter->setCompositionMode(QPainter::CompositionMode_Source);
    painter->fillRect(painter->hasClipping() ? painter->clipBoundingRect() : QRectF(0, 0, width(), height()), Qt::transparent);
    painter->restore();
    if (m_img.isNull() || m_from.width() < 2 || m_from.height() < 2) return;
    const qreal p = m_p;
    if (p >= 0.999) return;
    const qreal W = m_from.width(), H = m_from.height();
    const qreal y0 = m_from.y();
    const qreal y1 = m_target.y() - m_icon / 2;               // borde superior del icono
    const qreal dist = qMax<qreal>(1, y1 - y0);
    const qreal bend = clamp01(p / 0.42);                     // fase 1: curvatura del embudo
    const qreal slide = qPow(clamp01((p - 0.3) / 0.7), 1.35); // fase 2: deslizamiento
    const qreal h = H / dist;
    const qreal cx0 = m_from.x() + W / 2;
    auto halfW = [&](qreal t) { return W / 2 + (m_icon / 2 - W / 2) * bend * smoothstep(t); };
    auto centerX = [&](qreal t) { return cx0 + (m_target.x() - cx0) * bend * smoothstep(t); };

    // Zona que ocupa el efecto (de la ventana al icono)
    const int top = qMax(0, int(qFloor(y0 + slide * (1 + h) * dist)));
    const int bottom = int(qCeil(qMin(y0 + dist, y0 + (h + slide * (1 + h)) * dist)));
    const int left = int(qFloor(qMin(m_from.x(), m_target.x() - m_icon / 2))) - 2;
    const int right = int(qCeil(qMax(m_from.right(), m_target.x() + m_icon / 2))) + 2;
    if (bottom <= top || right <= left) return;
    const int fw = right - left, fh = bottom - top;
    if (m_frame.width() < fw || m_frame.height() < fh) m_frame = QImage(qMax(fw, m_frame.width()), qMax(fh, m_frame.height()), QImage::Format_ARGB32_Premultiplied);
    // La captura (a menudo ×2 en HiDPI) se reduce UNA vez al tamaño lógico de la ventana: 4 veces menos píxeles que
    // muestrear por fotograma y casi sin promedios (antes hasta 12 muestras por píxel): mucho más fluido por software
    const QSize ls(qMax(1, qRound(W)), qMax(1, qRound(H)));
    if (m_small.size() != ls || m_smallKey != m_img.cacheKey()) {
        m_small = (m_img.size() == ls ? m_img : m_img.scaled(ls, Qt::IgnoreAspectRatio, Qt::SmoothTransformation))
                      .convertToFormat(QImage::Format_ARGB32_Premultiplied);
        m_smallKey = m_img.cacheKey();
    }
    const QImage &src = m_small;
    const int iw = src.width(), ih = src.height();
    const qreal fade = p > 0.96 ? (1 - p) * 25 : 1;
    const int alpha = int(256 * clamp01(fade));

    for (int row = 0; row < fh; ++row) {
        quint32 *dst = reinterpret_cast<quint32 *>(m_frame.scanLine(row));
        std::memset(dst, 0, size_t(fw) * 4);
        const qreal Y = top + row + 0.5;
        const qreal t = (Y - y0) / dist;                         // posición en el embudo
        const qreal v = (t - slide * (1 + h)) / h;               // fila de la ventana (0..1)
        if (v < 0 || v > 1 || t >= 1) continue;
        const qreal hw = halfW(t), cx = centerX(t);
        const qreal xl = cx - hw, xr = cx + hw;
        if (xr - xl < 0.25) continue;
        // Fila de origen con interpolación vertical
        const qreal syf = qBound<qreal>(0, v * ih - 0.5, ih - 1);
        const int sy0 = int(syf), sy1 = qMin(ih - 1, sy0 + 1);
        const int wy = int((syf - sy0) * 256);
        const quint32 *s0 = reinterpret_cast<const quint32 *>(src.constScanLine(sy0));
        const quint32 *s1 = reinterpret_cast<const quint32 *>(src.constScanLine(sy1));
        const int x0 = qMax(int(qFloor(xl)), left), x1 = qMin(int(qCeil(xr)), right - 1);
        const qreal du = iw / (xr - xl);
        const int taps = qBound(1, int(du), 6);
        for (int x = x0; x <= x1; ++x) {
            const qreal pxl = x, pxr = x + 1;
            const qreal cov = qMin(pxr, xr) - qMax(pxl, xl);       // cobertura horizontal del píxel (bordes suaves)
            if (cov <= 0) continue;
            // Si la fila se comprime mucho (embudo estrecho), se promedian varias muestras por píxel: sin punteado
            quint32 c;
            if (taps <= 1) {
                const qreal sxf = qBound<qreal>(0, ((x + 0.5) - xl) * du - 0.5, iw - 1);
                const int sx0 = int(sxf), sx1 = qMin(iw - 1, sx0 + 1);
                const int wx = int((sxf - sx0) * 256);
                c = lerpPx(lerpPx(s0[sx0], s0[sx1], wx), lerpPx(s1[sx0], s1[sx1], wx), wy);
            } else {
                quint32 acc[4] = {0, 0, 0, 0};
                for (int k = 0; k < taps; ++k) {
                    const int sxk = qBound(0, int(((x + (k + 0.5) / taps) - xl) * du), iw - 1);
                    const quint32 q = lerpPx(s0[sxk], s1[sxk], wy);
                    acc[0] += q & 0xff; acc[1] += (q >> 8) & 0xff; acc[2] += (q >> 16) & 0xff; acc[3] += q >> 24;
                }
                c = (acc[0] / taps) | ((acc[1] / taps) << 8) | ((acc[2] / taps) << 16) | ((acc[3] / taps) << 24);
            }
            const int w = int(256 * qMin<qreal>(1, cov)) * alpha / 256;
            if (w < 256) c = scalePx(c, w);
            dst[x - left] = c;
        }
    }
    painter->drawImage(QPointF(left, top), m_frame, QRectF(0, 0, fw, fh));
}
