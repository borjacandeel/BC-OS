#pragma once
#include <QObject>
#include <QStringList>
#include <QVariantList>

// Entornos de escritorio elegibles al iniciar sesión (/usr/share/bc/sessions/*.desktop). Lo usan el login y Configuración.
class SessionList : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList sessions READ sessions CONSTANT)
    Q_PROPERTY(int current READ current WRITE setCurrent NOTIFY currentChanged)
    Q_PROPERTY(QString currentId READ currentId NOTIFY currentChanged)
    Q_PROPERTY(QString runningId READ runningId CONSTANT)
public:
    explicit SessionList(const QString &dir = QString(), const QString &stateDir = QString(), QObject *parent = nullptr);
    QVariantList sessions() const { return m_sessions; }
    int current() const { return m_current; }
    QString currentId() const;
    QString runningId() const { return qEnvironmentVariable("BC_SESSION_ID", "bc"); }
    void setCurrent(int i);
    // Orden para greetd: programa y argumentos, y variables de entorno de la sesión elegida.
    QStringList currentCommand() const;
    QStringList currentEnv() const;
    // Preferencia por usuario (la escribe el propio usuario desde Configuración; la lee el login antes de autenticar).
    Q_INVOKABLE void selectFor(const QString &user);
    Q_INVOKABLE bool remember(const QString &user, const QString &id);
    Q_INVOKABLE void rememberLast(const QString &id);
    Q_INVOKABLE QString currentUserName() const { return qEnvironmentVariable("USER", qEnvironmentVariable("LOGNAME")); }

    static QVariantMap parseDesktop(const QString &text, const QString &id);
    static bool validId(const QString &id);
signals:
    void currentChanged();

private:
    QString stateFile(const QString &name) const;
    QVariantList m_sessions;
    int m_current = 0;
    QString m_stateDir;
};
