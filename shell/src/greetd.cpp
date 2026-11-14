#include "greetd.h"
#include <QJsonArray>
#include <QJsonDocument>
#include <QtEndian>
#include <cstring>

GreetdClient::GreetdClient(QObject *parent) : QObject(parent) {
    connect(&m_sock, &QLocalSocket::readyRead, this, &GreetdClient::onReadyRead);
    connect(&m_sock, &QLocalSocket::errorOccurred, this, [this] {
        if (m_state != Idle) fail(m_sock.errorString(), false);
    });
}

QByteArray GreetdClient::frame(const QJsonObject &o) {
    const QByteArray body = QJsonDocument(o).toJson(QJsonDocument::Compact);
    const quint32 n = static_cast<quint32>(body.size());
    QByteArray out(4, '\0');
    memcpy(out.data(), &n, 4);  // longitud en orden de bytes nativo, como exige greetd
    return out + body;
}

void GreetdClient::setState(State s) {
    const bool was = busy();
    m_state = s;
    if (was != busy()) emit busyChanged();
}

void GreetdClient::send(const QJsonObject &o) { m_sock.write(frame(o)); m_sock.flush(); }

void GreetdClient::login(const QString &user, const QString &password) {
    if (m_state != Idle) return;
    m_user = user;
    m_password = password;
    const QString path = qEnvironmentVariable("GREETD_SOCK");
    if (path.isEmpty()) { emit errorOccurred(tr("No se encuentra el servicio de inicio de sesión")); return; }
    m_buf.clear();
    if (m_sock.state() != QLocalSocket::ConnectedState) {
        m_sock.abort();
        m_sock.connectToServer(path);
        if (!m_sock.waitForConnected(3000)) { emit errorOccurred(tr("No se puede conectar con el inicio de sesión")); return; }
    }
    setState(Creating);
    send({{"type", "create_session"}, {"username", user}});
}

void GreetdClient::fail(const QString &message, bool auth) {
    const bool cancel = m_state != Idle && m_sock.state() == QLocalSocket::ConnectedState && m_state != Cancelling;
    m_password.clear();
    if (cancel) { setState(Cancelling); send({{"type", "cancel_session"}}); }
    else setState(Idle);
    if (auth) emit authFailed(message); else emit errorOccurred(message);
}

QJsonObject GreetdClient::handle(const QJsonObject &msg) {
    const QString t = msg.value("type").toString();
    if (m_state == Cancelling) { setState(Idle); return {}; }
    if (t == "auth_message") {
        const QString k = msg.value("auth_message_type").toString();
        setState(Authing);
        if (k == "secret" || k == "visible")
            return {{"type", "post_auth_message_response"}, {"response", m_password}};
        return {{"type", "post_auth_message_response"}};
    }
    if (t == "success") {
        if (m_state == Starting) { m_password.clear(); setState(Idle); emit succeeded(); return {}; }
        setState(Starting);
        QJsonArray cmd, env;
        for (const auto &c : m_cmd) cmd.append(c);
        for (const auto &e : m_env) env.append(e);
        return {{"type", "start_session"}, {"cmd", cmd}, {"env", env}};
    }
    if (t == "error") {
        const bool auth = msg.value("error_type").toString() == "auth_error";
        fail(auth ? tr("Contraseña incorrecta") : msg.value("description").toString(), auth);
    }
    return {};
}

void GreetdClient::onReadyRead() {
    m_buf += m_sock.readAll();
    while (m_buf.size() >= 4) {
        quint32 n;
        memcpy(&n, m_buf.constData(), 4);
        if (m_buf.size() < 4 + static_cast<int>(n)) return;
        const QJsonObject msg = QJsonDocument::fromJson(m_buf.mid(4, n)).object();
        m_buf.remove(0, 4 + n);
        const QJsonObject next = handle(msg);
        if (!next.isEmpty()) send(next);
    }
}
