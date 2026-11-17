#include "notifications.h"
#include <QProcess>
#include <QDBusConnection>
#include <QDateTime>
#include <QDebug>

NotificationQueue::NotificationQueue(QObject *parent) : QObject(parent) {
    m_timer.setSingleShot(true);
    connect(&m_timer, &QTimer::timeout, this, [this] { m_visible = false; emit changed(); });
}

void NotificationQueue::push(const QString &app, const QString &title, const QString &body, const QString &icon, int timeoutMs) {
    m_action.clear();
    QVariantMap h{{"app", app}, {"title", title}, {"body", body}, {"icon", icon},
                  {"time", QDateTime::currentDateTime().toString(Qt::ISODate)}};
    m_history.prepend(h);
    while (m_history.size() > 50) m_history.removeLast();
    if (!m_dnd) {
        m_app = app; m_title = title; m_body = body; m_icon = icon;
        m_visible = true;
        m_timer.start(timeoutMs > 0 ? timeoutMs : 5000);
    }
    emit changed();
}

void NotificationQueue::dismiss() {
    m_timer.stop();
    m_visible = false;
    emit changed();
    emit dismissedByUser();
}

NotificationServer::NotificationServer(NotificationQueue *queue, QObject *parent) : QObject(parent), m_queue(queue) {}

bool NotificationServer::start() {
    QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.isConnected()) { qWarning() << "[notificaciones] sin bus de sesión D-Bus"; return false; }
    if (!bus.registerService("org.freedesktop.Notifications")) {
        qWarning() << "[notificaciones] otro servicio ya usa org.freedesktop.Notifications";
        return false;
    }
    return bus.registerObject("/org/freedesktop/Notifications", this,
                              QDBusConnection::ExportAllSlots | QDBusConnection::ExportAllSignals);
}

uint NotificationServer::Notify(const QString &app_name, uint replaces_id, const QString &app_icon, const QString &summary,
                                const QString &body, const QStringList &, const QVariantMap &, int expire_timeout) {
    const uint id = replaces_id > 0 ? replaces_id : m_nextId++;
    m_queue->push(app_name, summary, body, app_icon, expire_timeout);
    return id;
}

void NotificationServer::CloseNotification(uint id) {
    m_queue->dismiss();
    emit NotificationClosed(id, 3);
}

QStringList NotificationServer::GetCapabilities() { return {"body"}; }

QString NotificationServer::GetServerInformation(QString &vendor, QString &version, QString &spec_version) {
    vendor = "BC OS";
    version = "0.2";
    spec_version = "1.2";
    return "BC Shell";
}

bool NotificationQueue::activate() {
    if (m_action.isEmpty()) return false;
    const QStringList cmd = m_action;
    m_action.clear();
    QProcess::startDetached(cmd.first(), cmd.mid(1));
    dismiss();
    return true;
}
