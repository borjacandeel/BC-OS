#pragma once
#include <QObject>
#include <QString>

class AppConfig : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString language READ language CONSTANT)
    Q_PROPERTY(bool reducedMotion READ reducedMotion CONSTANT)
    Q_PROPERTY(QString fixedTime READ fixedTime CONSTANT)
    Q_PROPERTY(bool splash READ splash CONSTANT)
    Q_PROPERTY(QString demo READ demo CONSTANT)
    Q_PROPERTY(QString openArg READ openArg CONSTANT)
public:
    AppConfig(QString language, bool reducedMotion, QString fixedTime, QObject *parent = nullptr, bool splash = false);
    QString language() const { return m_language; }
    bool reducedMotion() const { return m_reducedMotion; }
    QString fixedTime() const { return m_fixedTime; }
    bool splash() const { return m_splash; }
    // Solo para capturas de prueba: BC_DEMO=lock|menu|power.
    QString openArg() const { return m_openArg; }
    void setOpenArg(const QString &a) { m_openArg = a; }
    QString demo() const { return qEnvironmentVariable("BC_DEMO"); }

private:
    QString m_language;
    bool m_reducedMotion;
    QString m_fixedTime;
    bool m_splash;
    QString m_openArg;
};
