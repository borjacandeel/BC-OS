#pragma once
#include <QObject>
#include <QSettings>

// Ajustes persistentes del usuario (QSettings): movimiento reducido, idioma...
class AppSettings : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool reducedMotion READ reducedMotion WRITE setReducedMotion NOTIFY changed)
    // Accesibilidad ▸ Pantalla (macOS): cristal opaco y bordes más marcados
    Q_PROPERTY(bool reduceTransparency READ reduceTransparency WRITE setReduceTransparency NOTIFY changed)
    Q_PROPERTY(bool increaseContrast READ increaseContrast WRITE setIncreaseContrast NOTIFY changed)
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
    // Aspecto efectivo: «Automático» es claro de 8:00 a 20:00 y oscuro el resto (se revisa cada minuto)
    Q_PROPERTY(bool darkNow READ darkNow NOTIFY changed)
    Q_PROPERTY(double glassTint READ glassTint WRITE setGlassTint NOTIFY changed)
    // Como macOS ▸ Aspecto: color de resaltado del texto ("" = automático, el de énfasis) y estilo de widgets/iconos
    Q_PROPERTY(QString highlight READ highlight WRITE setHighlight NOTIFY changed)
    Q_PROPERTY(QString widgetStyle READ widgetStyle WRITE setWidgetStyle NOTIFY changed)
    Q_PROPERTY(bool dockAutohide READ dockAutohide WRITE setDockAutohide NOTIFY changed)
    Q_PROPERTY(bool dockMagnify READ dockMagnify WRITE setDockMagnify NOTIFY changed)
    Q_PROPERTY(int dockSize READ dockSize WRITE setDockSize NOTIFY changed)
    Q_PROPERTY(QStringList dockApps READ dockApps WRITE setDockApps NOTIFY changed)
    Q_PROPERTY(QString widgetLayout READ widgetLayout WRITE setWidgetLayout NOTIFY changed)
    Q_PROPERTY(QString ccModules READ ccModules WRITE setCcModules NOTIFY changed)
    Q_PROPERTY(bool sounds READ sounds WRITE setSounds NOTIFY changed)
    Q_PROPERTY(QStringList dockRecent READ dockRecent WRITE setDockRecent NOTIFY changed)
    Q_PROPERTY(bool dockShowRecent READ dockShowRecent WRITE setDockShowRecent NOTIFY changed)
    Q_PROPERTY(bool clock24 READ clock24 WRITE setClock24 NOTIFY changed)
    // Esquinas activas: [arriba-izq, arriba-der, abajo-izq, abajo-der] → "", mission, desktop, launchpad, notes, lock, notifications
    Q_PROPERTY(QStringList hotCorners READ hotCorners WRITE setHotCorners NOTIFY changed)
public:
    QString appearance() const { return m_appearance; }
    bool darkNow() const;
    void setAppearance(const QString &a);
    double glassTint() const { return m_glass; }
    QString highlight() const { return m_highlight; }
    void setHighlight(const QString &c);
    QString widgetStyle() const { return m_widgetStyle; }
    void setWidgetStyle(const QString &s);
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
    QString ccModules() const { return m_ccModules; }
    void setCcModules(const QString &j);
    void setWidgetLayout(const QString &json);
    bool sounds() const { return m_sounds; }
    QStringList dockRecent() const { return m_dockRecent; }
    void setDockRecent(const QStringList &l);
    bool dockShowRecent() const { return m_dockShowRecent; }
    bool clock24() const { return m_clock24; }
    QStringList hotCorners() const { return m_hot; }
    void setHotCorners(const QStringList &l) { if (l == m_hot || l.size() != 4) return; m_hot = l; store("esquinas", l); }
    void setClock24(bool on) { if (on == m_clock24) return; m_clock24 = on; store("reloj24", on); }
    void setDockShowRecent(bool on);
    void setSounds(bool on);
    explicit AppSettings(QObject *parent = nullptr);
    bool reducedMotion() const { return m_reduced; }
    bool reduceTransparency() const { return m_solid; }
    bool increaseContrast() const { return m_contrast; }
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
    // Pista de la contraseña (botón «?» del login, como macOS): /var/lib/bc-greeter/pista-<usuario>, legible por el login
    Q_INVOKABLE static QString passwordHint(const QString &user);
    Q_INVOKABLE static bool setPasswordHint(const QString &hint);
    void setReduceTransparency(bool on);
    void setIncreaseContrast(bool on);
    void setLanguage(const QString &l);
    void reload();
signals:
    void changed();

private:
    qint64 m_stamp = -1;
    bool m_reloadPending = false;
    void dynamicWallpaper();
    bool m_reduced = false, m_solid = false, m_contrast = false;
    QString m_language = "es_ES";
    QString m_style = "mac";
    bool m_widgets = true, m_welcomed = false;
    QString m_wallpaper, m_accent = "#2F7BF5", m_highlight, m_widgetStyle;
    QString m_mode;
    QString m_appearance = "dark", m_widgetLayout, m_ccModules;
    double m_glass = 0.35;
    bool m_dockAutohide = false, m_dockMagnify = true, m_sounds = true;
    int m_dockSize = 49;
    QStringList m_dockApps, m_dockRecent, m_hot{"", "", "", "notes"};
    bool m_dockShowRecent = true, m_clock24 = false;
    class QFileSystemWatcher *m_watch = nullptr;
    void watch();
    template <typename T> void store(const char *key, const T &v);
};
