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
        if (key != m_key) {
            QImage src(path);
            if (src.isNull()) src = QImage(":/BCShell/assets/wallpaper-default.png");
            // Igual que sway («fill»): cubrir la pantalla recortando el sobrante centrado
            src = src.scaled(sw, sh, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);
            src = src.copy((src.width() - sw) / 2, (src.height() - sh) / 2, sw, sh);
            m_blur = blurred(src, qMax(12, sh / 22));
            m_key = key;
        }
        blur = m_blur;
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
    pa.drawImage(QPoint(0, 0), blur, QRect(x, y, w, h));
    pa.end();
    if (size) *size = out.size();
    return out;
}
