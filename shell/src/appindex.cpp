#include "appindex.h"
#include <QFileInfo>
#include <QRegularExpression>
#include <QDir>
#include <QFile>
#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>
#include <algorithm>

AppIndex::AppIndex(const QStringList &dirs, const QString &lang, QObject *parent) : QObject(parent), m_dirs(dirs), m_lang(lang) {
    // BC_APPS_DIRS (separadas por «:») sustituye a las carpetas estándar: capturas y pruebas reproducibles
    if (m_dirs.isEmpty() && !qEnvironmentVariable("BC_APPS_DIRS").isEmpty())
        m_dirs = qEnvironmentVariable("BC_APPS_DIRS").split(':', Qt::SkipEmptyParts);
    if (m_dirs.isEmpty()) {
        m_dirs << "/usr/share/applications" << "/usr/local/share/applications"
               << QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/applications";
    }
    if (m_lang.isEmpty()) m_lang = qEnvironmentVariable("LANG", "es_ES").section('.', 0, 0);
    reload();
}

bool AppIndex::parseDesktop(const QString &text, const QString &lang, Entry &out) {
    bool inEntry = false, noDisplay = false, hidden = false, isApp = false;
    QString name, localized, exec, icon, comment;
    const QString l2 = lang.section('_', 0, 0);
    for (const QString &raw : text.split('\n')) {
        const QString line = raw.trimmed();
        if (line.startsWith('[')) { inEntry = line == "[Desktop Entry]"; continue; }
        if (!inEntry || line.isEmpty() || line.startsWith('#')) continue;
        const int eq = line.indexOf('=');
        if (eq < 0) continue;
        const QString k = line.left(eq).trimmed(), v = line.mid(eq + 1).trimmed();
        if (k == "Type") isApp = v == "Application";
        else if (k == "Name") name = v;
        else if (k == "Name[" + lang + "]" || (localized.isEmpty() && k == "Name[" + l2 + "]")) localized = v;
        else if (k == "Exec") exec = v;
        else if (k == "Icon") icon = v;
        else if (k == "Comment") comment = v;
        else if (k == "NoDisplay") noDisplay = v == "true";
        else if (k == "Hidden") hidden = v == "true";
        else if (k == "Terminal") out.terminal = v == "true";
        else if (k == "Categories") out.category = categoryFor(v);
    }
    if (!isApp || noDisplay || hidden || exec.isEmpty()) return false;
    out.name = localized.isEmpty() ? name : localized;
    if (out.name.isEmpty()) return false;
    out.exec = exec; out.icon = icon; out.comment = comment;
    return true;
}

QStringList AppIndex::commandFor(const QString &exec, bool terminal) {
    static const QRegularExpression codes("%[fFuUdDnNickvm]");
    QString e = exec;
    e.replace("%%", "\x01");
    e.remove(codes);
    e.replace("\x01", "%");
    QStringList args = QProcess::splitCommand(e.simplified());
    if (terminal && !args.isEmpty()) args = QStringList{"bc-terminal", "-e"} + args;
    return args;
}

void AppIndex::reload() {
    m_entries.clear();
    QHash<QString, Entry> byId;
    for (const QString &dir : m_dirs) {
        const QDir d(dir);
        for (const QString &f : d.entryList({"*.desktop"}, QDir::Files)) {
            QFile file(d.filePath(f));
            if (!file.open(QIODevice::ReadOnly)) continue;
            if (isHiddenId(f)) continue;
            Entry e;
            if (!parseDesktop(QString::fromUtf8(file.readAll()), m_lang, e)) { byId.remove(f); continue; }
            e.id = f;
            byId.insert(f, e);  // la ruta posterior (usuario) pisa a la del sistema
        }
    }
    m_entries = byId.values();
    std::sort(m_entries.begin(), m_entries.end(), [](const Entry &a, const Entry &b) { return a.name.compare(b.name, Qt::CaseInsensitive) < 0; });
    emit changed();
}

bool AppIndex::isHiddenId(const QString &id) {
    // Herramientas de desarrollo y variantes técnicas que no deben aparecer en el lanzador del usuario.
    static const QStringList prefixes{"cmake", "assistant", "designer", "linguist", "qdbusviewer", "qv4l", "foot-server", "footclient",
                                      "foot.desktop", "Alacritty", "com.mitchellh.ghostty", "avahi", "bssh", "bvnc", "qt6ct", "qtcreator", "org.freedesktop.IBus", "nm-"};
    for (const QString &p : prefixes) if (id.startsWith(p)) return true;
    return false;
}

QString AppIndex::resolveIcon(const QString &name, const QStringList &rootsIn) {
    if (name.isEmpty()) return {};
    if (name.startsWith('/')) return QFileInfo(name).isFile() ? name : QString();
    static const QRegularExpression ok("^[A-Za-z0-9._+-]+$");
    if (!ok.match(name).hasMatch()) return {};   // nada de «..» ni separadores
    QStringList roots = rootsIn;
    static const QString theme = qEnvironmentVariable("BC_ICON_THEME_DIR", "/usr/share/icons/MacOS-Like-Dark");
    if (roots.isEmpty()) roots = {theme + "/apps/scalable", "/usr/share/icons/Qogir/scalable/apps", "/usr/share/icons/hicolor/scalable/apps",
                                  "/usr/share/icons/hicolor/256x256/apps", "/usr/share/icons/hicolor/128x128/apps",
                                  "/usr/share/icons/hicolor/64x64/apps", "/usr/share/icons/hicolor/48x48/apps", "/usr/share/pixmaps"};
    for (const QString &r : roots)
        for (const char *ext : {".svg", ".png"}) {
            const QString p = r + '/' + name + ext;
            if (QFileInfo(p).isFile()) return p;
        }
    return {};
}

QVariantList AppIndex::search(const QString &query) const {
    const QString q = query.trimmed();
    QVariantList out;
    struct Scored { int score; const Entry *e; };
    QList<Scored> hits;
    for (const Entry &e : m_entries) {
        int s = 0;
        if (q.isEmpty()) s = 1;
        else if (e.name.startsWith(q, Qt::CaseInsensitive)) s = 100;
        else if (e.name.contains(" " + q, Qt::CaseInsensitive)) s = 70;
        else if (e.name.contains(q, Qt::CaseInsensitive)) s = 50;
        else if (e.comment.contains(q, Qt::CaseInsensitive) || e.exec.contains(q, Qt::CaseInsensitive)) s = 20;
        if (s > 0) hits.append({s, &e});
    }
    std::stable_sort(hits.begin(), hits.end(), [](const Scored &a, const Scored &b) { return a.score > b.score; });
    for (const Scored &h : hits)
        out.append(QVariantMap{{"id", h.e->id}, {"name", h.e->name}, {"icon", h.e->icon}, {"comment", h.e->comment},
                               {"iconPath", resolveIcon(h.e->icon)}, {"category", h.e->category}});
    return out;
}

bool AppIndex::launch(const QString &id) {
    for (const Entry &e : m_entries) {
        if (e.id != id) continue;
        const QStringList a = commandFor(e.exec, e.terminal);
        if (a.isEmpty()) return false;
        const QString exe = QStandardPaths::findExecutable(a.first());
        return QProcess::startDetached(exe.isEmpty() ? a.first() : exe, a.mid(1));
    }
    return false;
}

QVariantMap AppIndex::infoFor(const QString &appId) const {
    if (appId.isEmpty()) return {};
    QString a = appId.toLower();
    // Las terminales reales (ocultas en el lanzador) se presentan como «Terminal» de BC
    if (a == "com.mitchellh.ghostty" || a == "alacritty" || a == "foot") a = "bc-terminal";
    for (const Entry &e : m_entries) {
        const QString id = e.id.toLower();
        const QString prog = commandFor(e.exec, false).value(0).section('/', -1).toLower();
        if (id == a || id.endsWith("." + a) || a.endsWith("." + id) || prog == a)
            return {{"id", e.id}, {"name", e.name}, {"icon", e.icon}, {"iconPath", resolveIcon(e.icon)}};
    }
    return {};
}

QString AppIndex::categoryFor(const QString &cats) {
    const QStringList c = cats.split(';', Qt::SkipEmptyParts);
    auto has = [&](std::initializer_list<const char *> l) { for (const char *x : l) if (c.contains(QLatin1String(x))) return true; return false; };
    if (has({"Game"})) return "juegos";
    if (has({"Graphics", "AudioVideo", "Audio", "Video", "Photography"})) return "creatividad";
    if (has({"Office", "Calendar", "TextEditor", "WordProcessor", "Spreadsheet"})) return "productividad";
    if (has({"Network", "WebBrowser", "Email", "Chat"})) return "internet";
    if (has({"Development", "IDE"})) return "desarrollo";
    if (has({"Settings", "System", "Monitor", "PackageManager", "TerminalEmulator", "FileManager"})) return "sistema";
    return "utilidades";
}
