#include "appsettings.h"
#include <QColor>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QTimer>
#include <QRegularExpression>
#include <QProcess>
#include <QStandardPaths>

AppSettings::AppSettings(QObject *parent) : QObject(parent) {
    reload();
    watch();
}

// Otro proceso (Ajustes del Sistema, el panel) puede cambiar el archivo: se recarga y se avisa en caliente.
void AppSettings::watch() {
    const QString file = QSettings("BC-OS", "bc-shell").fileName();
    QDir().mkpath(QFileInfo(file).absolutePath());
    m_watch = new QFileSystemWatcher(this);
    m_watch->addPath(QFileInfo(file).absolutePath());
    if (QFileInfo::exists(file)) m_watch->addPath(file);
    auto onChange = [this, file] {
        QTimer::singleShot(60, this, [this, file] {
            if (QFileInfo::exists(file) && !m_watch->files().contains(file)) m_watch->addPath(file);
            reload();
            emit changed();
        });
    };
    connect(m_watch, &QFileSystemWatcher::fileChanged, this, onChange);
    connect(m_watch, &QFileSystemWatcher::directoryChanged, this, onChange);
}

template <typename T> void AppSettings::store(const char *key, const T &v) {
    QSettings s("BC-OS", "bc-shell");
    s.setValue(key, v);
    s.sync();
    emit changed();
}

void AppSettings::setAppearance(const QString &a) {
    const QString v = a == "light" ? "light" : (a == "auto" ? "auto" : "dark");
    if (v == m_appearance) return;
    m_appearance = v;
    store("aspecto", v);
    // GTK, Qt y sway siguen el aspecto (bc-appearance aplica gsettings y colores de las barras de título)
    const QString exe = QStandardPaths::findExecutable("bc-appearance");
    if (!exe.isEmpty()) QProcess::startDetached(exe, {v});
}
void AppSettings::setGlassTint(double v) {
    v = qBound(0.0, v, 1.0);
    if (qFuzzyCompare(v + 1, m_glass + 1)) return;
    m_glass = v; store("cristal", v);
}
void AppSettings::setDockAutohide(bool on) { if (on == m_dockAutohide) return; m_dockAutohide = on; store("dockOcultar", on); }
void AppSettings::setDockMagnify(bool on) { if (on == m_dockMagnify) return; m_dockMagnify = on; store("dockAmpliar", on); }
void AppSettings::setDockSize(int px) { px = qBound(32, px, 96); if (px == m_dockSize) return; m_dockSize = px; store("dockTamano", px); }
void AppSettings::setDockApps(const QStringList &l) { if (l == m_dockApps) return; m_dockApps = l; store("dockApps", l); }
void AppSettings::setWidgetLayout(const QString &j) { if (j == m_widgetLayout) return; m_widgetLayout = j; store("widgetsPosicion", j); }
void AppSettings::setSounds(bool on) { if (on == m_sounds) return; m_sounds = on; store("sonidos", on); }

void AppSettings::reload() {
    QSettings s("BC-OS", "bc-shell");
    s.sync();
    m_reduced = s.value("movimientoReducido", false).toBool();
    m_language = s.value("idioma", "es_ES").toString();
    m_style = s.value("estiloEscritorio", "mac").toString();
    if (m_style != "win" && m_style != "minimal") m_style = "mac";
    m_wallpaper = s.value("fondo", "").toString();
    m_accent = s.value("acento", "#2F7BF5").toString();
    m_welcomed = s.value("bienvenida", false).toBool();
    m_widgets = s.value("widgets", true).toBool();
    m_mode = s.value("modo", "").toString();
    m_appearance = s.value("aspecto", "dark").toString();
    m_glass = qBound(0.0, s.value("cristal", 0.35).toDouble(), 1.0);
    m_dockAutohide = s.value("dockOcultar", false).toBool();
    m_dockMagnify = s.value("dockAmpliar", true).toBool();
    m_dockSize = qBound(32, s.value("dockTamano", 46).toInt(), 96);
    m_dockApps = s.value("dockApps").toStringList();
    m_widgetLayout = s.value("widgetsPosicion").toString();
    m_sounds = s.value("sonidos", true).toBool();
}

void AppSettings::setReducedMotion(bool on) {
    reload();   // otro proceso (panel o ajustes) pudo cambiarlo
    if (on == m_reduced) return;
    m_reduced = on;
    QSettings("BC-OS", "bc-shell").setValue("movimientoReducido", on);
    emit changed();
}

void AppSettings::setLanguage(const QString &l) {
    reload();   // otro proceso (panel o ajustes) pudo cambiarlo
    if (l == m_language) return;
    m_language = l;
    QSettings("BC-OS", "bc-shell").setValue("idioma", l);
    emit changed();
}

void AppSettings::setDesktopStyle(const QString &st) {
    reload();   // otro proceso (panel o ajustes) pudo cambiarlo
    const QString s = (st == "win" || st == "minimal") ? st : "mac";
    if (s == m_style) return;
    m_style = s;
    QSettings("BC-OS", "bc-shell").setValue("estiloEscritorio", s);
    // Avisa al panel en caliente (bc-ctl habla con org.bcos.Shell por D-Bus)
    const QString ctl = QStandardPaths::findExecutable("bc-ctl");
    if (!ctl.isEmpty()) QProcess::startDetached(ctl, {"style", s});
    emit changed();
}

static void notifyPanel(const QString &key, const QString &value) {
    const QString ctl = QStandardPaths::findExecutable("bc-ctl");
    if (!ctl.isEmpty()) QProcess::startDetached(ctl, {"option", key, value});
}

void AppSettings::setWidgets(bool on) {
    reload();   // otro proceso (panel o ajustes) pudo cambiarlo
    if (on == m_widgets) return;
    m_widgets = on;
    QSettings("BC-OS", "bc-shell").setValue("widgets", on);
    notifyPanel("widgets", on ? "1" : "0");
    emit changed();
}

void AppSettings::setMode(const QString &m) {
    reload();   // otro proceso (panel o ajustes) pudo cambiarlo
    const QString v = (m == "relax" || m == "focus" || m == "night") ? m : QString();
    if (v == m_mode) return;
    m_mode = v;
    QSettings("BC-OS", "bc-shell").setValue("modo", v);
    notifyPanel("mode", v.isEmpty() ? "-" : v);
    emit changed();
}

void AppSettings::setWallpaper(const QString &p) {
    reload();   // otro proceso (panel o ajustes) pudo cambiarlo
    static const QRegularExpression bad(R"([\"\\\\;,$\n'`])");
    if (!p.isEmpty() && (p.contains(bad) || !QFileInfo(p).isFile())) return;
    if (p == m_wallpaper) return;
    m_wallpaper = p;
    QSettings("BC-OS", "bc-shell").setValue("fondo", p);
    // sway lo lee al arrancar desde ~/.config/bc/wallpaper (bc-wm-mode init); en caliente se avisa al panel
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + "/bc";
    QDir().mkpath(dir);
    QFile f(dir + "/wallpaper");
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) { f.write(p.toUtf8() + "\n"); f.close(); }
    notifyPanel("wallpaper", p.isEmpty() ? "-" : p);
    emit changed();
}

void AppSettings::setAccent(const QString &c) {
    reload();   // otro proceso (panel o ajustes) pudo cambiarlo
    if (c == m_accent || !QColor::isValidColorName(c)) return;
    m_accent = c;
    QSettings("BC-OS", "bc-shell").setValue("acento", c);
    notifyPanel("accent", c);
    emit changed();
}

void AppSettings::setWelcomed(bool on) {
    reload();   // otro proceso (panel o ajustes) pudo cambiarlo
    if (on == m_welcomed) return;
    m_welcomed = on;
    QSettings("BC-OS", "bc-shell").setValue("bienvenida", on);
    emit changed();
}
