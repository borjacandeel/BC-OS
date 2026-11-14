#include "launcher.h"
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QStandardPaths>

Launcher::Launcher(QObject *parent) : QObject(parent) {
    m_timer.setInterval(1000);
    connect(&m_timer, &QTimer::timeout, this, &Launcher::poll);
}

QString Launcher::programFor(const QString &kind) {
    if (kind == "terminal") {
        const QString env = qEnvironmentVariable("BC_TERMINAL");
        return env.isEmpty() ? QStringLiteral("foot") : env;
    }
    if (kind == "navegador") {
        const QString env = qEnvironmentVariable("BC_BROWSER");
        return env.isEmpty() ? QStringLiteral("firefox") : env;
    }
    return {};
}

QString Launcher::launch(const QString &kind) {
    if (kind == "archivos" || kind == "monitor" || kind == "ajustes" || kind == "tienda") return "internal";
    const QString prog = programFor(kind);
    if (prog.isEmpty()) return "unavailable";
    if (m_pids.contains(kind)) return "started";
    const QString exe = QStandardPaths::findExecutable(prog);
    if (exe.isEmpty()) return "failed";
    qint64 pid = 0;
    if (!QProcess::startDetached(exe, {}, QString(), &pid) || pid <= 0) return "failed";
    m_pids.insert(kind, pid);
    m_timer.start();
    emit runningChanged();
    return "started";
}

void Launcher::poll() {
    bool changed = false;
    for (auto it = m_pids.begin(); it != m_pids.end();) {
        bool alive = false;
        QFile f(QStringLiteral("/proc/%1/stat").arg(it.value()));
        if (f.open(QIODevice::ReadOnly)) {
            const QByteArray d = f.readAll();
            const int i = d.lastIndexOf(')');
            alive = !(i > 0 && d.mid(i + 2, 1) == "Z");  // zombi = terminado
        }
        if (!alive) { it = m_pids.erase(it); changed = true; } else ++it;
    }
    if (m_pids.isEmpty()) m_timer.stop();
    if (changed) emit runningChanged();
}
