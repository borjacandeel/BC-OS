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
