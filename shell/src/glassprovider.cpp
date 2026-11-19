#include <QVector>
#include <QPainterPath>
#include <cmath>
#include "glassprovider.h"
#include <cmath>
#include <QFile>
#include <QFileInfo>
#include <QPainter>
#include <QPainterPath>
#include <QStandardPaths>

GlassProvider::GlassProvider() : QQuickImageProvider(QQuickImageProvider::Image) {}

QString GlassProvider::wallpaperPath() {
    QFile f(QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + "/bc/wallpaper");
    if (f.open(QIODevice::ReadOnly)) {
        const QString p = QString::fromUtf8(f.readLine()).trimmed();
        if (!p.isEmpty() && QFileInfo(p).isFile()) return p;
    }
    for (const QString &p : {QStringLiteral("/usr/share/bc/wallpapers/ondas.jpg")})
        if (QFileInfo(p).isFile()) return p;
    return QStringLiteral(":/BCShell/assets/wallpaper-default.png");
}

QImage GlassProvider::blurred(const QImage &src, int r) {
    if (src.isNull()) return src;
    // Reducir mucho y volver a ampliar con filtrado suave dos veces ≈ desenfoque gaussiano, en milisegundos
    // Reducción a mitades sucesivas (cada paso promedia 2×2: elimina el tramado y el ruido), luego ampliación
    // suave en dos pasos: equivale a un desenfoque gaussiano amplio y cuesta milisegundos.
    const QSize full = src.size();
    const int target = qMax(8, full.height() / qMax(2, r / 2));
    QImage small = src.convertToFormat(QImage::Format_RGB32);
    while (small.height() / 2 >= target) small = small.scaled(small.width() / 2, small.height() / 2, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
    // Ampliación de 2 en 2 (cada paso bilineal suaviza el anterior): sin los bloques/pixelado que dejaba ampliar ×8
    // de golpe en las barras laterales y paneles
    QImage up = small;
    while (up.width() * 2 < full.width()) up = up.scaled(up.width() * 2, up.height() * 2, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
    return up.scaled(full, Qt::IgnoreAspectRatio, Qt::SmoothTransformation).convertToFormat(QImage::Format_ARGB32_Premultiplied);
}

QImage GlassProvider::requestImage(const QString &id, QSize *size, const QSize &) {
    const QStringList p = id.section('?', 0, 0).split('_');
    if (p.size() < 7) return {};
    const int x = p[0].toInt(), y = p[1].toInt(), w = qMax(1, p[2].toInt()), h = qMax(1, p[3].toInt());
    const int r = p[4].toInt(), sw = qMax(1, p[5].toInt()), sh = qMax(1, p[6].toInt());
    const QString path = wallpaperPath();
    const QString key = path + QString::number(QFileInfo(path).lastModified().toSecsSinceEpoch()) + QString("@%1x%2").arg(sw).arg(sh);
    QImage blur;
    {
        QMutexLocker l(&m_lock);
        if (!m_blur.contains(key)) {
            if (m_blur.size() >= 4) m_blur.clear();
            QImage src(path);
            if (src.isNull()) src = QImage(":/BCShell/assets/wallpaper-default.png");
            // Igual que sway («fill»): cubrir la pantalla recortando el sobrante centrado
            src = src.scaled(sw, sh, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);
            src = src.copy((src.width() - sw) / 2, (src.height() - sh) / 2, sw, sh);
            m_blur.insert(key, blurred(src, qMax(14, sh / 28)));   // desenfoque amplio (~30 px) como los widgets de macOS: el fondo es solo luz y color
        }
        blur = m_blur.value(key);
    }
    // «full»: el fondo desenfocado entero; Glass lo desplaza mientras la ventana se mueve (sin recortar en cada fotograma)
    QImage out(w, h, QImage::Format_ARGB32_Premultiplied);
    out.fill(Qt::transparent);
    QPainter pa(&out);
    pa.setRenderHint(QPainter::Antialiasing);
    QPainterPath clip;
    if (p.value(8) == "L") {
        // Solo las esquinas izquierdas redondeadas (barras laterales pegadas al borde izquierdo de la ventana)
        clip.addRoundedRect(QRectF(0, 0, w + r, h), r, r);
        clip = clip.intersected([&] { QPainterPath q; q.addRect(0, 0, w, h); return q; }());
    } else clip.addRoundedRect(QRectF(0, 0, w, h), r, r);
    // (sin setClipPath: QPainter no suaviza los bordes de un recorte; la forma se aplica al final con una máscara
    // dibujada con antialias, así las esquinas redondeadas no se ven pixeladas)
    // Si la superficie se sale de la pantalla (ventana más baja que el borde, barra lateral larga…), se prolonga
    // el borde del fondo desenfocado en vez de dejar un hueco transparente con un corte visible.
    const QRect src(x, y, w, h), ok = src & blur.rect();
    if (!ok.isEmpty()) {
        const int ox = ok.left() - x, oy = ok.top() - y;
        pa.drawImage(QPoint(ox, oy), blur, ok);
        if (ok.bottom() < src.bottom())
            pa.drawImage(QRect(ox, ok.bottom() + 1 - y, ok.width(), src.bottom() - ok.bottom()), blur, QRect(ok.left(), ok.bottom(), ok.width(), 1));
        if (ok.top() > src.top())
            pa.drawImage(QRect(ox, 0, ok.width(), oy), blur, QRect(ok.left(), ok.top(), ok.width(), 1));
        if (ok.right() < src.right())
            pa.drawImage(QRect(ok.right() + 1 - x, 0, src.right() - ok.right(), h), out.copy(ok.right() - x, 0, 1, h), QRect(0, 0, 1, h));
        if (ok.left() > src.left())
            pa.drawImage(QRect(0, 0, ox, h), out.copy(ox, 0, 1, h), QRect(0, 0, 1, h));
    }
    pa.end();
    if (p.value(9) != "M") refract(out, r, p.value(8) == "L");   // «M»: ventana en movimiento, recorte rápido sin lente
    {
        QImage mask(w, h, QImage::Format_ARGB32_Premultiplied);
        mask.fill(Qt::transparent);
        QPainter mp(&mask);
        mp.setRenderHint(QPainter::Antialiasing);
        mp.fillPath(clip, Qt::white);
        mp.end();
        QPainter ap(&out);
        ap.setCompositionMode(QPainter::CompositionMode_DestinationIn);
        ap.drawImage(0, 0, mask);
    }
    if (size) *size = out.size();
    return out;
}

// Liquid Glass: cerca del borde el cristal actúa como una lente (curva el fondo hacia dentro, con una leve
// separación de colores) y la luz cae desde arriba a la izquierda (borde brillante en esa cara, más oscuro en la
// opuesta). Solo se recalcula una franja junto al borde, así que es barato también sin GPU.
void GlassProvider::refract(QImage &img, int radius, bool leftOnly) {
    // Liquid Glass portado de liquid-glass-react (rdev, MIT), modo «shader», a C++ sin GPU:
    //  1) mapa de desplazamiento: SDF de rectángulo redondeado en coordenadas normalizadas → el fondo se curva hacia el
    //     centro cerca de los bordes (lente);
    //  2) aberración cromática: el desplazamiento se aplica con escala distinta a R, G y B (70, 63, 56 px);
    //  3) saturación del fondo al 140 %;
    //  4) brillo especular en el filo: anillo de 1,5 px con degradado a 135° (pantalla + superposición).
    const int w = img.width(), h = img.height();
    if (w < 8 || h < 8) return;
    const QImage src = img.copy();
    const int rw = leftOnly ? w + qMax(radius, 1) : w;   // barras laterales: el borde derecho no es filo
    auto smoothStep = [](qreal a, qreal b, qreal t) { t = qBound<qreal>(0, (t - a) / (b - a), 1); return t * t * (3 - 2 * t); };
    auto rrSdf = [](qreal x, qreal y, qreal ww, qreal hh, qreal r) {
        const qreal qx = qAbs(x) - ww + r, qy = qAbs(y) - hh + r;
        return qMin<qreal>(qMax(qx, qy), 0) + std::hypot(qMax<qreal>(qx, 0), qMax<qreal>(qy, 0)) - r;
    };
    // Lente SOLO en el filo, como Liquid Glass de macOS: el interior del cristal coincide exactamente con lo que hay
    // detrás (antes todo el interior se desplazaba y el fondo no casaba con el de fuera). En una franja junto al borde
    // (proporcional al radio) el fondo se curva hacia dentro, más cuanto más cerca del filo.
    const qreal rr0 = qMin<qreal>(radius, qMin(rw, h) / 2.0);
    const qreal band = qBound<qreal>(4, rr0 * 0.5, 12);
    auto sdf = [&](qreal x, qreal y) { return rrSdf(x - rw / 2.0, y - h / 2.0, rw / 2.0, h / 2.0, rr0); };
    QVector<float> mx(w * h, 0.f), my(w * h, 0.f);
    for (int y = 0; y < h; ++y) for (int x = 0; x < w; ++x) {
        const qreal cx = x + 0.5, cy = y + 0.5;
        const qreal d = -sdf(cx, cy);                    // distancia al filo hacia dentro
        if (d <= 0 || d >= band) continue;
        qreal nx = sdf(cx + 1, cy) - sdf(cx - 1, cy), ny = sdf(cx, cy + 1) - sdf(cx, cy - 1);
        const qreal nl = std::hypot(nx, ny); if (nl < 1e-6) continue;
        nx /= nl; ny /= nl;                                 // normal hacia fuera
        const qreal t = 1 - d / band;
        const qreal m = band * 0.5 * t * t;               // se toma el fondo de más adentro: el filo «aumenta»
        mx[y * w + x] = float(-nx * m); my[y * w + x] = float(-ny * m);
    }
    const qreal kR = 1.0, kG = 0.92, kB = 0.84;            // leve separación de colores en el filo
    auto px = [&](qreal x, qreal y) -> QRgb {
        const int ix = qBound(0, int(x), w - 1), iy = qBound(0, int(y), h - 1);
        return reinterpret_cast<const QRgb *>(src.constScanLine(iy))[ix];
    };
    for (int y = 0; y < h; ++y) {
        QRgb *row = reinterpret_cast<QRgb *>(img.scanLine(y));
        for (int x = 0; x < w; ++x) {
            const QRgb o = row[x];
            const int a = qAlpha(o);
            if (a == 0) continue;
            const qreal ddx = mx[y * w + x], ddy = my[y * w + x];
            int r = qRed(px(x + ddx * kR, y + ddy * kR)), g = qGreen(px(x + ddx * kG, y + ddy * kG)), b = qBlue(px(x + ddx * kB, y + ddy * kB));
            // Saturación 140 % (matriz de luminancia de feColorMatrix «saturate»)
            const qreal l = 0.2126 * r + 0.7152 * g + 0.0722 * b;
            r = qBound(0, int(l + (r - l) * 1.4), 255); g = qBound(0, int(l + (g - l) * 1.4), 255); b = qBound(0, int(l + (b - l) * 1.4), 255);
            row[x] = qRgba(r * a / 255, g * a / 255, b * a / 255, a);
        }
    }
    // Brillo especular del filo (anillo de 1,5 px, degradado a 135°): transparente → 0,32 al 33 % → 0,6 al 66 % → transparente
    QPainter pa(&img);
    pa.setRenderHint(QPainter::Antialiasing);
    const qreal rr = qMin<qreal>(radius, qMin(rw, h) / 2.0);
    QPainterPath ring;
    ring.addRoundedRect(QRectF(0.75, 0.75, rw - 1.5, h - 1.5), qMax<qreal>(0, rr - 0.75), qMax<qreal>(0, rr - 0.75));
    QLinearGradient gr(QPointF(0, 0), QPointF(rw, h));   // 135°: de arriba a la izquierda a abajo a la derecha
    gr.setColorAt(0.0, QColor(255, 255, 255, 0));
    gr.setColorAt(0.33, QColor(255, 255, 255, int(255 * 0.12)));
    gr.setColorAt(0.66, QColor(255, 255, 255, int(255 * 0.22)));
    gr.setColorAt(1.0, QColor(255, 255, 255, 0));
    pa.setCompositionMode(QPainter::CompositionMode_Screen);
    pa.setPen(QPen(QBrush(gr), 1.5));
    pa.setBrush(Qt::NoBrush);
    if (leftOnly) pa.setClipRect(0, 0, w, h);
    pa.drawPath(ring);
    // Brillo interior suave arriba (inset 0 1px 3px blanco 0,25)
    QLinearGradient top(QPointF(0, 0), QPointF(0, qMin<qreal>(8, h / 3.0)));
    top.setColorAt(0, QColor(255, 255, 255, 22)); top.setColorAt(1, QColor(255, 255, 255, 0));
    pa.setPen(Qt::NoPen);
    pa.setBrush(top);
    QPainterPath inner; inner.addRoundedRect(QRectF(0, 0, rw, h), rr, rr);
    pa.drawPath(inner);
}
