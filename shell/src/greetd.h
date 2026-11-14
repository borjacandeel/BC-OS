#pragma once
#include <QJsonObject>
#include <QLocalSocket>
#include <QObject>
#include <QStringList>

// Cliente del protocolo IPC de greetd (JSON con prefijo de longitud u32 nativo) por $GREETD_SOCK.
class GreetdClient : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
public:
    explicit GreetdClient(QObject *parent = nullptr);
    bool busy() const { return m_state != Idle; }
    void setSession(const QStringList &cmd, const QStringList &env) { m_cmd = cmd; m_env = env; }
    // Autentica y arranca la sesión. Emite authFailed(msg), errorOccurred(msg) o succeeded().
    Q_INVOKABLE void login(const QString &user, const QString &password);
    // Para pruebas: procesa un mensaje y devuelve el siguiente a enviar (objeto vacío = ninguno).
    QJsonObject handle(const QJsonObject &msg);
    static QByteArray frame(const QJsonObject &o);
signals:
    void busyChanged();
    void authFailed(const QString &message);
    void errorOccurred(const QString &message);
    void succeeded();

private:
    enum State { Idle, Creating, Authing, Starting, Cancelling };
    void send(const QJsonObject &o);
    void onReadyRead();
    void fail(const QString &message, bool auth);
    void setState(State s);

    QLocalSocket m_sock;
    QByteArray m_buf;
    State m_state = Idle;
    QString m_user, m_password;
    QStringList m_cmd{"bc-session", "--greetd"};
    QStringList m_env{"XDG_SESSION_TYPE=wayland", "XDG_CURRENT_DESKTOP=BC"};
};
