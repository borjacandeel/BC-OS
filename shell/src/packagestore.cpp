#include "packagestore.h"
#include <QRegularExpression>
#include <QStandardPaths>

PackageStore::PackageStore(QObject *parent) : QAbstractListModel(parent) {}

QVariant PackageStore::data(const QModelIndex &i, int role) const {
    if (!i.isValid() || i.row() >= m_rows.size()) return {};
    const Pkg &p = m_rows[i.row()];
    switch (role) {
    case NameRole: return p.name;
    case RepoRole: return p.repo;
    case VersionRole: return p.version;
    case DescRole: return p.desc;
    case InstalledRole: return p.installed;
    }
    return {};
}

QHash<int, QByteArray> PackageStore::roleNames() const {
    return {{NameRole, "name"}, {RepoRole, "repo"}, {VersionRole, "version"}, {DescRole, "desc"}, {InstalledRole, "installed"}};
}

QList<PackageStore::Pkg> PackageStore::parseSearch(const QString &out) {
    // repo/nombre versión [grupos] [installed[: x]]  + línea indentada con la descripción
    static const QRegularExpression head(R"(^([^/\s]+)/(\S+)\s+(\S+)(.*)$)");
    QList<Pkg> list;
    for (const QString &line : out.split('\n')) {
        if (line.isEmpty()) continue;
        if (line.startsWith(' ') || line.startsWith('\t')) {
            if (!list.isEmpty()) list.last().desc = line.trimmed();
            continue;
        }
        const auto m = head.match(line);
        if (!m.hasMatch()) continue;
        Pkg p;
        p.repo = m.captured(1); p.name = m.captured(2); p.version = m.captured(3);
        p.installed = m.captured(4).contains("[installed");
        list.append(p);
    }
    return list;
}

QList<PackageStore::Pkg> PackageStore::parseInstalled(const QString &out) {
    QList<Pkg> list;
    for (const QString &line : out.split('\n', Qt::SkipEmptyParts)) {
        const QStringList f = line.split(' ', Qt::SkipEmptyParts);
        if (f.size() < 2) continue;
        Pkg p; p.name = f[0]; p.version = f[1]; p.installed = true;
        list.append(p);
    }
    return list;
}

QVariantMap PackageStore::parseInfo(const QString &out) {
    QVariantMap m;
    for (const QString &line : out.split('\n')) {
        const int c = line.indexOf(" : ");
        if (c < 0) continue;
        const QString k = line.left(c).trimmed(), v = line.mid(c + 3).trimmed();
        if (k == "Name") m["name"] = v;
        else if (k == "Version") m["version"] = v;
        else if (k == "Description") m["desc"] = v;
        else if (k == "URL") m["url"] = v;
        else if (k == "Installed Size" || k == "Download Size") m[k == "Installed Size" ? "size" : "download"] = v;
        else if (k == "Depends On") m["depends"] = v;
        else if (k == "Repository") m["repo"] = v;
    }
    return m;
}

QStringList PackageStore::sudoArgs(const QStringList &pacmanArgs) {
    return QStringList{"-S", "-p", "", "--", "pacman"} + pacmanArgs;
}

void PackageStore::setBusy(bool b) { if (b != m_busy) { m_busy = b; emit busyChanged(); } }

void PackageStore::runRead(const QStringList &args, std::function<void(const QString &)> done) {
    const QString exe = QStandardPaths::findExecutable("pacman");
    if (exe.isEmpty()) { done({}); return; }
    auto *p = new QProcess(this);
    const quint64 gen = ++m_gen;
    setBusy(true);
    connect(p, &QProcess::finished, this, [this, p, done, gen] {
        if (gen == m_gen) { done(QString::fromUtf8(p->readAllStandardOutput())); setBusy(false); }
        p->deleteLater();
    });
    p->start(exe, args);
}

void PackageStore::search(const QString &query) {
    if (query.trimmed().isEmpty()) { beginResetModel(); m_rows.clear(); endResetModel(); emit countChanged(); return; }
    runRead({"-Ss", "--", query.trimmed()}, [this](const QString &out) {
        beginResetModel(); m_rows = parseSearch(out); endResetModel(); emit countChanged();
    });
}

void PackageStore::listInstalled() {
    runRead({"-Qe"}, [this](const QString &out) {
        beginResetModel(); m_rows = parseInstalled(out); endResetModel(); emit countChanged();
    });
}

void PackageStore::showDetails(const QString &name) {
    runRead({"-Si", "--", name}, [this, name](const QString &out) {
        m_details = parseInfo(out);
        if (m_details.isEmpty()) {
            // instalado pero fuera de los repositorios: info local
            runRead({"-Qi", "--", name}, [this](const QString &o2) { m_details = parseInfo(o2); emit detailsChanged(); });
            return;
        }
        emit detailsChanged();
    });
}

void PackageStore::runPrivileged(const QStringList &pacmanArgs, const QString &password, const QString &action) {
    if (m_busy) return;
    const QString sudo = QStandardPaths::findExecutable("sudo");
    if (sudo.isEmpty()) { m_log = tr("sudo no está instalado"); emit logChanged(); emit finished(false, action); return; }
    m_log.clear(); emit logChanged();
    auto *p = new QProcess(this);
    p->setProcessChannelMode(QProcess::MergedChannels);
    setBusy(true);
    connect(p, &QProcess::readyRead, this, [this, p] {
        m_log += QString::fromUtf8(p->readAll());
        if (m_log.size() > 20000) m_log = m_log.right(15000);
        emit logChanged();
    });
    connect(p, &QProcess::finished, this, [this, p, action](int code) {
        const bool ok = code == 0;
        if (!ok && !m_log.contains("pacman") && m_log.contains("sudo")) m_log += "\n" + tr("Contraseña incorrecta");
        setBusy(false);
        emit logChanged();
        emit finished(ok, action);
        p->deleteLater();
    });
    p->start(sudo, sudoArgs(pacmanArgs));
    p->write(password.toUtf8() + "\n");
}

void PackageStore::install(const QString &name, const QString &password) {
    runPrivileged({"-S", "--noconfirm", "--needed", "--", name}, password, "install");
}
void PackageStore::remove(const QString &name, const QString &password) {
    runPrivileged({"-Rns", "--noconfirm", "--", name}, password, "remove");
}
void PackageStore::updateAll(const QString &password) {
    runPrivileged({"-Syu", "--noconfirm"}, password, "update");
}
