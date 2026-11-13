#include "appconfig.h"

AppConfig::AppConfig(QString language, bool reducedMotion, QString fixedTime, QObject *parent)
    : QObject(parent), m_language(std::move(language)), m_reducedMotion(reducedMotion),
      m_fixedTime(std::move(fixedTime)) {}
