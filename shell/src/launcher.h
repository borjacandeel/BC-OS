#pragma once
#include <QHash>
#include <QObject>
#include <QStringList>
#include <QTimer>

// Lanza aplicaciones reales y vigila si siguen vivas (/proc/<pid>).
class Launcher : public QObject {
    Q_OBJECT
    Q_PROPERTY(QStringList running READ running NOTIFY runningChanged)
public:
    explicit Launcher(QObject *parent = nullptr);
    QStringList running() const { return m_pids.keys(); }
    // Devuelve: "started" o "unavailable"/"failed". Las apps de BC se lanzan como procesos propios (`bc-shell --app`).
    Q_INVOKABLE QString launch(const QString &kind, const QString &open = QString());
    // app_id de sway de cada tipo del Dock.
    Q_INVOKABLE static QString appIdFor(const QString &kind);
    static QString bcAppName(const QString &kind);
    Q_INVOKABLE bool isRunning(const QString &kind) const { return m_pids.contains(kind); }
    // Programa de la app (vacío = sin implementar). Terminal: BC_TERMINAL o foot.
    static QString programFor(const QString &kind);
    void poll();
signals:
    void runningChanged();

private:
    QHash<QString, qint64> m_pids;
    QTimer m_timer;
};
