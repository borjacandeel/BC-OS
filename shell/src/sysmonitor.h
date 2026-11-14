#pragma once
#include <QAbstractListModel>
#include <QElapsedTimer>
#include <QHash>
#include <QTimer>

// Monitor del sistema: CPU, memoria, disco, red, temperatura y procesos, leídos de /proc y /sys.
class SysMonitor : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(double cpu READ cpu NOTIFY updated)
    Q_PROPERTY(QVariantList cpuHistory READ cpuHistory NOTIFY updated)
    Q_PROPERTY(qint64 memTotal READ memTotal NOTIFY updated)
    Q_PROPERTY(qint64 memUsed READ memUsed NOTIFY updated)
    Q_PROPERTY(qint64 swapTotal READ swapTotal NOTIFY updated)
    Q_PROPERTY(qint64 swapUsed READ swapUsed NOTIFY updated)
    Q_PROPERTY(qint64 diskTotal READ diskTotal NOTIFY updated)
    Q_PROPERTY(qint64 diskUsed READ diskUsed NOTIFY updated)
    Q_PROPERTY(double netDown READ netDown NOTIFY updated)
    Q_PROPERTY(double netUp READ netUp NOTIFY updated)
    Q_PROPERTY(double temperature READ temperature NOTIFY updated)
    Q_PROPERTY(qint64 uptime READ uptime NOTIFY updated)
    Q_PROPERTY(int processCount READ processCount NOTIFY updated)
    Q_PROPERTY(QString hostname READ hostname CONSTANT)
    Q_PROPERTY(QString kernel READ kernel CONSTANT)
    Q_PROPERTY(QString cpuModel READ cpuModel CONSTANT)
    Q_PROPERTY(QString osName READ osName CONSTANT)
    Q_PROPERTY(int cpuCount READ cpuCount CONSTANT)
public:
    enum Roles { PidRole = Qt::UserRole + 1, NameRole, CpuRole, MemRole };
    explicit SysMonitor(QObject *parent = nullptr);
    bool active() const { return m_timer.isActive(); }
    void setActive(bool on);
    double cpu() const { return m_cpu; }
    QVariantList cpuHistory() const { return m_history; }
    qint64 memTotal() const { return m_memTotal; }
    qint64 memUsed() const { return m_memTotal - m_memAvail; }
    qint64 swapTotal() const { return m_swapTotal; }
    qint64 swapUsed() const { return m_swapTotal - m_swapFree; }
    qint64 diskTotal() const { return m_diskTotal; }
    qint64 diskUsed() const { return m_diskTotal - m_diskFree; }
    double netDown() const { return m_down; }
    double netUp() const { return m_up; }
    double temperature() const { return m_temp; }
    qint64 uptime() const { return m_uptime; }
    int processCount() const { return m_procCount; }
    QString hostname() const;
    QString kernel() const;
    QString cpuModel() const { return m_cpuModel; }
    QString osName() const { return m_osName; }
    // Nombre del procesador a partir de /proc/cpuinfo (en ARM no hay «model name»: se usa el fabricante).
    static QString cpuNameFromInfo(const QString &cpuinfo);
    static QString osNameFromRelease(const QString &osRelease);
    int cpuCount() const { return m_cpuCount; }
    int rowCount(const QModelIndex & = {}) const override { return m_rows.size(); }
    QVariant data(const QModelIndex &i, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    Q_INVOKABLE void refresh();
    Q_INVOKABLE static QString formatBytes(qint64 b);

    // Analizadores puros (pruebas).
    struct CpuTimes { quint64 total = 0, idle = 0; };
    static CpuTimes parseCpuLine(const QString &statText);
    static bool parseMeminfo(const QString &text, qint64 &total, qint64 &avail, qint64 &swapTotal, qint64 &swapFree);
    static bool parseNetDev(const QString &text, quint64 &rx, quint64 &tx);
    struct Proc { int pid = 0; QString name; quint64 ticks = 0; qint64 rssKb = 0; };
    static bool parseProcStat(const QString &stat, Proc &p);

signals:
    void updated();
    void activeChanged();

private:
    QTimer m_timer;
    CpuTimes m_prev;
    bool m_havePrev = false;
    double m_cpu = 0, m_down = 0, m_up = 0, m_temp = -1;
    QVariantList m_history;
    qint64 m_memTotal = 0, m_memAvail = 0, m_swapTotal = 0, m_swapFree = 0, m_diskTotal = 0, m_diskFree = 0, m_uptime = 0;
    int m_procCount = 0, m_cpuCount = 1;
    QString m_cpuModel, m_osName;
    quint64 m_rx = 0, m_tx = 0;
    QElapsedTimer m_netClock;
    QHash<int, quint64> m_procTicks;
    quint64 m_prevTotal = 0;
    struct Row { int pid; QString name; double cpu; qint64 memKb; };
    QList<Row> m_rows;
};
