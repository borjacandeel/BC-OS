#include "swaycontrol.h"
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>
#include <QRegularExpression>

namespace {
void walk(const QJsonObject &n, bool inScratch, QVariantList &out, const QString &ws = QString(), const QString &outName = QString()) {
    const QString type = n.value("type").toString();
    const QJsonArray kids = n.value("nodes").toArray(), fkids = n.value("floating_nodes").toArray();
    const bool leaf = kids.isEmpty() && fkids.isEmpty();
    if ((type == "con" || type == "floating_con") && leaf && n.value("pid").toInt() > 0) {
        QString app = n.value("app_id").toString();
        if (app.isEmpty()) app = n.value("window_properties").toObject().value("class").toString();
        // deco_rect es relativo al contenedor padre; rect es absoluto pero (como en i3) empieza DEBAJO de la barra de título
        const QJsonObject deco = n.value("deco_rect").toObject(), rect = n.value("rect").toObject();
        out.append(QVariantMap{{"id", n.value("id").toInt()}, {"appId", app}, {"title", n.value("name").toString()},
                               {"focused", n.value("focused").toBool()}, {"floating", type == "floating_con"},
                               {"minimized", inScratch}, {"pid", n.value("pid").toInt()},
                               {"fullscreen", n.value("fullscreen_mode").toInt() > 0},
                               // barra de título dibujada por sway (x, y, ancho, alto): ahí se colocan los botones de la ventana
                               {"decoX", rect.value("x").toInt()}, {"decoY", rect.value("y").toInt() - deco.value("height").toInt()},
                               {"decoW", deco.value("width").toInt()}, {"decoH", deco.value("height").toInt()},
                               {"workspace", ws}, {"output", outName},
                               {"rectW", rect.value("width").toInt()}, {"rectH", rect.value("height").toInt() + deco.value("height").toInt()}});
        return;
    }
    const bool scratch = inScratch || (type == "workspace" && n.value("name").toString() == "__i3_scratch");
    const QString w = type == "workspace" ? n.value("name").toString() : ws;
    const QString o = type == "output" ? n.value("name").toString() : outName;
    for (const QJsonValue &v : kids) walk(v.toObject(), scratch, out, w, o);
    for (const QJsonValue &v : fkids) walk(v.toObject(), scratch, out, w, o);
}
}  // namespace

QString SwayControl::modeFilePath() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + "/bc/layout-mode";
}

SwayControl::SwayControl(QObject *parent) : QObject(parent) {
    // Hyprland (animaciones fluidas con GPU) o sway (por software): misma interfaz para el QML
    m_hypr = !qEnvironmentVariable("HYPRLAND_INSTANCE_SIGNATURE").isEmpty();
    m_exe = QStandardPaths::findExecutable(m_hypr ? "hyprctl" : "swaymsg");
    m_available = !m_exe.isEmpty() && (m_hypr || !qEnvironmentVariable("SWAYSOCK").isEmpty());
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
    if (m_hypr) { hyprConnect(); QTimer::singleShot(300, this, &SwayControl::refresh); return; }
    m_events.setProcessChannelMode(QProcess::SeparateChannels);
    connect(&m_events, &QProcess::readyReadStandardOutput, this, [this] { m_events.readAllStandardOutput(); m_debounce.start(); });
    connect(&m_events, &QProcess::finished, this, [this] {
        QTimer::singleShot(2000, this, [this] { m_events.start(m_exe, {"-t", "subscribe", "-m", "-r", "[\"window\",\"workspace\",\"input\"]"}); });
    });
    m_events.start(m_exe, {"-t", "subscribe", "-m", "-r", "[\"window\",\"workspace\",\"input\"]"});
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
    if (m_hypr) { refreshHypr(); return; }
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
                                          {"rw", m.value("rectW")}, {"rh", m.value("rectH")}, {"focused", m.value("focused")}});
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
    query("get_workspaces", [this](const QByteArray &j) {
        const QVariantList ws = parseWorkspaces(j);
        if (ws != m_workspaces) { m_workspaces = ws; emit workspacesChanged(); }
    });
    if (++m_inputTick % 6 == 1) query("get_inputs", [this](const QByteArray &j) {
        const QString l = parseLayout(j);
        if (l != m_layout) { m_layout = l; emit layoutChanged(); }
    });
}

void SwayControl::query(const QString &type, std::function<void(const QByteArray &)> done) {
    auto *q = new QProcess(this);
    connect(q, &QProcess::finished, this, [q, done](int code) { if (code == 0) done(q->readAllStandardOutput()); q->deleteLater(); });
    connect(q, &QProcess::errorOccurred, q, [q](QProcess::ProcessError e) { if (e == QProcess::FailedToStart) q->deleteLater(); });
    q->start(m_exe, {"-t", type, "-r"});
}

QVariantList SwayControl::parseWorkspaces(const QByteArray &json) {
    QVariantList out;
    for (const QJsonValue &v : QJsonDocument::fromJson(json).array()) {
        const QJsonObject o = v.toObject();
        const QJsonObject r = o.value("rect").toObject();
        out.append(QVariantMap{{"num", o.value("num").toInt()}, {"name", o.value("name").toString()}, {"focused", o.value("focused").toBool()},
                               {"visible", o.value("visible").toBool()}, {"output", o.value("output").toString()},
                               {"x", r.value("x").toInt()}, {"y", r.value("y").toInt()}, {"w", r.value("width").toInt()}, {"h", r.value("height").toInt()}});
    }
    return out;
}

// Fuente de entrada activa en abreviatura de dos letras («ES», «EN»…) como en la barra de macOS
QString SwayControl::parseLayout(const QByteArray &json) {
    for (const QJsonValue &v : QJsonDocument::fromJson(json).array()) {
        const QJsonObject o = v.toObject();
        if (o.value("type").toString() != "keyboard") continue;
        const QString name = o.value("xkb_active_layout_name").toString();
        if (name.isEmpty()) continue;
        static const QMap<QString, QString> map{{"Spanish", "ES"}, {"English", "EN"}, {"French", "FR"}, {"German", "DE"},
                                                 {"Portuguese", "PT"}, {"Italian", "IT"}, {"Catalan", "CA"}};
        for (auto it = map.cbegin(); it != map.cend(); ++it) if (name.startsWith(it.key())) return it.value();
        return name.left(2).toUpper();
    }
    return QString();
}

void SwayControl::switchWorkspace(const QString &name) { command("workspace \"" + QString(name).remove('"') + "\""); }
void SwayControl::moveToWorkspace(int id, const QString &name) { command(QString("[con_id=%1] move container to workspace \"%2\"").arg(id).arg(QString(name).remove('"'))); }

bool SwayControl::sendIpc(const QString &cmd) {
    const QString sock = qEnvironmentVariable("SWAYSOCK");
    if (sock.isEmpty()) return false;
    if (m_ipc.state() != QLocalSocket::ConnectedState) {
        m_ipc.connectToServer(sock);
        if (!m_ipc.waitForConnected(150)) return false;
        connect(&m_ipc, &QLocalSocket::readyRead, &m_ipc, [this] { m_ipc.readAll(); }, Qt::UniqueConnection);
    }
    const QByteArray payload = cmd.toUtf8();
    QByteArray msg("i3-ipc");
    const quint32 len = quint32(payload.size()), type = 0;   // RUN_COMMAND
    msg.append(reinterpret_cast<const char *>(&len), 4);
    msg.append(reinterpret_cast<const char *>(&type), 4);
    msg.append(payload);
    return m_ipc.write(msg) == msg.size() && m_ipc.flush();
}

void SwayControl::command(const QString &cmd) {
    if (!m_available) return;
    if (m_hypr) {
        const QStringList d = translateToHyprland(cmd, m_addr, m_activeWs);
        if (!d.isEmpty()) QProcess::startDetached(m_exe, {"eval", d.join("; ")});
        m_debounce.start();
        return;
    }
    if (!sendIpc(cmd)) QProcess::startDetached(m_exe, {cmd});
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

// ---------------------------------------------------------------------------------------------
// Hyprland
void SwayControl::hyprConnect() {
    const QString sig = qEnvironmentVariable("HYPRLAND_INSTANCE_SIGNATURE");
    QString rt = qEnvironmentVariable("XDG_RUNTIME_DIR");
    QString path = rt + "/hypr/" + sig + "/.socket2.sock";
    if (!QFileInfo::exists(path)) path = "/tmp/hypr/" + sig + "/.socket2.sock";
    connect(&m_hyprEvents, &QLocalSocket::readyRead, this, [this] {
        const QByteArray d = m_hyprEvents.readAll();
        // workspace, openwindow, closewindow, movewindow, activewindow, fullscreen, changefloatingmode, activelayout…
        // Ventana nueva = ventana activa SIEMPRE (como macOS): foco de teclado y delante, aunque el teclado lo tuviera
        // la barra, el Dock o un menú al abrirse (antes había que hacer clic en ella para poder escribir)
        for (const QByteArray &line : d.split('\n')) {
            if (!line.startsWith("openwindow>>")) continue;
            const QList<QByteArray> f = line.mid(12).split(',');
            if (f.size() < 2 || f.at(1).startsWith("special")) continue;   // minimizadas (escritorio especial): no
            const QString target = "address:0x" + QString::fromLatin1(f.at(0));
            const QString lua = "hl.dispatch(hl.dsp.focus({ window = \"" + target + "\" })); "
                                "hl.dispatch(hl.dsp.window.alter_zorder({ mode = \"top\", window = \"" + target + "\" }))";
            QTimer::singleShot(40, this, [this, lua] { QProcess::startDetached(m_exe, {"eval", lua}); });
        }
        if (!d.isEmpty()) m_debounce.start();
    });
    connect(&m_hyprEvents, &QLocalSocket::disconnected, this, [this, path] {
        QTimer::singleShot(2000, this, [this, path] { m_hyprEvents.connectToServer(path); });
    });
    m_debounce.setSingleShot(true);
    m_debounce.setInterval(60);
    connect(&m_debounce, &QTimer::timeout, this, &SwayControl::refresh, Qt::UniqueConnection);
    m_hyprEvents.connectToServer(path);
}

QVariantList SwayControl::parseHyprClients(const QByteArray &clients, QHash<int, QString> *addr) {
    QVariantList out;
    for (const QJsonValue &v : QJsonDocument::fromJson(clients).array()) {
        const QJsonObject o = v.toObject();
        if (!o.value("mapped").toBool(true)) continue;
        const QString a = o.value("address").toString();
        bool ok = false;
        const qulonglong n = a.mid(2).toULongLong(&ok, 16);
        const int id = ok ? int(n & 0x7fffffff) : -1;
        if (addr) addr->insert(id, a);
        const QJsonArray at = o.value("at").toArray(), size = o.value("size").toArray();
        const QJsonObject ws = o.value("workspace").toObject();
        const QString wsName = ws.value("name").toString();
        const QJsonValue fs = o.value("fullscreen");
        QString app = o.value("class").toString();
        if (app.isEmpty()) app = o.value("initialClass").toString();
        out.append(QVariantMap{{"id", id}, {"appId", app}, {"title", o.value("title").toString()},
                               {"focused", o.value("focusHistoryID").toInt(-1) == 0}, {"floating", o.value("floating").toBool()},
                               {"minimized", wsName.startsWith("special:minimized")}, {"pid", o.value("pid").toInt()},
                               {"fullscreen", fs.isBool() ? fs.toBool() : fs.toInt() > 0},
                               // Sin barra de título del compositor: las apps dibujan la suya (CSD)
                               {"decoX", at.at(0).toInt()}, {"decoY", at.at(1).toInt()}, {"decoW", size.at(0).toInt()}, {"decoH", 0},
                               {"workspace", wsName.startsWith("special:") ? QStringLiteral("__i3_scratch") : wsName},
                               {"output", o.value("monitor").toVariant().toString()},
                               {"rectW", size.at(0).toInt()}, {"rectH", size.at(1).toInt()}});
    }
    return out;
}

void SwayControl::refreshHypr() {
    if (!m_available || m_busy) return;
    m_busy = true;
    auto *p = new QProcess(this);
    connect(p, &QProcess::finished, this, [this, p](int code) {
        m_busy = false;
        if (code == 0) {
            QHash<int, QString> addr;
            const QVariantList w = parseHyprClients(p->readAllStandardOutput(), &addr);
            m_addr = addr;
            QStringList ids; int fid = -1; QString fapp, ftitle;
            for (const QVariant &v : w) {
                const QVariantMap m = v.toMap();
                ids << m.value("appId").toString();
                if (m.value("focused").toBool() && !m.value("minimized").toBool()) { fid = m.value("id").toInt(); fapp = m.value("appId").toString(); ftitle = m.value("title").toString(); }
            }
            if (w != m_windows || fid != m_focusedId) {
                m_windows = w; m_appIds = ids; m_focusedId = fid; m_focusedApp = fapp; m_focusedTitle = ftitle;
                emit windowsChanged();
            }
            if (!m_chrome.isEmpty()) { m_chrome.clear(); emit chromeChanged(); }
        }
        p->deleteLater();
    });
    connect(p, &QProcess::errorOccurred, this, [this, p](QProcess::ProcessError e) { if (e == QProcess::FailedToStart) { m_busy = false; p->deleteLater(); } });
    p->start(m_exe, {"-j", "clients"});
    auto *q = new QProcess(this);
    connect(q, &QProcess::finished, this, [this, q](int code) {
        if (code == 0) {
            const QJsonArray mons = QJsonDocument::fromJson(q->property("mons").toByteArray()).array();
            QStringList visible; QString focusedMon;
            for (const QJsonValue &m : mons) {
                const QJsonObject o = m.toObject();
                visible << o.value("activeWorkspace").toObject().value("name").toString();
                if (o.value("focused").toBool()) { focusedMon = o.value("name").toString(); m_activeWs = o.value("activeWorkspace").toObject().value("name").toString(); }
            }
            QVariantList ws;
            for (const QJsonValue &v : QJsonDocument::fromJson(q->readAllStandardOutput()).array()) {
                const QJsonObject o = v.toObject();
                const QString name = o.value("name").toString();
                if (name.startsWith("special:")) continue;
                ws.append(QVariantMap{{"num", o.value("id").toInt()}, {"name", name}, {"focused", name == m_activeWs},
                                      {"visible", visible.contains(name)}, {"output", o.value("monitor").toString()},
                                      {"x", 0}, {"y", 0}, {"w", 0}, {"h", 0}});
            }
            std::sort(ws.begin(), ws.end(), [](const QVariant &a, const QVariant &b) { return a.toMap().value("num").toInt() < b.toMap().value("num").toInt(); });
            if (ws != m_workspaces) { m_workspaces = ws; emit workspacesChanged(); }
        }
        q->deleteLater();
    });
    // Monitores primero (escritorio visible de cada pantalla) y luego escritorios
    auto *m = new QProcess(this);
    connect(m, &QProcess::finished, this, [this, m, q](int) { q->setProperty("mons", m->readAllStandardOutput()); q->start(m_exe, {"-j", "workspaces"}); m->deleteLater(); });
    m->start(m_exe, {"-j", "monitors"});
    if (++m_inputTick % 6 == 1) {
        auto *d = new QProcess(this);
        connect(d, &QProcess::finished, this, [this, d](int code) {
            if (code == 0) {
                const QJsonArray kbs = QJsonDocument::fromJson(d->readAllStandardOutput()).object().value("keyboards").toArray();
                QString name;
                for (const QJsonValue &k : kbs) if (k.toObject().value("main").toBool()) name = k.toObject().value("active_keymap").toString();
                if (name.isEmpty() && !kbs.isEmpty()) name = kbs.first().toObject().value("active_keymap").toString();
                static const QMap<QString, QString> map{{"Spanish", "ES"}, {"English", "EN"}, {"French", "FR"}, {"German", "DE"}, {"Portuguese", "PT"}, {"Italian", "IT"}};
                QString l = name.left(2).toUpper();
                for (auto it = map.cbegin(); it != map.cend(); ++it) if (name.startsWith(it.key())) l = it.value();
                if (!name.isEmpty() && l != m_layout) { m_layout = l; emit layoutChanged(); }
            }
            d->deleteLater();
        });
        d->start(m_exe, {"-j", "devices"});
    }
}

// Órdenes de sway que usa BC Shell → llamadas Lua de Hyprland 0.57+ (hyprctl eval "hl.dispatch(…)")
static QString luaStr(const QString &s) { return "[==[" + QString(s).remove("]==]") + "]==]"; }
QStringList SwayControl::translateToHyprland(const QString &swayCmd, const QHash<int, QString> &addr, const QString &activeWs) {
    QString cmd = swayCmd.trimmed();
    QString target;   // selector de ventana de Hyprland: «address:0x…» o «class:…»
    static const QRegularExpression crit("^\\[(con_id|app_id)=\"?([^\"\\]]+)\"?\\]\\s*");
    const auto m = crit.match(cmd);
    if (m.hasMatch()) {
        if (m.captured(1) == "con_id") { const QString a = addr.value(m.captured(2).toInt()); if (a.isEmpty()) return {}; target = "address:" + a; }
        else target = "class:^(" + m.captured(2) + ")$";
        cmd = cmd.mid(m.capturedLength());
    }
    const QString w = target.isEmpty() ? QString() : ", window = " + luaStr(target);
    auto d = [](const QString &expr) { return "hl.dispatch(" + expr + ")"; };
    auto ws = [](const QString &n) { bool num = false; n.toInt(&num); return num ? n : luaStr(n); };
    if (cmd.startsWith("exec ")) {
        const QString e = cmd.mid(5).trimmed();
        if (e.startsWith("swaymsg")) return {};   // órdenes internas de sway: aquí no aplican
        return {d("hl.dsp.exec_cmd(" + luaStr(e) + ")")};
    }
    if (cmd.startsWith("output ") && cmd.contains(" bg ")) {
        static const QRegularExpression bg("bg \"([^\"]+)\"");
        const auto b = bg.match(cmd);
        if (b.hasMatch()) return {d("hl.dsp.exec_cmd(" + luaStr("sh -c 'pkill -x swaybg; exec swaybg -m fill -i \"" + b.captured(1) + "\"'") + ")")};
        return {};
    }
    static const QRegularExpression wsRe("^workspace (?:number )?\"?([^\"]+)\"?$");
    const auto wm = wsRe.match(cmd);
    if (wm.hasMatch()) {
        QString n = wm.captured(1);
        if (n == "next" || n == "next_on_output") n = "m+1";
        else if (n == "prev" || n == "prev_on_output") n = "m-1";
        return {d("hl.dsp.focus({ workspace = " + ws(n) + " })")};
    }
    QStringList out;
    for (QString part : cmd.split(',', Qt::SkipEmptyParts)) {
        part = part.trimmed();
        QRegularExpressionMatch r;
        // Enfocar y traer delante: con ventanas flotantes (las de BC OS) Hyprland enfocaba la ventana pero la dejaba
        // detrás de las otras, y el Dock / Alt+Tab parecían no cambiar de app
        if (part == "focus") { if (!target.isEmpty()) out << d("hl.dsp.focus({ window = " + luaStr(target) + " })")
                                                          << d("hl.dsp.window.alter_zorder({ mode = \"top\", window = " + luaStr(target) + " })"); }
        else if (part == "kill") out << d("hl.dsp.window.close(" + (target.isEmpty() ? QString() : "{ window = " + luaStr(target) + " }") + ")");
        else if (part == "move scratchpad") out << d("hl.dsp.window.move({ workspace = \"special:minimized\"" + w + " })");
        else if (part == "scratchpad show") {
            out << d("hl.dsp.window.move({ workspace = " + ws(activeWs) + w + " })");
            if (!target.isEmpty()) out << d("hl.dsp.focus({ window = " + luaStr(target) + " })")
                                       << d("hl.dsp.window.alter_zorder({ mode = \"top\", window = " + luaStr(target) + " })");
        }
        else if (part == "fullscreen toggle" || part == "fullscreen") out << d("hl.dsp.window.fullscreen({ action = \"toggle\"" + w + " })");
        else if (part == "floating enable") out << d("hl.dsp.window.float({ action = \"set\"" + w + " })");
        else if (part == "floating disable") out << d("hl.dsp.window.float({ action = \"unset\"" + w + " })");
        else if (part == "floating toggle") out << d("hl.dsp.window.float({ action = \"toggle\"" + w + " })");
        else if ((r = QRegularExpression("^resize set (\\d+) (\\d+)$").match(part)).hasMatch())
            out << d("hl.dsp.window.resize({ x = " + r.captured(1) + ", y = " + r.captured(2) + w + " })");
        else if ((r = QRegularExpression("^move (?:absolute )?position (\\d+) (\\d+)$").match(part)).hasMatch())
            out << d("hl.dsp.window.move({ x = " + r.captured(1) + ", y = " + r.captured(2) + w + " })");
        else if ((r = QRegularExpression("^move (?:container )?to workspace (?:number )?\"?([^\"]+)\"?$").match(part)).hasMatch())
            out << d("hl.dsp.window.move({ workspace = " + ws(r.captured(1)) + w + " })");
        // «opacity …»: Hyprland ya anima la entrada de las ventanas; el fundido manual de sway no hace falta
    }
    return out;
}
