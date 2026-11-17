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
    const QImage mid = small.scaled(small.width() * 4, small.height() * 4, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
    return mid.scaled(full, Qt::IgnoreAspectRatio, Qt::SmoothTransformation).convertToFormat(QImage::Format_ARGB32_Premultiplied);
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
            m_blur.insert(key, blurred(src, qMax(12, sh / 22)));
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
    pa.setClipPath(clip);
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
    if (size) *size = out.size();
    return out;
}

// Liquid Glass: cerca del borde el cristal actúa como una lente (curva el fondo hacia dentro, con una leve
// separación de colores) y la luz cae desde arriba a la izquierda (borde brillante en esa cara, más oscuro en la
// opuesta). Solo se recalcula una franja junto al borde, así que es barato también sin GPU.
void GlassProvider::refract(QImage &img, int radius, bool leftOnly) {
    const int w = img.width(), h = img.height();
    if (w < 8 || h < 8) return;
    const qreal band = qBound<qreal>(4, qMin(w, h) * 0.22, 22);
    const QImage src = img.copy();
    const qreal rw = leftOnly ? w + radius : w;          // en barras laterales el borde derecho no cuenta
    const qreal hx = rw / 2.0, hy = h / 2.0, rad = qMin<qreal>(radius, qMin(hx, hy));
    auto sdf = [&](qreal x, qreal y) {                    // distancia con signo a la caja redondeada (negativa dentro)
        const qreal qx = qAbs(x - hx) - (hx - rad), qy = qAbs(y - hy) - (hy - rad);
        const qreal ox = qMax<qreal>(qx, 0), oy = qMax<qreal>(qy, 0);
        return std::sqrt(ox * ox + oy * oy) + qMin<qreal>(qMax(qx, qy), 0) - rad;
    };
    auto sample = [&](qreal x, qreal y, int ch) {
        const int ix = qBound(0, int(x + 0.5), w - 1), iy = qBound(0, int(y + 0.5), h - 1);
        const QRgb c = reinterpret_cast<const QRgb *>(src.constScanLine(iy))[ix];
        return ch == 0 ? qRed(c) : ch == 1 ? qGreen(c) : qBlue(c);
    };
    const qreal lx = -0.6, ly = -0.8;                     // dirección de la luz (arriba a la izquierda)
    for (int y = 0; y < h; ++y) {
        QRgb *row = reinterpret_cast<QRgb *>(img.scanLine(y));
        for (int x = 0; x < w; ++x) {
            const qreal d = -sdf(x + 0.5, y + 0.5);       // distancia al borde hacia dentro
            if (d < 0 || d > band) { if (x > band && x < w - band - 1 && y > band && y < h - band) x = int(w - band - 1); continue; }
            const QRgb o = row[x];
            if (qAlpha(o) == 0) continue;
            // Normal hacia fuera (gradiente de la distancia)
            qreal nx = sdf(x + 1.5, y + 0.5) - sdf(x - 0.5, y + 0.5), ny = sdf(x + 0.5, y + 1.5) - sdf(x + 0.5, y - 0.5);
            const qreal nl = std::sqrt(nx * nx + ny * ny); if (nl < 1e-6) continue; nx /= nl; ny /= nl;
            const qreal t = 1.0 - d / band;               // 1 en el borde, 0 al final de la franja
            const qreal bend = t * t * band * 0.85;       // cuánto se curva el fondo hacia dentro
            const qreal sx = x - nx * bend, sy = y - ny * bend;
            const qreal ca = t * t * 1.6;                 // aberración cromática leve en el filo
            int rr = sample(sx - nx * ca, sy - ny * ca, 0), gg = sample(sx, sy, 1), bb = sample(sx + nx * ca, sy + ny * ca, 2);
            // Luz: realce en la cara iluminada y sombra suave en la opuesta, más intensa en el filo
            const qreal lit = -(nx * lx + ny * ly);       // >0 de cara a la luz
            const qreal k = std::pow(t, 3.0);
            const qreal add = k * (lit > 0 ? 70 * lit : 0) + std::pow(t, 6.0) * 40;
            const qreal mul = 1.0 - k * (lit < 0 ? 0.18 * -lit : 0);
            rr = qBound(0, int(rr * mul + add), 255); gg = qBound(0, int(gg * mul + add), 255); bb = qBound(0, int(bb * mul + add), 255);
            const int a = qAlpha(o);                      // conservar el antialias del recorte (premultiplicado)
            row[x] = qRgba(rr * a / 255, gg * a / 255, bb * a / 255, a);
        }
    }
}
