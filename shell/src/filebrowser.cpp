#include "filebrowser.h"
#include <QDir>
#include <QMimeDatabase>
#include <QStandardPaths>

FileBrowser::FileBrowser(QObject *parent) : QAbstractListModel(parent) {
    open(QDir::homePath());
}

QHash<int, QByteArray> FileBrowser::roleNames() const {
    return {{NameRole, "name"}, {PathRole, "filePath"}, {KindRole, "kind"}, {IsDirRole, "isDir"}};
}

QVariant FileBrowser::data(const QModelIndex &i, int role) const {
    if (!i.isValid() || i.row() >= m_items.size()) return {};
    const QFileInfo &fi = m_items.at(i.row());
    switch (role) {
    case NameRole: return fi.fileName();
    case PathRole: return fi.absoluteFilePath();
    case KindRole: return kindFor(fi);
    case IsDirRole: return fi.isDir();
    }
    return {};
}

QString FileBrowser::kindFor(const QFileInfo &fi) {
    if (fi.isDir()) return "carpeta";
    const QString mime = QMimeDatabase().mimeTypeForFile(fi, QMimeDatabase::MatchExtension).name();
    if (mime.startsWith("image/")) return "imagen";
    if (mime == "application/pdf") return "pdf";
    if (mime.startsWith("text/x-") || mime == "application/json" || mime == "text/markdown"
        || mime.contains("javascript") || mime.contains("xml") || mime.contains("shellscript")) return "codigo";
    if (mime.startsWith("text/")) return "texto";
    return "archivo";
}

bool FileBrowser::canUp() const { return !QDir(m_path).isRoot(); }

void FileBrowser::load(const QString &path) {
    m_path = QDir::cleanPath(path);
    QDir d(m_path);
    m_available = d.exists() && d.isReadable();
    beginResetModel();
    m_all.clear();
    if (m_available)
        m_all = d.entryInfoList(QDir::AllEntries | QDir::NoDotAndDotDot,
                                QDir::DirsFirst | QDir::IgnoreCase | QDir::Name);
    m_items.clear();
    for (const auto &fi : std::as_const(m_all))
        if (m_filter.isEmpty() || fi.fileName().contains(m_filter, Qt::CaseInsensitive)) m_items << fi;
    endResetModel();
    emit pathChanged();
    emit countChanged();
}

void FileBrowser::refilter() {
    beginResetModel();
    m_items.clear();
    for (const auto &fi : std::as_const(m_all))
        if (m_filter.isEmpty() || fi.fileName().contains(m_filter, Qt::CaseInsensitive)) m_items << fi;
    endResetModel();
    emit countChanged();
}

void FileBrowser::setFilter(const QString &f) {
    if (f == m_filter) return;
    m_filter = f;
    refilter();
    emit filterChanged();
}

void FileBrowser::open(const QString &path) {
    const QString clean = QDir::cleanPath(path);
    if (m_hpos >= 0 && m_history.value(m_hpos) == clean) return;
    m_history = m_history.mid(0, m_hpos + 1);
    m_history << clean;
    m_hpos = m_history.size() - 1;
    if (!m_filter.isEmpty()) { m_filter.clear(); emit filterChanged(); }
    load(clean);
    emit historyChanged();
}

void FileBrowser::activate(int row) {
    if (row < 0 || row >= m_items.size()) return;
    if (m_items.at(row).isDir()) open(m_items.at(row).absoluteFilePath());
}

void FileBrowser::back() {
    if (!canBack()) return;
    --m_hpos;
    load(m_history.at(m_hpos));
    emit historyChanged();
}

void FileBrowser::forward() {
    if (!canForward()) return;
    ++m_hpos;
    load(m_history.at(m_hpos));
    emit historyChanged();
}

void FileBrowser::up() {
    QDir d(m_path);
    if (d.cdUp()) open(d.absolutePath());
}

QString FileBrowser::placePath(const QString &n) const {
    using SL = QStandardPaths;
    if (n == "home") return QDir::homePath();
    SL::StandardLocation loc = n == "desktop" ? SL::DesktopLocation
        : n == "documents" ? SL::DocumentsLocation : n == "downloads" ? SL::DownloadLocation
        : n == "pictures" ? SL::PicturesLocation : n == "music" ? SL::MusicLocation : SL::HomeLocation;
    return SL::writableLocation(loc);
}

void FileBrowser::place(const QString &n) { open(placePath(n)); }

QVariantList FileBrowser::crumbs() const {
    QVariantList out;
    const QString home = QDir::homePath();
    QStringList parts;
    QString acc;
    if (m_path == home || m_path.startsWith(home + "/")) {
        out.push_back(QVariantMap{{"name", QString()}, {"path", home}, {"home", true}});
        parts = m_path.mid(home.size()).split('/', Qt::SkipEmptyParts);
        acc = home;
    } else {
        out.push_back(QVariantMap{{"name", QStringLiteral("/")}, {"path", "/"}, {"home", false}});
        parts = m_path.split('/', Qt::SkipEmptyParts);
    }
    for (const auto &p : parts) {
        acc += "/" + p;
        out.push_back(QVariantMap{{"name", p}, {"path", acc}, {"home", false}});
    }
    return out;
}
