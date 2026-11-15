#include "appconfig.h"
#include <QColor>
#include <QSettings>

AppConfig::AppConfig(QString language, bool reducedMotion, QString fixedTime, QObject *parent, bool splash)
    : QObject(parent), m_language(std::move(language)), m_reducedMotion(reducedMotion),
      m_fixedTime(std::move(fixedTime)), m_splash(splash) {
    const QString a = QSettings("BC-OS", "bc-shell").value("acento", qEnvironmentVariableIntValue("BC_CLASSIC") == 1 ? "#2F7BF5" : "#0A84FF").toString();
    if (QColor::isValidColorName(a)) m_accent = a;
}

void AppConfig::setAccent(const QString &c) {
    if (!QColor::isValidColorName(c) || c == m_accent) return;
    m_accent = c;
    emit accentChanged();
}
