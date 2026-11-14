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
