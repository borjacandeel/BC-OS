#pragma once
#include <QObject>
#include <QString>

class AppConfig : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString language READ language CONSTANT)
    Q_PROPERTY(bool reducedMotion READ reducedMotion CONSTANT)
    Q_PROPERTY(QString fixedTime READ fixedTime CONSTANT)
public:
    AppConfig(QString language, bool reducedMotion, QString fixedTime, QObject *parent = nullptr);
    QString language() const { return m_language; }
    bool reducedMotion() const { return m_reducedMotion; }
    QString fixedTime() const { return m_fixedTime; }

private:
    QString m_language;
    bool m_reducedMotion;
    QString m_fixedTime;
};
