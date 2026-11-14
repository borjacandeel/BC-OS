#include "appsettings.h"
#include <QProcess>
#include <QStandardPaths>

AppSettings::AppSettings(QObject *parent) : QObject(parent) {
    QSettings s("BC-OS", "bc-shell");
    m_reduced = s.value("movimientoReducido", false).toBool();
    m_language = s.value("idioma", "es_ES").toString();
    m_style = s.value("estiloEscritorio", "mac").toString();
    if (m_style != "win") m_style = "mac";
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
    const QString s = st == "win" ? "win" : "mac";
    if (s == m_style) return;
    m_style = s;
    QSettings("BC-OS", "bc-shell").setValue("estiloEscritorio", s);
    // Avisa al panel en caliente (bc-ctl habla con org.bcos.Shell por D-Bus)
    const QString ctl = QStandardPaths::findExecutable("bc-ctl");
    if (!ctl.isEmpty()) QProcess::startDetached(ctl, {"style", s});
    emit changed();
}
