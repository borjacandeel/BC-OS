#include "appconfig.h"

AppConfig::AppConfig(QString language, bool reducedMotion, QString fixedTime, QObject *parent, bool splash)
    : QObject(parent), m_language(std::move(language)), m_reducedMotion(reducedMotion),
      m_fixedTime(std::move(fixedTime)), m_splash(splash) {}
