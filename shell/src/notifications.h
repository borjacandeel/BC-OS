#pragma once
#include <QObject>
#include <QStringList>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>

// Cola de notificaciones visible para QML (singleton "Notifications"): una tarjeta activa e historial.
class NotificationQueue : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool visible READ visible NOTIFY changed)
    Q_PROPERTY(QString app READ app NOTIFY changed)
    Q_PROPERTY(QString title READ title NOTIFY changed)
    Q_PROPERTY(QString body READ body NOTIFY changed)
    Q_PROPERTY(QString icon READ icon NOTIFY changed)
    Q_PROPERTY(QVariantList history READ history NOTIFY changed)
    Q_PROPERTY(bool dnd READ dnd WRITE setDnd NOTIFY changed)
public:
    explicit NotificationQueue(QObject *parent = nullptr);
    bool visible() const { return m_visible; }
    QString app() const { return m_app; }
    QString title() const { return m_title; }
    QString body() const { return m_body; }
    QString icon() const { return m_icon; }
    QVariantList history() const { return m_history; }
    bool dnd() const { return m_dnd; }
    void setDnd(bool on) { if (m_dnd != on) { m_dnd = on; emit changed(); } }
    // timeoutMs <= 0: 5 s por defecto. Con No molestar solo se guarda en el historial.
    Q_INVOKABLE void push(const QString &app, const QString &title, const QString &body, const QString &icon, int timeoutMs = 5000);
    Q_INVOKABLE void dismiss();
    Q_INVOKABLE void clearHistory() { m_history.clear(); emit changed(); }
    Q_INVOKABLE void removeAt(int i) { if (i >= 0 && i < m_history.size()) { m_history.removeAt(i); emit changed(); } }
signals:
    void changed();
    void dismissedByUser();

private:
    QTimer m_timer;
    bool m_visible = false, m_dnd = false;
    QString m_app, m_title, m_body, m_icon;
    QVariantList m_history;
};

// Servicio D-Bus org.freedesktop.Notifications.
class NotificationServer : public QObject {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.freedesktop.Notifications")
public:
    explicit NotificationServer(NotificationQueue *queue, QObject *parent = nullptr);
    bool start();
public slots:
    uint Notify(const QString &app_name, uint replaces_id, const QString &app_icon, const QString &summary,
                const QString &body, const QStringList &actions, const QVariantMap &hints, int expire_timeout);
    void CloseNotification(uint id);
    QStringList GetCapabilities();
    QString GetServerInformation(QString &vendor, QString &version, QString &spec_version);
signals:
    void NotificationClosed(uint id, uint reason);
    void ActionInvoked(uint id, const QString &action_key);

private:
    NotificationQueue *m_queue;
    uint m_nextId = 1;
};
