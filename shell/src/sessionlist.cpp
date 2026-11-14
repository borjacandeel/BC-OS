#include "sessionlist.h"
#include <QDir>
#include <QFile>
#include <QRegularExpression>
#include <QSaveFile>
#include <algorithm>

bool SessionList::validId(const QString &id) {
    static const QRegularExpression re("^[a-z0-9][a-z0-9_-]{0,31}$");
    return re.match(id).hasMatch();
}

QVariantMap SessionList::parseDesktop(const QString &text, const QString &id) {
    QVariantMap m;
    bool inEntry = false;
    QString name, exec, comment, type = "wayland";
    int order = 100;
    for (const QString &raw : text.split('\n')) {
        const QString l = raw.trimmed();
        if (l.startsWith('[')) { inEntry = l == "[Desktop Entry]"; continue; }
        if (!inEntry || l.isEmpty() || l.startsWith('#')) continue;
        const int eq = l.indexOf('=');
        if (eq <= 0) continue;
        const QString k = l.left(eq).trimmed(), v = l.mid(eq + 1).trimmed();
        if (k == "Name") name = v;
        else if (k == "Exec") exec = v;
        else if (k == "Comment") comment = v;
        else if (k == "X-BC-Type") type = v == "x11" ? "x11" : "wayland";
        else if (k == "X-BC-Order") order = v.toInt();
    }
    if (name.isEmpty() || exec.isEmpty() || !validId(id)) return m;
    m = QVariantMap{{"id", id}, {"name", name}, {"comment", comment}, {"exec", exec}, {"type", type}, {"order", order}};
    return m;
}

SessionList::SessionList(const QString &dirIn, const QString &stateIn, QObject *parent) : QObject(parent) {
    const QString dir = !dirIn.isEmpty() ? dirIn : qEnvironmentVariable("BC_SESSIONS_DIR", "/usr/share/bc/sessions");
    m_stateDir = !stateIn.isEmpty() ? stateIn : qEnvironmentVariable("BC_SESSION_STATE", "/var/lib/bc-greeter");
    for (const QString &f : QDir(dir).entryList({"*.desktop"}, QDir::Files)) {
        QFile file(QDir(dir).filePath(f));
        if (!file.open(QIODevice::ReadOnly)) continue;
        const QVariantMap s = parseDesktop(QString::fromUtf8(file.readAll()), f.left(f.size() - 8));
        if (!s.isEmpty()) m_sessions.append(s);
    }
    std::sort(m_sessions.begin(), m_sessions.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap().value("order").toInt() < b.toMap().value("order").toInt();
    });
    if (m_sessions.isEmpty())   // sin carpeta de sesiones: solo BC OS
        m_sessions.append(QVariantMap{{"id", "bc"}, {"name", "BC OS"}, {"comment", ""}, {"exec", "bc-session --greetd"}, {"type", "wayland"}, {"order", 0}});
    // última elección global
    QFile last(stateFile("last"));
    if (last.open(QIODevice::ReadOnly)) {
        const QString id = QString::fromUtf8(last.readAll()).trimmed();
        for (int i = 0; i < m_sessions.size(); ++i) if (m_sessions[i].toMap().value("id").toString() == id) m_current = i;
    }
}

QString SessionList::stateFile(const QString &name) const { return m_stateDir + "/" + name; }

QString SessionList::currentId() const { return m_sessions.value(m_current).toMap().value("id").toString(); }

void SessionList::setCurrent(int i) {
    if (i < 0 || i >= m_sessions.size() || i == m_current) return;
    m_current = i;
    emit currentChanged();
}

QStringList SessionList::currentCommand() const {
    return m_sessions.value(m_current).toMap().value("exec").toString().split(' ', Qt::SkipEmptyParts);
}

QStringList SessionList::currentEnv() const {
    const QVariantMap s = m_sessions.value(m_current).toMap();
    const bool x11 = s.value("type").toString() == "x11";
    return {QString("XDG_SESSION_TYPE=%1").arg(x11 ? "x11" : "wayland"),
            QString("XDG_CURRENT_DESKTOP=%1").arg(x11 ? "BC-Dotfiles" : "BC"),
            "BC_GREETD=1", QString("BC_SESSION_ID=%1").arg(s.value("id").toString())};
}

void SessionList::selectFor(const QString &user) {
    static const QRegularExpression ok("^[a-z_][a-z0-9_-]*$");
    if (!ok.match(user).hasMatch()) return;
    QFile f(stateFile("session-" + user));
    if (!f.open(QIODevice::ReadOnly)) return;
    const QString id = QString::fromUtf8(f.readAll()).trimmed();
    for (int i = 0; i < m_sessions.size(); ++i)
        if (m_sessions[i].toMap().value("id").toString() == id) { setCurrent(i); return; }
}

bool SessionList::remember(const QString &user, const QString &id) {
    static const QRegularExpression ok("^[a-z_][a-z0-9_-]*$");
    if (!ok.match(user).hasMatch() || !validId(id)) return false;
    bool known = false;
    for (const QVariant &s : m_sessions) if (s.toMap().value("id").toString() == id) known = true;
    if (!known) return false;
    QSaveFile f(stateFile("session-" + user));
    if (!f.open(QIODevice::WriteOnly)) return false;
    f.write(id.toUtf8() + "\n");
    return f.commit();
}

void SessionList::rememberLast(const QString &id) {
    if (!validId(id)) return;
    QSaveFile f(stateFile("last"));
    if (f.open(QIODevice::WriteOnly)) { f.write(id.toUtf8() + "\n"); f.commit(); }
}
