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
    // Devuelve: "started", "internal", "unavailable", "failed".
    Q_INVOKABLE QString launch(const QString &kind);
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
