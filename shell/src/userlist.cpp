#include "userlist.h"
#include <QFile>
#include <QVariantMap>

QVariantList UserList::parse(const QString &passwdPath) {
    QVariantList out;
    QFile f(passwdPath);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) return out;
    while (!f.atEnd()) {
        const QString line = QString::fromUtf8(f.readLine()).trimmed();
        const QStringList p = line.split(':');
        if (p.size() < 7) continue;
        bool ok = false;
        const int uid = p[2].toInt(&ok);
        if (!ok || uid < 1000 || uid >= 60000) continue;
        const QString shell = p[6];
        if (shell.endsWith("nologin") || shell.endsWith("/false")) continue;
        QString display = p[4].split(',').value(0).trimmed();
        if (display.isEmpty()) display = p[0];
        out.append(QVariantMap{{"name", p[0]}, {"display", display}, {"uid", uid}});
    }
    return out;
}

UserList::UserList(const QString &passwdPath, QObject *parent) : QObject(parent) {
    const QString path = !passwdPath.isEmpty() ? passwdPath
                       : qEnvironmentVariable("BC_PASSWD", "/etc/passwd");
    m_users = parse(path);
}
