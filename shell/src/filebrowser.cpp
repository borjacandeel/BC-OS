#include "filebrowser.h"
#include <QDateTime>
#include <cerrno>
#include <QProcess>
#include <QSaveFile>
#include <QUrl>
#include <QDir>
#include <QMimeDatabase>
#include <QStandardPaths>
#include <QLocale>
#include <sys/xattr.h>

FileBrowser::FileBrowser(QObject *parent) : QAbstractListModel(parent) {
    open(QDir::homePath());
}

QHash<int, QByteArray> FileBrowser::roleNames() const {
    return {{NameRole, "name"}, {PathRole, "filePath"}, {KindRole, "kind"}, {IsDirRole, "isDir"},
            {SizeRole, "sizeText"}, {ModifiedRole, "modifiedText"}, {TagsRole, "tags"}, {MimeRole, "mime"}};
}

QVariant FileBrowser::data(const QModelIndex &i, int role) const {
    if (!i.isValid() || i.row() >= m_items.size()) return {};
    const QFileInfo &fi = m_items.at(i.row());
    switch (role) {
    case NameRole: return fi.fileName();
    case PathRole: return fi.absoluteFilePath();
    case KindRole: return kindFor(fi);
    case IsDirRole: return fi.isDir();
    case SizeRole: return fi.isDir() ? QString("—") : QLocale(QLocale::Spanish).formattedDataSize(fi.size(), 1, QLocale::DataSizeSIFormat);
    case ModifiedRole: return QLocale(QLocale::Spanish).toString(fi.lastModified(), "d MMM yyyy, H:mm");
    case TagsRole: return tagsOf(fi.absoluteFilePath());
    case MimeRole: return QMimeDatabase().mimeTypeForFile(fi, QMimeDatabase::MatchExtension).comment();
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
        if ((m_filter.isEmpty() || fi.fileName().contains(m_filter, Qt::CaseInsensitive))
            && (m_tagFilter.isEmpty() || tagsOf(fi.absoluteFilePath()).contains(m_tagFilter))) m_items << fi;
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
    const QFileInfo &fi = m_items.at(row);
    if (fi.isDir()) { open(fi.absoluteFilePath()); return; }
    if (inTrash()) return;
    const QString xdg = QStandardPaths::findExecutable("xdg-open");
    if (xdg.isEmpty() || !QProcess::startDetached(xdg, {fi.absoluteFilePath()}))
        emit operationFailed(tr("No hay ninguna aplicación para abrir «%1»").arg(fi.fileName()));
}

namespace {
QString dataHome() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
}
QString uniqueName(const QDir &dir, const QString &name) {
    if (!dir.exists(name)) return name;
    const QFileInfo fi(name);
    const QString base = fi.completeBaseName().isEmpty() ? name : fi.completeBaseName();
    const QString ext = fi.suffix().isEmpty() ? QString() : "." + fi.suffix();
    for (int i = 2; i < 10000; ++i) {
        const QString c = QString("%1 %2%3").arg(base).arg(i).arg(ext);
        if (!dir.exists(c)) return c;
    }
    return name + "." + QString::number(QDateTime::currentMSecsSinceEpoch());
}
bool moveAny(const QString &from, const QString &to) {
    if (QDir().rename(from, to)) return true;
    return QProcess::execute("mv", {"--", from, to}) == 0;  // entre sistemas de archivos distintos
}
}  // namespace

QString FileBrowser::trashPath() const { return dataHome() + "/Trash/files"; }
bool FileBrowser::inTrash() const { return m_path == QDir::cleanPath(trashPath()); }
void FileBrowser::openTrash() { QDir().mkpath(trashPath()); QDir().mkpath(dataHome() + "/Trash/info"); open(trashPath()); }
QString FileBrowser::nameAt(int row) const { return row >= 0 && row < m_items.size() ? m_items.at(row).fileName() : QString(); }

bool FileBrowser::newFolder(const QString &name) {
    const QString n = name.trimmed();
    if (n.isEmpty() || n.contains('/')) { emit operationFailed(tr("Nombre no válido")); return false; }
    if (!QDir(m_path).mkdir(uniqueName(QDir(m_path), n))) { emit operationFailed(tr("No se pudo crear la carpeta")); return false; }
    reload();
    return true;
}

bool FileBrowser::renameAt(int row, const QString &newName) {
    if (row < 0 || row >= m_items.size()) return false;
    const QString n = newName.trimmed();
    if (n.isEmpty() || n.contains('/')) { emit operationFailed(tr("Nombre no válido")); return false; }
    const QFileInfo fi = m_items.at(row);
    if (n == fi.fileName()) return true;
    if (QFileInfo::exists(fi.absolutePath() + "/" + n)) { emit operationFailed(tr("Ya existe un elemento con ese nombre")); return false; }
    if (!QDir().rename(fi.absoluteFilePath(), fi.absolutePath() + "/" + n)) { emit operationFailed(tr("No se pudo cambiar el nombre")); return false; }
    reload();
    return true;
}

bool FileBrowser::trashAt(int row) {
    if (row < 0 || row >= m_items.size() || inTrash()) return false;
    const QFileInfo fi = m_items.at(row);
    const QDir files(trashPath()), info(dataHome() + "/Trash/info");
    QDir().mkpath(files.path());
    QDir().mkpath(info.path());
    const QString name = uniqueName(files, fi.fileName());
    QSaveFile f(info.filePath(name + ".trashinfo"));
    if (!f.open(QIODevice::WriteOnly)) { emit operationFailed(tr("No se pudo usar la papelera")); return false; }
    f.write("[Trash Info]\nPath=" + QUrl::toPercentEncoding(fi.absoluteFilePath(), "/") + "\nDeletionDate="
            + QDateTime::currentDateTime().toString("yyyy-MM-ddThh:mm:ss").toUtf8() + "\n");
    if (!f.commit()) return false;
    if (!moveAny(fi.absoluteFilePath(), files.filePath(name))) {
        QFile::remove(info.filePath(name + ".trashinfo"));
        emit operationFailed(tr("No se pudo mover a la papelera"));
        return false;
    }
    reload();
    return true;
}

bool FileBrowser::restoreAt(int row) {
    if (row < 0 || row >= m_items.size() || !inTrash()) return false;
    const QString name = m_items.at(row).fileName();
    const QString infoPath = dataHome() + "/Trash/info/" + name + ".trashinfo";
    QFile f(infoPath);
    QString orig;
    if (f.open(QIODevice::ReadOnly)) {
        for (const QString &l : QString::fromUtf8(f.readAll()).split('\n'))
            if (l.startsWith("Path=")) orig = QUrl::fromPercentEncoding(l.mid(5).toUtf8());
    }
    if (orig.isEmpty()) orig = QDir::homePath() + "/" + name;
    const QFileInfo target(orig);
    QDir().mkpath(target.absolutePath());
    const QString dest = target.absolutePath() + "/" + uniqueName(QDir(target.absolutePath()), target.fileName());
    if (!moveAny(m_items.at(row).absoluteFilePath(), dest)) { emit operationFailed(tr("No se pudo restaurar")); return false; }
    QFile::remove(infoPath);
    reload();
    return true;
}

bool FileBrowser::deleteAt(int row) {
    if (row < 0 || row >= m_items.size() || !inTrash()) return false;
    const QFileInfo fi = m_items.at(row);
    const bool ok = fi.isDir() && !fi.isSymLink() ? QDir(fi.absoluteFilePath()).removeRecursively() : QFile::remove(fi.absoluteFilePath());
    if (!ok) { emit operationFailed(tr("No se pudo eliminar")); return false; }
    QFile::remove(dataHome() + "/Trash/info/" + fi.fileName() + ".trashinfo");
    reload();
    return true;
}

bool FileBrowser::emptyTrash() {
    const QDir files(trashPath()), info(dataHome() + "/Trash/info");
    bool ok = true;
    for (const QFileInfo &fi : files.entryInfoList(QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden | QDir::System))
        ok &= fi.isDir() && !fi.isSymLink() ? QDir(fi.absoluteFilePath()).removeRecursively() : QFile::remove(fi.absoluteFilePath());
    for (const QFileInfo &fi : info.entryInfoList(QDir::Files)) QFile::remove(fi.absoluteFilePath());
    if (!ok) emit operationFailed(tr("No se pudo vaciar la papelera"));
    if (inTrash()) reload();
    return ok;
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

QStringList FileBrowser::tagsOf(const QString &path) {
    char buf[512];
    const QByteArray p = QFile::encodeName(path);
    const ssize_t n = getxattr(p.constData(), "user.xdg.tags", buf, sizeof(buf) - 1);
    if (n <= 0) return {};
    return QString::fromUtf8(buf, int(n)).split(',', Qt::SkipEmptyParts);
}
bool FileBrowser::setTag(int row, const QString &color) {
    static const QStringList ok{"rojo", "naranja", "amarillo", "verde", "azul", "morado", "gris"};
    if (row < 0 || row >= m_items.size() || (!color.isEmpty() && !ok.contains(color))) return false;
    const QByteArray p = QFile::encodeName(m_items.at(row).absoluteFilePath());
    QStringList t = tagsOf(m_items.at(row).absoluteFilePath());
    if (color.isEmpty()) t.clear(); else if (t.contains(color)) t.removeAll(color); else t << color;
    int r = t.isEmpty() ? removexattr(p.constData(), "user.xdg.tags") : setxattr(p.constData(), "user.xdg.tags", t.join(',').toUtf8().constData(), t.join(',').toUtf8().size(), 0);
    if (r != 0 && !(t.isEmpty() && errno == ENODATA)) { emit operationFailed(tr("Este sistema de archivos no admite etiquetas")); return false; }
    emit dataChanged(index(row), index(row), {TagsRole});
    return true;
}
void FileBrowser::setTagFilter(const QString &color) { m_tagFilter = color; load(m_path); }
QString FileBrowser::textPreview(const QString &path, int maxBytes) const {
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) return {};
    const QByteArray b = f.read(qBound(256, maxBytes, 200000));
    if (b.contains('\0')) return {};
    return QString::fromUtf8(b);
}
QVariantMap FileBrowser::infoAt(int row) const {
    if (row < 0 || row >= m_items.size()) return {};
    const QFileInfo &fi = m_items.at(row);
    return {{"name", fi.fileName()}, {"path", fi.absoluteFilePath()}, {"kind", kindFor(fi)}, {"isDir", fi.isDir()},
            {"size", data(index(row), SizeRole)}, {"modified", data(index(row), ModifiedRole)}, {"mime", data(index(row), MimeRole)}};
}
