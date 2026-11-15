#include "desktopdata.h"
#include <QDBusArgument>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusMetaType>
#include <QDBusObjectPath>
#include <QDBusReply>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>
#include <QFileSystemWatcher>
#include <QStandardPaths>
#include <QRegularExpression>

static QString readLine(const QString &path) {
    QFile f(path);
    return f.open(QIODevice::ReadOnly) ? QString::fromUtf8(f.readAll()).trimmed() : QString();
}

Batteries::Batteries(QObject *parent) : QObject(parent) {
    m_timer.setInterval(60000);
    connect(&m_timer, &QTimer::timeout, this, &Batteries::refresh);
}

void Batteries::setActive(bool on) {
    if (on == m_timer.isActive()) return;
    if (on) { refresh(); m_timer.start(); } else m_timer.stop();
    emit activeChanged();
}

QString Batteries::kindFor(const QString &type, const QString &name) {
    const QString n = (type + " " + name).toLower();
    if (n.contains("mouse") || n.contains("ratón") || n.contains(" m2") || n.contains("mx master") || n.contains("logi m")) return "mouse";
    if (n.contains("keyboard") || n.contains("teclado")) return "keyboard";
    if (n.contains("audio") || n.contains("head") || n.contains("pods") || n.contains("buds") || n.contains("auricular")) return "headphones";
    if (n.contains("gamepad") || n.contains("controller") || n.contains("joystick")) return "gamepad";
    if (n.contains("phone")) return "phone";
    if (n.contains("system") || n.startsWith("bat")) return "laptop";
    return "battery";
}

void Batteries::refresh() {
    QVariantList out;
    QDir ps("/sys/class/power_supply");
    for (const QString &e : ps.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name)) {
        const QString d = ps.filePath(e);
        if (readLine(d + "/type") != "Battery") continue;
        const QString cap = readLine(d + "/capacity");
        if (cap.isEmpty()) continue;
        const bool device = readLine(d + "/scope") == "Device";
        QString name = readLine(d + "/model_name");
        if (!device) name = QObject::tr("Este equipo");
        else if (name.isEmpty()) name = e;
        out.append(QVariantMap{{"name", name}, {"percent", cap.toInt()}, {"charging", readLine(d + "/status") == "Charging"},
                               {"kind", device ? kindFor(readLine(d + "/type"), name) : QString("laptop")}});
    }
    // Bluetooth (BlueZ expone el nivel de batería de auriculares, ratones, etc.)
    QDBusMessage m = QDBusMessage::createMethodCall("org.bluez", "/", "org.freedesktop.DBus.ObjectManager", "GetManagedObjects");
    QDBusMessage r = QDBusConnection::systemBus().call(m, QDBus::Block, 1500);
    if (r.type() == QDBusMessage::ReplyMessage && !r.arguments().isEmpty()) {
        const QDBusArgument arg = r.arguments().first().value<QDBusArgument>();
        arg.beginMap();
        while (!arg.atEnd()) {
            QDBusObjectPath path;
            QMap<QString, QVariantMap> ifaces;
            arg.beginMapEntry();
            arg >> path;
            arg.beginMap();
            while (!arg.atEnd()) {
                QString iface; QVariantMap props;
                arg.beginMapEntry(); arg >> iface;
                arg.beginMap();
                while (!arg.atEnd()) { QString k; QDBusVariant v; arg.beginMapEntry(); arg >> k >> v; arg.endMapEntry(); props.insert(k, v.variant()); }
                arg.endMap();
                arg.endMapEntry();
                ifaces.insert(iface, props);
            }
            arg.endMap();
            arg.endMapEntry();
            if (!ifaces.contains("org.bluez.Battery1") || !ifaces.contains("org.bluez.Device1")) continue;
            const QVariantMap dev = ifaces.value("org.bluez.Device1");
            if (!dev.value("Connected").toBool()) continue;
            const QString name = dev.value("Alias", dev.value("Name")).toString();
            out.append(QVariantMap{{"name", name}, {"percent", ifaces.value("org.bluez.Battery1").value("Percentage").toInt()},
                                   {"charging", false}, {"kind", kindFor(dev.value("Icon").toString(), name)}});
        }
        arg.endMap();
    }
    if (out != m_devices) { m_devices = out; emit changed(); }
}

// ---------------------------------------------------------------------------------------------
Reminders::Reminders(QObject *parent, const QString &file) : QObject(parent), m_file(file) {
    if (m_file.isEmpty()) m_file = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/bc/recordatorios.json";
    load();
    // La app Recordatorios y el widget del escritorio son procesos distintos: se recarga al cambiar el archivo
    QDir().mkpath(QFileInfo(m_file).absolutePath());
    auto *w = new QFileSystemWatcher(this);
    w->addPath(QFileInfo(m_file).absolutePath());
    if (QFileInfo::exists(m_file)) w->addPath(m_file);
    auto again = [this, w] { if (QFileInfo::exists(m_file) && !w->files().contains(m_file)) w->addPath(m_file); load(); emit changed(); };
    connect(w, &QFileSystemWatcher::fileChanged, this, again);
    connect(w, &QFileSystemWatcher::directoryChanged, this, again);
}
int Reminders::pending() const {
    int n = 0;
    for (const QVariant &v : m_items) if (!v.toMap().value("done").toBool()) ++n;
    return n;
}
void Reminders::load() {
    QFile f(m_file);
    m_items.clear();
    if (f.open(QIODevice::ReadOnly)) m_items = QJsonDocument::fromJson(f.readAll()).array().toVariantList();
}
void Reminders::save() {
    QDir().mkpath(QFileInfo(m_file).absolutePath());
    QSaveFile f(m_file);
    if (f.open(QIODevice::WriteOnly)) { f.write(QJsonDocument(QJsonArray::fromVariantList(m_items)).toJson(QJsonDocument::Compact)); f.commit(); }
    emit changed();
}
void Reminders::add(const QString &title) {
    const QString t = title.trimmed().left(200);
    if (t.isEmpty()) return;
    int id = 1;
    for (const QVariant &v : m_items) id = qMax(id, v.toMap().value("id").toInt() + 1);
    m_items.append(QVariantMap{{"id", id}, {"title", t}, {"done", false}});
    save();
}
void Reminders::toggle(int id) {
    for (QVariant &v : m_items) { QVariantMap m = v.toMap(); if (m.value("id").toInt() == id) { m["done"] = !m.value("done").toBool(); v = m; } }
    save();
}
void Reminders::remove(int id) {
    for (int i = m_items.size() - 1; i >= 0; --i) if (m_items[i].toMap().value("id").toInt() == id) m_items.removeAt(i);
    save();
}
void Reminders::clearDone() {
    for (int i = m_items.size() - 1; i >= 0; --i) if (m_items[i].toMap().value("done").toBool()) m_items.removeAt(i);
    save();
}

// ---------------------------------------------------------------------------------------------
WidgetHost::WidgetHost(QObject *parent, const QString &dir) : QObject(parent), m_dir(dir) {
    if (m_dir.isEmpty()) m_dir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/bc/widgets";
    m_timer.setInterval(30000);
    connect(&m_timer, &QTimer::timeout, this, &WidgetHost::refresh);
    m_timer.start();
    refresh();
}
QVariantMap WidgetHost::parse(const QByteArray &json, const QString &id) {
    const QJsonObject o = QJsonDocument::fromJson(json).object();
    if (o.isEmpty() || o.value("title").toString().isEmpty()) return {};
    QVariantList rows;
    for (const QJsonValue &r : o.value("rows").toArray()) {
        const QJsonObject ro = r.toObject();
        rows.append(QVariantMap{{"label", ro.value("label").toString().left(60)}, {"detail", ro.value("detail").toString().left(80)},
                                {"value", qBound(0.0, ro.value("value").toDouble(-1), 1.0)}, {"hasValue", ro.contains("value")},
                                {"right", ro.value("right").toString().left(40)}});
        if (rows.size() >= 5) break;
    }
    return {{"id", id}, {"title", o.value("title").toString().left(40)}, {"icon", o.value("icon").toString()}, {"rows", rows}};
}
void WidgetHost::refresh() {
    QVariantList out;
    QDir d(m_dir);
    for (const QFileInfo &fi : d.entryInfoList({"*.json"}, QDir::Files, QDir::Name)) {
        if (fi.size() > 65536) continue;
        QFile f(fi.filePath());
        if (!f.open(QIODevice::ReadOnly)) continue;
        const QVariantMap w = parse(f.readAll(), fi.completeBaseName());
        if (!w.isEmpty()) out.append(w);
    }
    if (out != m_widgets) { m_widgets = out; emit changed(); }
}

// ---------------------------------------------------------------------------------------------
#include <QProcess>
#include <QLocale>
#include <cmath>
QuickTools::QuickTools(QObject *parent) : QObject(parent) {
    m_media = {{"available", false}, {"playing", false}, {"title", ""}, {"artist", ""}};
    m_mediaTimer.setInterval(3000);
    connect(&m_mediaTimer, &QTimer::timeout, this, &QuickTools::refreshMedia);
}
void QuickTools::run(const QString &prog, const QStringList &args, std::function<void(int, const QString &)> done) {
    if (QStandardPaths::findExecutable(prog).isEmpty()) { done(-1, QString()); return; }
    auto *p = new QProcess(this);
    ++m_busy; emit busyChanged();
    connect(p, &QProcess::finished, this, [this, p, done](int code) {
        done(code, QString::fromUtf8(p->readAllStandardOutput())); p->deleteLater(); --m_busy; emit busyChanged();
    });
    connect(p, &QProcess::errorOccurred, this, [this, p, done](QProcess::ProcessError e) {
        if (e != QProcess::FailedToStart) return; done(-1, QString()); p->deleteLater(); --m_busy; emit busyChanged();
    });
    QTimer::singleShot(20000, p, [p] { if (p->state() != QProcess::NotRunning) p->kill(); });
    p->start(prog, args);
}
QVariantList QuickTools::parseWifi(const QString &t) {
    QVariantList out; QStringList seen;
    for (const QString &line : t.split('\n', Qt::SkipEmptyParts)) {
        // IN-USE:SIGNAL:SECURITY:SSID (los «:» del SSID vienen escapados como «\:»)
        QStringList f; QString cur; bool esc = false;
        for (QChar c : line) { if (esc) { cur += c; esc = false; } else if (c == '\\') esc = true; else if (c == ':') { f << cur; cur.clear(); } else cur += c; }
        f << cur;
        if (f.size() < 4 || f[3].isEmpty() || seen.contains(f[3])) continue;
        seen << f[3];
        out.append(QVariantMap{{"ssid", f[3]}, {"signal", f[1].toInt()}, {"secure", !f[2].isEmpty() && f[2] != "--"}, {"active", f[0] == "*"}});
    }
    return out;
}
void QuickTools::scanWifi() {
    run("nmcli", {"-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "dev", "wifi", "list", "--rescan", "auto"}, [this](int code, const QString &o) {
        const QVariantList n = code == 0 ? parseWifi(o) : QVariantList();
        if (n != m_networks) { m_networks = n; emit networksChanged(); }
    });
}
void QuickTools::connectWifi(const QString &ssid, const QString &pw) {
    QStringList a{"dev", "wifi", "connect", ssid};
    if (!pw.isEmpty()) a << "password" << pw;
    run("nmcli", a, [this, ssid](int code, const QString &) { emit wifiResult(code == 0, ssid); scanWifi(); });
}
QVariantList QuickTools::parseBluetooth(const QString &devs, const QString &conn) {
    QVariantList out;
    for (const QString &line : devs.split('\n', Qt::SkipEmptyParts)) {
        if (!line.startsWith("Device ")) continue;
        const QString mac = line.section(' ', 1, 1), name = line.section(' ', 2);
        out.append(QVariantMap{{"mac", mac}, {"name", name}, {"connected", conn.contains(mac)}});
    }
    return out;
}
void QuickTools::scanBluetooth() {
    run("bluetoothctl", {"devices"}, [this](int, const QString &all) {
        run("bluetoothctl", {"devices", "Connected"}, [this, all](int, const QString &c) {
            const QVariantList l = parseBluetooth(all, c);
            if (l != m_bt) { m_bt = l; emit btChanged(); }
        });
    });
    run("bluetoothctl", {"--timeout", "6", "scan", "on"}, [this](int, const QString &) {
        run("bluetoothctl", {"devices"}, [this](int, const QString &all) {
            run("bluetoothctl", {"devices", "Connected"}, [this, all](int, const QString &c) {
                const QVariantList l = parseBluetooth(all, c);
                if (l != m_bt) { m_bt = l; emit btChanged(); }
            });
        });
    });
}
void QuickTools::toggleBluetoothDevice(const QString &mac, bool on) {
    static const QRegularExpression ok("^[0-9A-Fa-f:]{17}$");
    if (!ok.match(mac).hasMatch()) return;
    if (on) run("bluetoothctl", {"pair", mac}, [this, mac](int, const QString &) {
        run("bluetoothctl", {"trust", mac}, [this, mac](int, const QString &) { run("bluetoothctl", {"connect", mac}, [this](int, const QString &) { scanBluetooth(); }); });
    });
    else run("bluetoothctl", {"disconnect", mac}, [this](int, const QString &) { scanBluetooth(); });
}
void QuickTools::refreshMedia() {
    run("playerctl", {"metadata", "--format", "{{status}}\t{{title}}\t{{artist}}"}, [this](int code, const QString &o) {
        QVariantMap m{{"available", false}, {"playing", false}, {"title", ""}, {"artist", ""}};
        if (code == 0) {
            const QStringList f = o.trimmed().split('\t');
            if (f.size() >= 2 && !f[1].isEmpty()) m = {{"available", true}, {"playing", f[0] == "Playing"}, {"title", f[1]}, {"artist", f.value(2)}};
        }
        if (m != m_media) { m_media = m; emit mediaChanged(); }
    });
}
void QuickTools::mediaCommand(const QString &cmd) {
    if (!QStringList{"play-pause", "next", "previous"}.contains(cmd)) return;
    run("playerctl", {cmd}, [this](int, const QString &) { refreshMedia(); });
}

void QuickTools::searchFiles(const QString &text) {
    const QString t = text.trimmed();
    const int seq = ++m_searchSeq;
    if (t.size() < 2) { m_files.clear(); emit filesChanged(); return; }
    QString pat = t; pat.replace('[', "\\[").replace('*', "\\*").replace('?', "\\?");
    const QString home = QDir::homePath();
    run("find", {home, "-maxdepth", "5", "-not", "-path", "*/.*", "-iname", "*" + pat + "*"}, [this, seq, home](int, const QString &o) {
        if (seq != m_searchSeq) return;
        QVariantList out;
        for (const QString &p : o.split('\n', Qt::SkipEmptyParts)) {
            if (p == home) continue;
            const QFileInfo fi(p);
            out.append(QVariantMap{{"path", p}, {"name", fi.fileName()}, {"dir", fi.isDir()}, {"parent", QString(fi.absolutePath()).replace(home, "~")}});
            if (out.size() >= 12) break;
        }
        m_files = out; emit filesChanged();
    });
}

// Evaluador seguro de expresiones aritméticas (sin JavaScript eval): + - * / % ^ ( ) y coma decimal
namespace {
struct Calc {
    QString s; int i = 0; bool ok = true;
    QChar peek() { while (i < s.size() && s[i].isSpace()) ++i; return i < s.size() ? s[i] : QChar(); }
    double expr() { double v = term(); for (;;) { QChar c = peek(); if (c == '+') { ++i; v += term(); } else if (c == '-') { ++i; v -= term(); } else return v; } }
    double term() { double v = power(); for (;;) { QChar c = peek();
        if (c == '*' || c == QChar(0xD7)) { ++i; v *= power(); } else if (c == '/' || c == QChar(0xF7)) { ++i; double d = power(); if (d == 0) ok = false; else v /= d; }
        else if (c == '%') { ++i; double d = power(); if (d == 0) ok = false; else v = std::fmod(v, d); } else return v; } }
    double power() { double b = unary(); if (peek() == '^') { ++i; return std::pow(b, power()); } return b; }
    double unary() { if (peek() == '-') { ++i; return -unary(); } if (peek() == '+') { ++i; return unary(); } return atom(); }
    double atom() {
        if (peek() == '(') { ++i; double v = expr(); if (peek() == ')') ++i; else ok = false; return v; }
        const int st = i; while (i < s.size() && (s[i].isDigit() || s[i] == '.' || s[i] == ',')) ++i;
        if (st == i) { ok = false; return 0; }
        bool k; double v = s.mid(st, i - st).replace(',', '.').toDouble(&k); if (!k) ok = false; return v;
    }
};
}
QString QuickTools::calculate(const QString &e) {
    static const QRegularExpression allowed(R"(^[0-9\s\.,+\-*/%^()×÷]+$)"), hasOp(R"([+\-*/%^×÷])");
    if (!allowed.match(e).hasMatch() || !hasOp.match(e).hasMatch()) return {};
    Calc c{e};
    const double v = c.expr();
    if (!c.ok || c.peek() != QChar() || std::isnan(v) || std::isinf(v)) return {};
    return QLocale(QLocale::Spanish, QLocale::Spain).toString(v, 'g', 12);
}
void QuickTools::open(const QString &path) { QProcess::startDetached("xdg-open", {path}); }

#include <QSettings>
void SoundPlayer::play(const QString &name) {
    static const QRegularExpression ok("^[a-z-]{1,24}$");
    if (!ok.match(name).hasMatch()) return;
    if (!QSettings("BC-OS", "bc-shell").value("sonidos", true).toBool()) return;
    const QString f = "/usr/share/sounds/bc/" + name + ".wav";
    if (!QFileInfo::exists(f)) return;
    for (const char *p : {"pw-play", "paplay", "aplay"}) {
        const QString exe = QStandardPaths::findExecutable(p);
        if (!exe.isEmpty()) { QProcess::startDetached(exe, QStringList{(QString(p) == "aplay" ? "-q" : "--volume=0.6"), f}); return; }
    }
}

void QuickTools::capture(const QString &tag, const QString &geom) {
    static const QRegularExpression g(R"(^-?\d+,-?\d+ \d+x\d+$)"), t(R"(^[a-z0-9-]{1,32}$)");
    if (!t.match(tag).hasMatch() || (!geom.isEmpty() && !g.match(geom).hasMatch())) { emit captured(tag, QString(), false); return; }
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation) + "/bc-captures";
    QDir().mkpath(dir);
    const QString path = dir + "/" + tag + ".ppm";      // PPM: sin compresión, lo más rápido de escribir y leer
    QStringList a{"-t", "ppm"};
    if (!geom.isEmpty()) a << "-g" << geom;
    a << path;
    run("grim", a, [this, tag, path](int code, const QString &) { emit captured(tag, path, code == 0); });
}

// ---------------------------------------------------------------------------------------------
#include <csignal>
#include <pwd.h>
#include <unistd.h>
Processes::Processes(QObject *parent) : QObject(parent) {
    m_timer.setInterval(2000);
    connect(&m_timer, &QTimer::timeout, this, &Processes::refresh);
}
void Processes::setActive(bool on) {
    if (on == m_timer.isActive()) return;
    if (on) { refresh(); m_timer.start(); } else m_timer.stop();
    emit activeChanged();
}
static QString userName(uint uid) {
    static QHash<uint, QString> cache;
    if (cache.contains(uid)) return cache.value(uid);
    const passwd *pw = getpwuid(uid);
    return cache[uid] = pw ? QString::fromLocal8Bit(pw->pw_name) : QString::number(uid);
}
void Processes::refresh() {
    // Totales de CPU (para % de usuario/sistema y para repartir entre procesos)
    QFile st("/proc/stat");
    qulonglong total = 0, user = 0, sys = 0;
    if (st.open(QIODevice::ReadOnly)) {
        const QList<QByteArray> f = st.readLine().simplified().split(' ');
        for (int i = 1; i < f.size(); ++i) total += f[i].toULongLong();
        if (f.size() > 4) { user = f[1].toULongLong() + f[2].toULongLong(); sys = f[3].toULongLong(); }
    }
    const qulonglong dTotal = total - m_prevTotal;
    if (m_prevTotal && dTotal) { m_userCpu = 100.0 * (user - m_prevUser) / dTotal; m_sysCpu = 100.0 * (sys - m_prevSys) / dTotal; }
    const long hz = sysconf(_SC_CLK_TCK) > 0 ? sysconf(_SC_CLK_TCK) : 100;
    const long page = sysconf(_SC_PAGESIZE) > 0 ? sysconf(_SC_PAGESIZE) : 4096;
    const int ncpu = qMax(1, int(sysconf(_SC_NPROCESSORS_ONLN)));
    const uint me = getuid();
    QHash<int, qulonglong> ticks;
    QVariantList all;
    int threads = 0;
    const QDir proc("/proc");
    for (const QString &e : proc.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
        bool ok = false; const int pid = e.toInt(&ok);
        if (!ok) continue;
        QFile f("/proc/" + e + "/stat");
        if (!f.open(QIODevice::ReadOnly)) continue;
        const QByteArray s = f.readAll();
        const int l = s.indexOf('('), r = s.lastIndexOf(')');
        if (l < 0 || r < 0) continue;
        const QString comm = QString::fromUtf8(s.mid(l + 1, r - l - 1));
        const QList<QByteArray> rest = s.mid(r + 2).split(' ');
        if (rest.size() < 22) continue;
        if (pid == 2 || rest[1].toInt() == 2) continue;   // hilos del núcleo: macOS tampoco los lista
        const qulonglong t = rest[11].toULongLong() + rest[12].toULongLong();   // utime + stime
        const int nth = rest[17].toInt();
        const qlonglong rss = rest[21].toLongLong() * page;
        ticks[pid] = t;
        threads += nth;
        double cpu = 0;
        if (m_prevTotal && dTotal && m_prevTicks.contains(pid)) cpu = 100.0 * ncpu * (t - m_prevTicks.value(pid)) / dTotal;
        const uint uid = QFileInfo("/proc/" + e).ownerId();
        // Nombre legible: el de la orden si comm está truncado (15 caracteres)
        QString name = comm;
        if (name.size() >= 15) { QFile c("/proc/" + e + "/cmdline"); if (c.open(QIODevice::ReadOnly)) { const QString a0 = QString::fromLocal8Bit(c.readAll().split('\0').value(0)); if (!a0.isEmpty()) name = a0.section('/', -1); } }
        const qulonglong secs = t / hz;
        all.append(QVariantMap{{"pid", pid}, {"name", name}, {"cpu", qRound(cpu * 10) / 10.0},
                               {"cpuTime", QString("%1:%2.%3").arg(secs / 60).arg(secs % 60, 2, 10, QChar('0')).arg((t % hz) * 100 / hz, 2, 10, QChar('0'))},
                               {"mem", rss}, {"memText", QLocale(QLocale::Spanish).formattedDataSize(rss, 1)}, {"threads", nth},
                               {"user", userName(uid)}, {"mine", uid == me}});
    }
    m_prevTicks = ticks; m_prevTotal = total; m_prevUser = user; m_prevSys = sys;
    m_all = all; m_threads = threads;
    rebuild();
}
void Processes::rebuild() {
    QVariantList l;
    for (const QVariant &v : std::as_const(m_all))
        if (m_filter.isEmpty() || v.toMap().value("name").toString().contains(m_filter, Qt::CaseInsensitive)) l << v;
    const QString k = m_sort;
    std::sort(l.begin(), l.end(), [&k](const QVariant &a, const QVariant &b) {
        const QVariantMap x = a.toMap(), y = b.toMap();
        if (k == "name") return x.value("name").toString().compare(y.value("name").toString(), Qt::CaseInsensitive) < 0;
        if (k == "pid") return x.value("pid").toInt() < y.value("pid").toInt();
        if (k == "mem") return x.value("mem").toLongLong() > y.value("mem").toLongLong();
        if (k == "threads") return x.value("threads").toInt() > y.value("threads").toInt();
        return x.value("cpu").toDouble() > y.value("cpu").toDouble();
    });
    m_list = l.mid(0, 300);
    emit changed();
}
bool Processes::quit(int pid, bool force) {
    if (pid <= 1 || QFileInfo("/proc/" + QString::number(pid)).ownerId() != getuid()) return false;
    return ::kill(pid, force ? SIGKILL : SIGTERM) == 0;
}

#include "appindex.h"
QString QuickTools::iconPath(const QString &name) {
    static const QRegularExpression ok("^[A-Za-z0-9._-]{1,80}$");
    return ok.match(name).hasMatch() ? AppIndex::resolveIcon(name) : QString();
}

// ---------------------------------------------------------------------------------------------
NotesStore::NotesStore(QObject *parent, const QString &dir) : QObject(parent), m_dir(dir) {
    if (m_dir.isEmpty()) m_dir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/bc/notas";
    reload();
}
static bool validNoteId(const QString &id) { static const QRegularExpression re("^[0-9]{6,20}$"); return re.match(id).hasMatch(); }
QString NotesStore::path(const QString &id) const {
    if (!validNoteId(id)) return {};
    if (QFileInfo::exists(m_dir + "/" + id + ".txt")) return m_dir + "/" + id + ".txt";
    if (QFileInfo::exists(m_dir + "/.eliminadas/" + id + ".txt")) return m_dir + "/.eliminadas/" + id + ".txt";
    return m_dir + "/" + id + ".txt";
}
QVariantList NotesStore::scan(const QString &dir) const {
    QVariantList out;
    const QLocale es(QLocale::Spanish, QLocale::Spain);
    for (const QFileInfo &fi : QDir(dir).entryInfoList({"*.txt"}, QDir::Files, QDir::Time)) {
        QFile f(fi.filePath());
        if (!f.open(QIODevice::ReadOnly)) continue;
        const QString t = QString::fromUtf8(f.read(2000));
        const QStringList lines = t.split('\n');
        QString title = lines.value(0).trimmed(); if (title.isEmpty()) title = QObject::tr("Nota nueva");
        QString snippet; for (int i = 1; i < lines.size() && snippet.isEmpty(); ++i) snippet = lines[i].trimmed();
        const QDateTime m = fi.lastModified();
        const QString date = m.date() == QDate::currentDate() ? es.toString(m.time(), "H:mm") : es.toString(m.date(), "d/M/yy");
        out.append(QVariantMap{{"id", fi.completeBaseName()}, {"title", title.left(80)}, {"snippet", snippet.left(80)}, {"date", date}, {"modified", m}});
    }
    return out;
}
void NotesStore::reload() { m_notes = scan(m_dir); m_deleted = scan(m_dir + "/.eliminadas"); emit changed(); }
QString NotesStore::create() {
    QDir().mkpath(m_dir);
    const QString id = QString::number(QDateTime::currentMSecsSinceEpoch());
    QFile f(m_dir + "/" + id + ".txt");
    if (f.open(QIODevice::WriteOnly)) f.close();
    reload();
    return id;
}
QString NotesStore::text(const QString &id) const {
    QFile f(path(id));
    return f.open(QIODevice::ReadOnly) ? QString::fromUtf8(f.readAll()) : QString();
}
void NotesStore::save(const QString &id, const QString &t) {
    const QString p = path(id);
    if (p.isEmpty()) return;
    QDir().mkpath(QFileInfo(p).absolutePath());
    QSaveFile f(p);
    if (f.open(QIODevice::WriteOnly)) { f.write(t.toUtf8()); f.commit(); }
    reload();
}
void NotesStore::remove(const QString &id) {
    const QString p = path(id);
    if (p.isEmpty()) return;
    if (p.contains("/.eliminadas/")) QFile::remove(p);
    else { QDir().mkpath(m_dir + "/.eliminadas"); QFile::rename(p, m_dir + "/.eliminadas/" + id + ".txt"); }
    reload();
}
void NotesStore::restore(const QString &id) {
    if (!validNoteId(id)) return;
    QFile::rename(m_dir + "/.eliminadas/" + id + ".txt", m_dir + "/" + id + ".txt");
    reload();
}

void QuickTools::listDisplayModes() {
    run("bc-display", {"list"}, [this](int code, const QString &o) {
        const QStringList m = code == 0 ? o.split('\n', Qt::SkipEmptyParts) : QStringList();
        if (m != m_modes) { m_modes = m; emit displayModesChanged(); }
    });
}
void QuickTools::setDisplayMode(const QString &mode) {
    static const QRegularExpression ok("^[0-9]{3,5}x[0-9]{3,5}$");
    if (mode == "auto") run("bc-display", {"auto"}, [](int, const QString &) {});
    else if (ok.match(mode).hasMatch()) run("bc-display", {"set", mode}, [](int, const QString &) {});
}
static QString kbFile() { return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + "/bc/keyboard-layout"; }
QString QuickTools::keyboardLayout() {
    QFile f(kbFile());
    const QString v = f.open(QIODevice::ReadOnly) ? QString::fromUtf8(f.readAll()).trimmed() : QString();
    return v.isEmpty() ? QStringLiteral("es") : v;
}
bool QuickTools::setKeyboardLayout(const QString &code) {
    static const QStringList ok{"es", "us", "gb", "fr", "de", "it", "pt", "latam"};
    if (!ok.contains(code)) return false;
    QDir().mkpath(QFileInfo(kbFile()).absolutePath());
    QSaveFile f(kbFile());
    if (!f.open(QIODevice::WriteOnly)) return false;
    f.write(code.toUtf8() + "\n"); f.commit();
    QProcess::startDetached("swaymsg", {"input type:keyboard xkb_layout " + code});
    QProcess::startDetached("bc-wm-mode", {"init"});
    return true;
}
