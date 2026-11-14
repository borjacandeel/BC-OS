#pragma once
#include <QObject>
#include <QString>

// Verificación de contraseña con PAM (servicio "bc-lock") para la pantalla de bloqueo.
class PamAuth : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString currentUser READ currentUser CONSTANT)
public:
    explicit PamAuth(QObject *parent = nullptr);
    QString currentUser() const { return m_user; }
    // Asíncrono: emite finished(ok) en el hilo principal.
    Q_INVOKABLE void verify(const QString &password);
    // Síncrono (para pruebas y para el hilo de trabajo).
    static bool verifySync(const QString &user, const QString &password, const QString &service);
signals:
    void finished(bool ok);

private:
    QString m_user;
};
