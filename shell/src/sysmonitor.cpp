#include "sysmonitor.h"
#include <QDir>
#include <QFile>
#include <QRegularExpression>
#include <QStorageInfo>
#include <algorithm>
#include <unistd.h>

namespace {
QString slurp(const QString &path) {
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) return {};
    return QString::fromUtf8(f.readAll());
}
}  // namespace

SysMonitor::SysMonitor(QObject *parent) : QAbstractListModel(parent) {
    m_timer.setInterval(2000);
    connect(&m_timer, &QTimer::timeout, this, &SysMonitor::refresh);
    m_cpuCount = qMax(1, int(sysconf(_SC_NPROCESSORS_ONLN)));
    for (const QString &l : slurp("/proc/cpuinfo").split('\n')) {
        if (l.startsWith("model name") || l.startsWith("Model") || l.startsWith("Hardware")) {
            m_cpuModel = l.section(':', 1).trimmed();
            break;
        }
    }
    if (m_cpuModel.isEmpty()) m_cpuModel = QStringLiteral("ARM64");
}

void SysMonitor::setActive(bool on) {
    if (on == m_timer.isActive()) return;
    if (on) { m_timer.start(); refresh(); } else { m_timer.stop(); m_havePrev = false; }
    emit activeChanged();
}

QString SysMonitor::hostname() const { return slurp("/etc/hostname").trimmed(); }
QString SysMonitor::kernel() const { return slurp("/proc/sys/kernel/osrelease").trimmed(); }

SysMonitor::CpuTimes SysMonitor::parseCpuLine(const QString &text) {
    CpuTimes t;
    const QString line = text.section('\n', 0, 0);
    if (!line.startsWith("cpu ")) return t;
    const QStringList f = line.simplified().split(' ');
    quint64 sum = 0;
    for (int i = 1; i < f.size() && i <= 8; ++i) sum += f[i].toULongLong();
    t.total = sum;
    t.idle = f.value(4).toULongLong() + f.value(5).toULongLong();
    return t;
}

bool SysMonitor::parseMeminfo(const QString &text, qint64 &total, qint64 &avail, qint64 &swapTotal, qint64 &swapFree) {
    int found = 0;
    for (const QString &l : text.split('\n')) {
        const qint64 v = l.section(':', 1).simplified().section(' ', 0, 0).toLongLong() * 1024;
        if (l.startsWith("MemTotal:")) { total = v; ++found; }
        else if (l.startsWith("MemAvailable:")) { avail = v; ++found; }
        else if (l.startsWith("SwapTotal:")) { swapTotal = v; ++found; }
        else if (l.startsWith("SwapFree:")) { swapFree = v; ++found; }
    }
    return found == 4;
}

bool SysMonitor::parseNetDev(const QString &text, quint64 &rx, quint64 &tx) {
    rx = tx = 0;
    bool any = false;
    for (const QString &l : text.split('\n')) {
        if (!l.contains(':')) continue;
        const QString dev = l.section(':', 0, 0).trimmed();
        if (dev == "lo" || dev.isEmpty() || dev.startsWith("Inter") || dev.startsWith("face")) continue;
        const QStringList f = l.section(':', 1).simplified().split(' ');
        if (f.size() < 9) continue;
        rx += f[0].toULongLong();
        tx += f[8].toULongLong();
        any = true;
    }
    return any;
}

bool SysMonitor::parseProcStat(const QString &stat, Proc &p) {
    const int a = stat.indexOf('('), b = stat.lastIndexOf(')');
    if (a < 0 || b < a) return false;
    p.pid = stat.left(a).trimmed().toInt();
    p.name = stat.mid(a + 1, b - a - 1);
    const QStringList f = stat.mid(b + 2).split(' ');
    if (f.size() < 22) return false;
    p.ticks = f[11].toULongLong() + f[12].toULongLong();  // utime + stime
    p.rssKb = f[21].toLongLong() * (sysconf(_SC_PAGESIZE) / 1024);
    return p.pid > 0;
}

void SysMonitor::refresh() {
    const QString stat = slurp("/proc/stat");
    const CpuTimes now = parseCpuLine(stat);
    quint64 dTotal = 0;
    if (m_havePrev && now.total > m_prev.total) {
        dTotal = now.total - m_prev.total;
        const quint64 dIdle = now.idle - m_prev.idle;
        m_cpu = qBound(0.0, 100.0 * double(dTotal - dIdle) / double(dTotal), 100.0);
        m_history.append(m_cpu);
        while (m_history.size() > 40) m_history.removeFirst();
    }
    m_prev = now;
    m_havePrev = true;

    qint64 t = 0, a = 0, st = 0, sf = 0;
    if (parseMeminfo(slurp("/proc/meminfo"), t, a, st, sf)) { m_memTotal = t; m_memAvail = a; m_swapTotal = st; m_swapFree = sf; }
    const QStorageInfo root("/");
    m_diskTotal = root.bytesTotal();
    m_diskFree = root.bytesAvailable();
    m_uptime = slurp("/proc/uptime").section(' ', 0, 0).toDouble();

    quint64 rx = 0, tx = 0;
    if (parseNetDev(slurp("/proc/net/dev"), rx, tx)) {
        if (m_netClock.isValid() && m_netClock.elapsed() > 0 && rx >= m_rx && tx >= m_tx) {
            const double s = m_netClock.elapsed() / 1000.0;
            m_down = (rx - m_rx) / s;
            m_up = (tx - m_tx) / s;
        }
        m_rx = rx; m_tx = tx;
        m_netClock.restart();
    }

    m_temp = -1;
    const QDir th("/sys/class/thermal");
    for (const QString &z : th.entryList({"thermal_zone*"}, QDir::Dirs)) {
        const QString v = slurp(th.filePath(z + "/temp")).trimmed();
        if (!v.isEmpty()) { m_temp = v.toDouble() / 1000.0; break; }
    }

    // Procesos: CPU% = delta de ticks / delta de ticks totales del sistema * núcleos * 100.
    QList<Row> rows;
    QHash<int, quint64> ticks;
    int count = 0;
    const QDir proc("/proc");
    for (const QString &e : proc.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
        bool ok = false;
        e.toInt(&ok);
        if (!ok) continue;
        Proc p;
        if (!parseProcStat(slurp("/proc/" + e + "/stat"), p)) continue;
        ++count;
        ticks.insert(p.pid, p.ticks);
        double cpu = 0;
        if (dTotal > 0 && m_procTicks.contains(p.pid) && p.ticks >= m_procTicks[p.pid])
            cpu = 100.0 * double(p.ticks - m_procTicks[p.pid]) / double(dTotal) * m_cpuCount;
        rows.append({p.pid, p.name, cpu, p.rssKb});
    }
    m_procTicks = ticks;
    m_procCount = count;
    std::sort(rows.begin(), rows.end(), [](const Row &x, const Row &y) {
        return x.cpu != y.cpu ? x.cpu > y.cpu : x.memKb > y.memKb;
    });
    if (rows.size() > 30) rows.resize(30);
    beginResetModel();
    m_rows = rows;
    endResetModel();
    emit updated();
}

QVariant SysMonitor::data(const QModelIndex &i, int role) const {
    if (!i.isValid() || i.row() >= m_rows.size()) return {};
    const Row &r = m_rows[i.row()];
    switch (role) {
    case PidRole: return r.pid;
    case NameRole: return r.name;
    case CpuRole: return r.cpu;
    case MemRole: return r.memKb * 1024;
    }
    return {};
}

QHash<int, QByteArray> SysMonitor::roleNames() const {
    return {{PidRole, "pid"}, {NameRole, "name"}, {CpuRole, "cpu"}, {MemRole, "mem"}};
}

QString SysMonitor::formatBytes(qint64 b) {
    const char *u[] = {"B", "KB", "MB", "GB", "TB"};
    double v = b;
    int i = 0;
    while (v >= 1024 && i < 4) { v /= 1024; ++i; }
    return QString::number(v, 'f', i == 0 ? 0 : (v < 10 ? 2 : 1)) + " " + u[i];
}
