#include "swaycontrol.h"
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>

namespace {
void walk(const QJsonObject &n, bool inScratch, QVariantList &out) {
    const QString type = n.value("type").toString();
    const QJsonArray kids = n.value("nodes").toArray(), fkids = n.value("floating_nodes").toArray();
    const bool leaf = kids.isEmpty() && fkids.isEmpty();
    if ((type == "con" || type == "floating_con") && leaf && n.value("pid").toInt() > 0) {
        QString app = n.value("app_id").toString();
        if (app.isEmpty()) app = n.value("window_properties").toObject().value("class").toString();
        const QJsonObject deco = n.value("deco_rect").toObject();
        out.append(QVariantMap{{"id", n.value("id").toInt()}, {"appId", app}, {"title", n.value("name").toString()},
                               {"focused", n.value("focused").toBool()}, {"floating", type == "floating_con"},
                               {"minimized", inScratch}, {"pid", n.value("pid").toInt()},
                               {"fullscreen", n.value("fullscreen_mode").toInt() > 0},
                               // barra de título dibujada por sway (x, y, ancho, alto): ahí se colocan los botones de la ventana
                               {"decoX", deco.value("x").toInt()}, {"decoY", deco.value("y").toInt()},
                               {"decoW", deco.value("width").toInt()}, {"decoH", deco.value("height").toInt()}});
        return;
    }
    const bool scratch = inScratch || (type == "workspace" && n.value("name").toString() == "__i3_scratch");
    for (const QJsonValue &v : kids) walk(v.toObject(), scratch, out);
    for (const QJsonValue &v : fkids) walk(v.toObject(), scratch, out);
}
}  // namespace

QString SwayControl::modeFilePath() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + "/bc/layout-mode";
}

SwayControl::SwayControl(QObject *parent) : QObject(parent) {
    m_exe = QStandardPaths::findExecutable("swaymsg");
    m_available = !m_exe.isEmpty() && !qEnvironmentVariable("SWAYSOCK").isEmpty();
    readMode();
    const QString dir = QFileInfo(modeFilePath()).absolutePath();
    QDir().mkpath(dir);
    m_watch.addPath(dir);
    connect(&m_watch, &QFileSystemWatcher::directoryChanged, this, [this] { readMode(); });
    connect(&m_watch, &QFileSystemWatcher::fileChanged, this, [this] { readMode(); });
    if (!m_available) return;
    m_debounce.setSingleShot(true);
    m_debounce.setInterval(80);
    connect(&m_debounce, &QTimer::timeout, this, &SwayControl::refresh);
    m_poll.setInterval(10000);
    connect(&m_poll, &QTimer::timeout, this, &SwayControl::refresh);
    m_poll.start();
    connect(&m_events, &QProcess::readyReadStandardOutput, this, [this] { m_events.readAllStandardOutput(); m_debounce.start(); });
    connect(&m_events, &QProcess::finished, this, [this] {
        QTimer::singleShot(2000, this, [this] { m_events.start(m_exe, {"-t", "subscribe", "-m", "-r", "[\"window\",\"workspace\"]"}); });
    });
    m_events.start(m_exe, {"-t", "subscribe", "-m", "-r", "[\"window\",\"workspace\"]"});
    QTimer::singleShot(300, this, &SwayControl::refresh);
}

void SwayControl::readMode() {
    QFile f(modeFilePath());
    bool t = false;
    if (f.open(QIODevice::ReadOnly)) t = QString::fromUtf8(f.readAll()).trimmed() == "tiling";
    if (QFileInfo::exists(modeFilePath())) m_watch.addPath(modeFilePath());
    if (t != m_tiling) { m_tiling = t; emit tilingChanged(); }
}

QVariantList SwayControl::parseTree(const QByteArray &json) {
    QVariantList out;
    const QJsonObject root = QJsonDocument::fromJson(json).object();
    if (root.isEmpty()) return out;
    walk(root, false, out);
    return out;
}

void SwayControl::refresh() {
    if (!m_available || m_busy) return;
    m_busy = true;
    auto *p = new QProcess(this);
    connect(p, &QProcess::finished, this, [this, p](int code) {
        m_busy = false;
        if (code == 0) {
            const QVariantList w = parseTree(p->readAllStandardOutput());
            QStringList ids;
            int fid = -1;
            QString fapp, ftitle;
            for (const QVariant &v : w) {
                const QVariantMap m = v.toMap();
                if (!m.value("minimized").toBool()) ids << m.value("appId").toString();
                else ids << m.value("appId").toString();
                if (m.value("focused").toBool()) { fid = m.value("id").toInt(); fapp = m.value("appId").toString(); ftitle = m.value("title").toString(); }
            }
            QVariantList chrome;
            for (const QVariant &v : w) {
                const QVariantMap m = v.toMap();
                if (m.value("minimized").toBool() || m.value("fullscreen").toBool() || m.value("decoH").toInt() <= 0) continue;
                if (m.value("appId").toString().startsWith("bc-")) continue;   // las apps de BC llevan su propio semáforo
                chrome.append(QVariantMap{{"id", m.value("id")}, {"x", m.value("decoX")}, {"y", m.value("decoY")}, {"w", m.value("decoW")}, {"h", m.value("decoH")},
                                          {"focused", m.value("focused")}});
            }
            if (chrome != m_chrome) {
                m_chrome = chrome;
                m_poll.setInterval(m_chrome.isEmpty() ? 10000 : 600);   // con ventanas externas se sigue su posición para colocar los botones
                emit chromeChanged();
            }
            if (w != m_windows || fid != m_focusedId) {
                m_windows = w; m_appIds = ids; m_focusedId = fid; m_focusedApp = fapp; m_focusedTitle = ftitle;
                emit windowsChanged();
            }
        }
        p->deleteLater();
    });
    connect(p, &QProcess::errorOccurred, this, [this, p](QProcess::ProcessError e) {
        if (e != QProcess::FailedToStart) return;
        m_busy = false; p->deleteLater();
    });
    QTimer::singleShot(5000, p, [this, p] { if (p->state() != QProcess::NotRunning) { m_busy = false; p->kill(); } });
    p->start(m_exe, {"-t", "get_tree", "-r"});
}

void SwayControl::command(const QString &cmd) {
    if (!m_available) return;
    QProcess::startDetached(m_exe, {cmd});
    m_debounce.start();
}

void SwayControl::focusWindow(int id) { command(QString("[con_id=%1] focus").arg(id)); }
void SwayControl::closeWindow(int id) { command(QString("[con_id=%1] kill").arg(id)); }
void SwayControl::minimizeWindow(int id) { command(QString("[con_id=%1] move scratchpad").arg(id)); }
void SwayControl::toggleFullscreen(int id) { command(QString("[con_id=%1] fullscreen toggle").arg(id)); }

bool SwayControl::focusApp(const QString &appId) {
    for (const QVariant &v : m_windows) {
        const QVariantMap m = v.toMap();
        if (m.value("appId").toString() != appId) continue;
        if (m.value("minimized").toBool()) command(QString("[con_id=%1] scratchpad show").arg(m.value("id").toInt()));
        else focusWindow(m.value("id").toInt());
        return true;
    }
    return false;
}

void SwayControl::toggleTiling() {
    QProcess::startDetached(QStandardPaths::findExecutable("bc-wm-mode").isEmpty() ? QStringLiteral("bc-wm-mode") : QStandardPaths::findExecutable("bc-wm-mode"), {"toggle"});
}

void SwayControl::setTiling(bool on) {
    const QString exe = QStandardPaths::findExecutable("bc-wm-mode");
    QProcess::startDetached(exe.isEmpty() ? QStringLiteral("bc-wm-mode") : exe, {on ? "tiling" : "floating"});
}
