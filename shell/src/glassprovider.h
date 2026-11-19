#pragma once
#include <QHash>
#include <QImage>
#include <QMutex>
#include <QQuickImageProvider>

// Liquid Glass sin shaders (funciona con el renderizador por software de Qt en máquinas virtuales):
// el fondo de pantalla se desenfoca UNA vez y cada superficie de cristal pide su recorte ya redondeado.
//   image://glass/<x>_<y>_<w>_<h>_<radio>_<anchoPantalla>_<altoPantalla>_<versión>
// El fondo se toma de ~/.config/bc/wallpaper (o el de BC OS por defecto).
class GlassProvider : public QQuickImageProvider {
public:
    GlassProvider();
    QImage requestImage(const QString &id, QSize *size, const QSize &requested) override;
    static QString wallpaperPath();
    static void refract(QImage &img, int radius, bool leftOnly);
    static QImage blurred(const QImage &src, int radiusPx);   // desenfoque por reducción y ampliación sucesivas
    static QImage blurSmall(const QImage &src, int radiusPx);
    static QImage blurUp(const QImage &small, const QSize &full);
    static QImage loadCover(const QString &path, int sw, int sh);
    static QString diskCachePath(const QString &key);
    // Fondo desenfocado a tamaño de pantalla: de la caché en disco o calculado (y guardado)
    static QImage blurredBackground(const QString &path, int sw, int sh, int radius);

private:
    QMutex m_lock;
    QHash<QString, QImage> m_blur;   // un fondo desenfocado por tamaño de pantalla (multimonitor)
};
