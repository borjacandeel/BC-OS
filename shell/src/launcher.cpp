#include "launcher.h"
#include <QCoreApplication>
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
        return env.isEmpty() ? QStringLiteral("bc-terminal") : env;
    }
    if (kind == "navegador") {
        const QString env = qEnvironmentVariable("BC_BROWSER");
        return env.isEmpty() ? QStringLiteral("firefox") : env;
    }
    return {};
}

bool Launcher::run(const QString &program, const QStringList &args) {
    const QString exe = QStandardPaths::findExecutable(program);
    return !exe.isEmpty() && QProcess::startDetached(exe, args);
}

QString Launcher::bcAppName(const QString &kind) {
    if (kind == "archivos") return "files";
    if (kind == "monitor") return "monitor";
    if (kind == "ajustes") return "settings";
    if (kind == "tienda") return "store";
    if (kind == "notas") return "notes";
    if (kind == "calculadora") return "calculator";
    if (kind == "vista") return "preview";
    if (kind == "musica") return "music";
    return {};
}

QString Launcher::appIdFor(const QString &kind) {
    const QString n = bcAppName(kind);
    if (!n.isEmpty()) return "bc-" + n;
    if (kind == "terminal") return "Alacritty";
    if (kind == "navegador") return "firefox";
    return {};
}

QString Launcher::launch(const QString &kind, const QString &open) {
    QString exe;
    QStringList args;
    const QString bc = bcAppName(kind);
    if (!bc.isEmpty()) {
        const QString env = qEnvironmentVariable("BC_SHELL_BIN");
        exe = env.isEmpty() ? QCoreApplication::applicationFilePath() : env;
        args = {"--app", bc};
        if (!open.isEmpty()) args << "--open" << open;
    } else {
        const QString prog = programFor(kind);
        if (prog.isEmpty()) return "unavailable";
        exe = QStandardPaths::findExecutable(prog);
        if (exe.isEmpty()) return "failed";
    }
    if (m_pids.contains(kind)) return "started";
    qint64 pid = 0;
    if (!QProcess::startDetached(exe, args, QString(), &pid) || pid <= 0) return "failed";
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
