#include "updatechecker.h"
#include <QProcess>
#include <QStandardPaths>

UpdateChecker::UpdateChecker(QObject *parent) : QObject(parent) {
    m_timer.setInterval(6 * 3600 * 1000);
    connect(&m_timer, &QTimer::timeout, this, &UpdateChecker::check);
    m_timer.start();
    QTimer::singleShot(120 * 1000, this, &UpdateChecker::check);   // primera comprobación tras iniciar sesión
}

int UpdateChecker::parseCount(const QString &out) {
    int n = 0;
    for (const QString &line : out.split('\n')) if (line.trimmed().contains(" -> ")) ++n;
    return n;
}

void UpdateChecker::check() {
    const QString exe = QStandardPaths::findExecutable("checkupdates");
    if (exe.isEmpty() || m_busy) return;
    m_busy = true;
    auto *p = new QProcess(this);
    connect(p, &QProcess::finished, this, [this, p] {
        m_busy = false;
        const int n = parseCount(QString::fromUtf8(p->readAllStandardOutput()));
        if (n != m_count) { m_count = n; emit countChanged(); }
        if (n > 0 && n != m_notified) { m_notified = n; emit updatesFound(n); }
        p->deleteLater();
    });
    connect(p, &QProcess::errorOccurred, this, [this, p](QProcess::ProcessError e) { if (e == QProcess::FailedToStart) { m_busy = false; p->deleteLater(); } });
    QTimer::singleShot(120000, p, [p] { if (p->state() != QProcess::NotRunning) p->kill(); });
    p->start(exe, {});
}
