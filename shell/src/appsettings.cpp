#include "appsettings.h"

AppSettings::AppSettings(QObject *parent) : QObject(parent) {
    QSettings s("BC-OS", "bc-shell");
    m_reduced = s.value("movimientoReducido", false).toBool();
    m_language = s.value("idioma", "es_ES").toString();
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
