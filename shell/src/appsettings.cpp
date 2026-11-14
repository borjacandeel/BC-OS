#include "appsettings.h"
#include <QColor>
#include <QDir>
#include <QFile>
#include <QProcess>
#include <QStandardPaths>

AppSettings::AppSettings(QObject *parent) : QObject(parent) {
    QSettings s("BC-OS", "bc-shell");
    m_reduced = s.value("movimientoReducido", false).toBool();
    m_language = s.value("idioma", "es_ES").toString();
    m_style = s.value("estiloEscritorio", "mac").toString();
    if (m_style != "win" && m_style != "minimal") m_style = "mac";
    m_wallpaper = s.value("fondo", "").toString();
    m_accent = s.value("acento", "#2F7BF5").toString();
    m_welcomed = s.value("bienvenida", false).toBool();
    m_widgets = s.value("widgets", true).toBool();
    m_mode = s.value("modo", "").toString();
}

void AppSettings::setReducedMotion(bool on) {
    if (on == m_reduced) return;
    m_reduced = on;
    QSettings("BC-OS", "bc-shell").setValue("movimientoReducido", on);
    emit changed();
}

void AppSettings::setLanguage(const QString &l) {
    if (l == m_language) return;
    m_language = l;
    QSettings("BC-OS", "bc-shell").setValue("idioma", l);
    emit changed();
}

void AppSettings::setDesktopStyle(const QString &st) {
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
    if (on == m_widgets) return;
    m_widgets = on;
    QSettings("BC-OS", "bc-shell").setValue("widgets", on);
    notifyPanel("widgets", on ? "1" : "0");
    emit changed();
}

void AppSettings::setMode(const QString &m) {
    const QString v = (m == "relax" || m == "focus" || m == "night") ? m : QString();
    if (v == m_mode) return;
    m_mode = v;
    QSettings("BC-OS", "bc-shell").setValue("modo", v);
    notifyPanel("mode", v.isEmpty() ? "-" : v);
    emit changed();
}

void AppSettings::setWallpaper(const QString &p) {
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
    if (c == m_accent || !QColor::isValidColorName(c)) return;
    m_accent = c;
    QSettings("BC-OS", "bc-shell").setValue("acento", c);
    notifyPanel("accent", c);
    emit changed();
}

void AppSettings::setWelcomed(bool on) {
    if (on == m_welcomed) return;
    m_welcomed = on;
    QSettings("BC-OS", "bc-shell").setValue("bienvenida", on);
    emit changed();
}
