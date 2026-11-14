#include "windowlist.h"
#include <QProcess>
#include <QStandardPaths>

WindowList::WindowList(QObject *parent) : QObject(parent) {
    m_exe = QStandardPaths::findExecutable("wlrctl");
    m_available = !m_exe.isEmpty() && !qEnvironmentVariable("WAYLAND_DISPLAY").isEmpty();
    if (!m_available) return;
    m_timer.setInterval(2000);
    connect(&m_timer, &QTimer::timeout, this, &WindowList::refresh);
    m_timer.start();
    QTimer::singleShot(500, this, &WindowList::refresh);
}

QVariantList WindowList::parseList(const QString &out) {
    QVariantList list;
    for (const QString &line : out.split('\n', Qt::SkipEmptyParts)) {
        const int c = line.indexOf(": ");
        const QString id = (c > 0 ? line.left(c) : line).trimmed();
        if (id.isEmpty() || id == "bc-shell") continue;
        list.append(QVariantMap{{"appId", id}, {"title", c > 0 ? line.mid(c + 2).trimmed() : QString()}});
    }
    return list;
}

void WindowList::refresh() {
    if (!m_available) return;
    auto *p = new QProcess(this);
    connect(p, &QProcess::finished, this, [this, p](int code) {
        if (code == 0) {
            const QVariantList w = parseList(QString::fromUtf8(p->readAllStandardOutput()));
            QStringList ids;
            for (const QVariant &v : w) ids << v.toMap().value("appId").toString();
            if (ids != m_appIds) { m_windows = w; m_appIds = ids; emit changed(); }
        }
        p->deleteLater();
    });
    p->start(m_exe, {"toplevel", "list"});
}

void WindowList::act(const QString &verb, const QString &appId) {
    if (!m_available) return;
    QProcess::startDetached(m_exe, {"toplevel", verb, "app_id:" + appId});
    QTimer::singleShot(400, this, &WindowList::refresh);
}
