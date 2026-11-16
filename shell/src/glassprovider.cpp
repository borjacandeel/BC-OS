#include "glassprovider.h"
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
    if (size) *size = out.size();
    return out;
}
