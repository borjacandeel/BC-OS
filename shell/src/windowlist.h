#pragma once
#include <QObject>
#include <QTimer>
#include <QVariantList>

// Ventanas externas abiertas (compositor labwc) mediante `wlrctl toplevel`.
class WindowList : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList windows READ windows NOTIFY changed)
    Q_PROPERTY(QStringList appIds READ appIds NOTIFY changed)
    Q_PROPERTY(bool available READ available CONSTANT)
public:
    explicit WindowList(QObject *parent = nullptr);
    QVariantList windows() const { return m_windows; }
    QStringList appIds() const { return m_appIds; }
    bool available() const { return m_available; }
    Q_INVOKABLE bool has(const QString &appId) const { return m_appIds.contains(appId); }
    Q_INVOKABLE void focus(const QString &appId) { act("focus", appId); }
    Q_INVOKABLE void minimize(const QString &appId) { act("minimize", appId); }
    Q_INVOKABLE void close(const QString &appId) { act("close", appId); }
    Q_INVOKABLE void refresh();
    // "app_id: título" por línea
    static QVariantList parseList(const QString &out);
signals:
    void changed();

private:
    void act(const QString &verb, const QString &appId);
    QTimer m_timer;
    QString m_exe;
    bool m_available = false;
    QVariantList m_windows;
    QStringList m_appIds;
};
