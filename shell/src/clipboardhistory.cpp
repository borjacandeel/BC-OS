#include "clipboardhistory.h"
#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QTimer>

bool ClipboardHistory::available() const {
    return !QStandardPaths::findExecutable("cliphist").isEmpty() && !QStandardPaths::findExecutable("wl-copy").isEmpty();
}

QVariantList ClipboardHistory::parseList(const QString &out, int max) {
    QVariantList list;
    static const QRegularExpression numeric("^[0-9]+$");
    for (const QString &line : out.split('\n')) {
        const int t = line.indexOf('\t');
        if (t <= 0) continue;
        const QString id = line.left(t);
        QString prev = line.mid(t + 1).trimmed();
        if (!numeric.match(id).hasMatch() || prev.isEmpty()) continue;
        if (prev.startsWith("[[ binary data")) continue;   // imágenes y binarios: no se listan
        if (prev.size() > 140) prev = prev.left(140) + QStringLiteral("…");
        list.append(QVariantMap{{"id", id}, {"text", prev}});
        if (list.size() >= max) break;
    }
    return list;
}

void ClipboardHistory::refresh() {
    const QString exe = QStandardPaths::findExecutable("cliphist");
    if (exe.isEmpty() || m_busy) return;
    m_busy = true;
    auto *p = new QProcess(this);
    connect(p, &QProcess::finished, this, [this, p] {
        m_busy = false;
        m_items = parseList(QString::fromUtf8(p->readAllStandardOutput()));
        emit itemsChanged();
        p->deleteLater();
    });
    connect(p, &QProcess::errorOccurred, this, [this, p](QProcess::ProcessError e) { if (e == QProcess::FailedToStart) { m_busy = false; p->deleteLater(); } });
    QTimer::singleShot(5000, p, [p] { if (p->state() != QProcess::NotRunning) p->kill(); });
    p->start(exe, {"list"});
}

void ClipboardHistory::pick(const QString &id) {
    static const QRegularExpression numeric("^[0-9]+$");
    if (!numeric.match(id).hasMatch()) return;     // el id solo puede ser un número: nunca llega texto al intérprete
    const QString sh = QStandardPaths::findExecutable("sh");
    if (sh.isEmpty()) return;
    QProcess::startDetached(sh, {"-c", "cliphist decode \"$1\" | wl-copy", "sh", id});
}

void ClipboardHistory::clear() {
    const QString exe = QStandardPaths::findExecutable("cliphist");
    if (!exe.isEmpty()) QProcess::startDetached(exe, {"wipe"});
    m_items.clear();
    emit itemsChanged();
}
