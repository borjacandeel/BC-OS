#pragma once
#include <QObject>
#include <QTimer>

// Avisa de actualizaciones disponibles (checkupdates, de pacman-contrib: no toca la base de datos real).
class UpdateChecker : public QObject {
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
public:
    explicit UpdateChecker(QObject *parent = nullptr);
    int count() const { return m_count; }
    Q_INVOKABLE void check();
    static int parseCount(const QString &out);
signals:
    void countChanged();
    void updatesFound(int count);     // solo cuando hay actualizaciones nuevas respecto al último aviso

private:
    int m_count = 0, m_notified = 0;
    bool m_busy = false;
    QTimer m_timer;
};
