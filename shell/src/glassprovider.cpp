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
    const QSize full = src.size();
    const int f = qMax(2, r / 3);
    QImage small = src.scaled(qMax(8, full.width() / f), qMax(8, full.height() / f), Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
    QImage tiny = small.scaled(qMax(4, small.width() / 2), qMax(4, small.height() / 2), Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
    small = tiny.scaled(small.size(), Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
    return small.scaled(full, Qt::IgnoreAspectRatio, Qt::SmoothTransformation).convertToFormat(QImage::Format_ARGB32_Premultiplied);
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
    clip.addRoundedRect(QRectF(0, 0, w, h), r, r);
    pa.setClipPath(clip);
    pa.drawImage(QPoint(0, 0), blur, QRect(x, y, w, h));
    pa.end();
    if (size) *size = out.size();
    return out;
}
