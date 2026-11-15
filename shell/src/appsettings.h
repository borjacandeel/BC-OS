#pragma once
#include <QObject>
#include <QSettings>

// Ajustes persistentes del usuario (QSettings): movimiento reducido, idioma...
class AppSettings : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool reducedMotion READ reducedMotion WRITE setReducedMotion NOTIFY changed)
    Q_PROPERTY(QString desktopStyle READ desktopStyle WRITE setDesktopStyle NOTIFY changed)
    Q_PROPERTY(bool widgets READ widgets WRITE setWidgets NOTIFY changed)
    Q_PROPERTY(QString mode READ mode WRITE setMode NOTIFY changed)
    Q_PROPERTY(QString wallpaper READ wallpaper WRITE setWallpaper NOTIFY changed)
    Q_PROPERTY(QString accent READ accent WRITE setAccent NOTIFY changed)
    Q_PROPERTY(bool welcomed READ welcomed WRITE setWelcomed NOTIFY changed)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY changed)
    // Golden Gate: aspecto claro/oscuro, deslizador de Liquid Glass, Dock y widgets (se recargan en caliente
    // en todos los procesos de BC Shell vigilando el archivo de ajustes)
    Q_PROPERTY(QString appearance READ appearance WRITE setAppearance NOTIFY changed)
    Q_PROPERTY(double glassTint READ glassTint WRITE setGlassTint NOTIFY changed)
    Q_PROPERTY(bool dockAutohide READ dockAutohide WRITE setDockAutohide NOTIFY changed)
    Q_PROPERTY(bool dockMagnify READ dockMagnify WRITE setDockMagnify NOTIFY changed)
    Q_PROPERTY(int dockSize READ dockSize WRITE setDockSize NOTIFY changed)
    Q_PROPERTY(QStringList dockApps READ dockApps WRITE setDockApps NOTIFY changed)
    Q_PROPERTY(QString widgetLayout READ widgetLayout WRITE setWidgetLayout NOTIFY changed)
    Q_PROPERTY(bool sounds READ sounds WRITE setSounds NOTIFY changed)
    Q_PROPERTY(QStringList dockRecent READ dockRecent WRITE setDockRecent NOTIFY changed)
    Q_PROPERTY(bool dockShowRecent READ dockShowRecent WRITE setDockShowRecent NOTIFY changed)
public:
    QString appearance() const { return m_appearance; }
    void setAppearance(const QString &a);
    double glassTint() const { return m_glass; }
    void setGlassTint(double v);
    bool dockAutohide() const { return m_dockAutohide; }
    void setDockAutohide(bool on);
    bool dockMagnify() const { return m_dockMagnify; }
    void setDockMagnify(bool on);
    int dockSize() const { return m_dockSize; }
    void setDockSize(int px);
    QStringList dockApps() const { return m_dockApps; }
    void setDockApps(const QStringList &l);
    QString widgetLayout() const { return m_widgetLayout; }
    void setWidgetLayout(const QString &json);
    bool sounds() const { return m_sounds; }
    QStringList dockRecent() const { return m_dockRecent; }
    void setDockRecent(const QStringList &l);
    bool dockShowRecent() const { return m_dockShowRecent; }
    void setDockShowRecent(bool on);
    void setSounds(bool on);
    explicit AppSettings(QObject *parent = nullptr);
    bool reducedMotion() const { return m_reduced; }
    QString desktopStyle() const { return m_style; }
    void setDesktopStyle(const QString &s);
    bool widgets() const { return m_widgets; }
    void setWidgets(bool on);
    QString mode() const { return m_mode; }
    void setMode(const QString &m);
    QString wallpaper() const { return m_wallpaper; }
    void setWallpaper(const QString &p);
    QString accent() const { return m_accent; }
    void setAccent(const QString &c);
    bool welcomed() const { return m_welcomed; }
    void setWelcomed(bool on);
    QString language() const { return m_language; }
    void setReducedMotion(bool on);
    void setLanguage(const QString &l);
    void reload();
signals:
    void changed();

private:
    bool m_reduced = false;
    QString m_language = "es_ES";
    QString m_style = "mac";
    bool m_widgets = true, m_welcomed = false;
    QString m_wallpaper, m_accent = "#2F7BF5";
    QString m_mode;
    QString m_appearance = "dark", m_widgetLayout;
    double m_glass = 0.35;
    bool m_dockAutohide = false, m_dockMagnify = true, m_sounds = true;
    int m_dockSize = 46;
    QStringList m_dockApps, m_dockRecent;
    bool m_dockShowRecent = true;
    class QFileSystemWatcher *m_watch = nullptr;
    void watch();
    template <typename T> void store(const char *key, const T &v);
};
