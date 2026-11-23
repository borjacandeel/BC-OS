#include "systemstatus.h"
#include <QTimer>
#include <QDir>
#include <QFile>
#include <QProcess>
#include <QRegularExpression>
#include <QSettings>
#include <QStandardPaths>
#include <QtMath>

namespace {
QString find(const QString &p) { return QStandardPaths::findExecutable(p); }
QString readFile(const QString &path) {
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) return {};
    return QString::fromUtf8(f.readAll()).trimmed();
}
QStringList splitNm(const QString &line) {
    QStringList out;
    QString cur;
    for (int i = 0; i < line.size(); ++i) {
        if (line[i] == '\\' && i + 1 < line.size()) { cur += line[++i]; continue; }
        if (line[i] == ':') { out << cur; cur.clear(); continue; }
        cur += line[i];
    }
    out << cur;
    return out;
}
}  // namespace

SystemStatus::SystemStatus(QObject *parent) : QObject(parent) {
    m_dnd = QSettings("BC-OS", "bc-shell").value("noMolestar", false).toBool();
    m_timer.setInterval(5000);
    connect(&m_timer, &QTimer::timeout, this, &SystemStatus::refresh);
    m_timer.start();
    QTimer::singleShot(0, this, &SystemStatus::refresh);
}

SystemStatus::Volume SystemStatus::parseWpctl(const QString &out) {
    static const QRegularExpression re(R"(Volume:\s*([0-9]*\.?[0-9]+))");
    Volume v;
    const auto m = re.match(out);
    if (!m.hasMatch()) return v;
    v.ok = true;
    v.value = qBound(0.0, m.captured(1).toDouble(), 1.5);
    v.muted = out.contains("[MUTED]");
    return v;
}

SystemStatus::Net SystemStatus::parseNmcliDevices(const QString &out) {
    Net n;
    for (const QString &line : out.split('\n', Qt::SkipEmptyParts)) {
        const QStringList f = splitNm(line);
        if (f.size() < 3) continue;
        const QString type = f[1], state = f[2], conn = f.value(3);
        if (type == "wifi") n.hasWifi = true;
        if ((type == "wifi" || type == "ethernet") && state.startsWith("connected") && !n.online) {
            n.online = true;
            n.wired = (type == "ethernet");
            n.connection = conn;
        }
    }
    return n;
}

int SystemStatus::parseNmcliSignal(const QString &out) {
    for (const QString &line : out.split('\n', Qt::SkipEmptyParts)) {
        const QStringList f = splitNm(line);
        if (f.size() >= 2 && f[0] == "yes") return f[1].toInt();
    }
    return -1;
}

int SystemStatus::signalBars(int p) {
    if (p < 0) return 0;
    if (p >= 75) return 3;
    if (p >= 50) return 2;
    if (p >= 25) return 1;
    return 0;
}

bool SystemStatus::parseBluetoothPowered(const QString &out) {
    return out.contains(QRegularExpression(R"(Powered:\s*yes)"));
}

void SystemStatus::parseBrightnessctl(const QString &out, bool &ok, double &frac) {
    // brightnessctl -m: dispositivo,clase,actual,porcentaje%,máximo
    const QStringList f = out.trimmed().split(',');
    ok = f.size() >= 5;
    if (ok) frac = qBound(0.0, f[3].chopped(f[3].endsWith('%') ? 1 : 0).toDouble() / 100.0, 1.0);
}

void SystemStatus::run(const QString &program, const QStringList &args, std::function<void(int, const QString &)> done) {
    const QString exe = find(program);
    if (exe.isEmpty()) { done(-1, {}); return; }
    const QString key = exe + ' ' + args.join(' ');
    if (m_running.contains(key)) return;      // la consulta anterior aún no ha terminado (p. ej. nmcli colgado)
    m_running.insert(key);
    auto *p = new QProcess(this);
    connect(p, &QProcess::finished, this, [this, p, done, key](int code, QProcess::ExitStatus) {
        m_running.remove(key);
        done(code, QString::fromUtf8(p->readAllStandardOutput()));
        p->deleteLater();
    });
    connect(p, &QProcess::errorOccurred, this, [this, p, done, key](QProcess::ProcessError e) {
        if (e == QProcess::FailedToStart) { m_running.remove(key); done(-1, {}); p->deleteLater(); }
    });
    QTimer::singleShot(10000, p, [p] { if (p->state() != QProcess::NotRunning) p->kill(); });
    p->start(exe, args);
}

void SystemStatus::readBattery() {
    const int p0 = m_batteryPercent; const bool c0 = m_batteryCharging, h0 = m_hasBattery;
    bool found = false;
    const QDir d(qEnvironmentVariable("BC_POWER_SUPPLY_DIR", QStringLiteral("/sys/class/power_supply")));   // (otra carpeta: pruebas y capturas)
    for (const QString &n : d.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
        if (readFile(d.filePath(n + "/type")) != "Battery") continue;
        found = true;
        m_batteryPercent = readFile(d.filePath(n + "/capacity")).toInt();
        const QString st = readFile(d.filePath(n + "/status"));
        m_batteryCharging = st == "Charging" || st == "Full";
        break;
    }
    m_hasBattery = found;
    // Avisar si cambia (antes dependía de que otra lectura emitiera «changed»: la batería podía quedarse sin actualizar)
    if (p0 != m_batteryPercent || c0 != m_batteryCharging || h0 != m_hasBattery) emit changed();
}

bool SystemStatus::cameraInUse() {
    // ¿Algún proceso del usuario tiene abierta una cámara (/dev/video*)? Sin cámaras no se recorre nada
    if (QDir("/dev").entryList({"video*"}, QDir::System).isEmpty()) return false;
    const QStringList pids = QDir("/proc").entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString &pid : pids) {
        if (pid.isEmpty() || !pid.at(0).isDigit()) continue;
        QDir fd("/proc/" + pid + "/fd");
        for (const QFileInfo &f : fd.entryInfoList(QDir::Files | QDir::System | QDir::NoDotAndDotDot))
            if (f.symLinkTarget().startsWith("/dev/video")) return true;
    }
    return false;
}

void SystemStatus::refresh() {
    readBattery();
    { const bool cam = cameraInUse(); if (cam != m_cam) { m_cam = cam; emit changed(); } }
    run("pactl", {"list", "short", "source-outputs"}, [this](int code, const QString &out) {
        const bool mic = code == 0 && !out.trimmed().isEmpty();
        if (mic != m_mic) { m_mic = mic; emit changed(); }
    });
    run("wpctl", {"get-volume", "@DEFAULT_AUDIO_SINK@"}, [this](int code, const QString &out) {
        const Volume v = code == 0 ? parseWpctl(out) : Volume();
        if (v.ok != m_audio || v.value != m_volume || v.muted != m_muted) {
            m_audio = v.ok; m_volume = v.value; m_muted = v.muted;
            emit changed();
        }
    });
    run("nmcli", {"-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device"}, [this](int code, const QString &out) {
        const Net n = code == 0 ? parseNmcliDevices(out) : Net();
        if (n.hasWifi != m_hasWifi || n.online != m_online || n.wired != m_wired || n.connection != m_connection) {
            m_hasWifi = n.hasWifi; m_online = n.online; m_wired = n.wired; m_connection = n.connection;
            emit changed();
        }
    });
    if (m_hasWifi) {
        run("nmcli", {"radio", "wifi"}, [this](int code, const QString &out) {
            const bool on = code == 0 && out.trimmed() == "enabled";
            if (on != m_wifiEnabled) { m_wifiEnabled = on; emit changed(); }
        });
        run("nmcli", {"-t", "-f", "ACTIVE,SIGNAL,SSID", "device", "wifi"}, [this](int code, const QString &out) {
            const int s = code == 0 ? parseNmcliSignal(out) : -1;
            if (s != m_signal) { m_signal = s; emit changed(); }
        });
    }
    if (!QDir("/sys/class/bluetooth").entryList(QDir::Dirs | QDir::NoDotAndDotDot).isEmpty()) {
        run("bluetoothctl", {"show"}, [this](int code, const QString &out) {
            const bool avail = code == 0 && out.contains("Controller");
            const bool on = avail && parseBluetoothPowered(out);
            if (avail != m_btAvailable || on != m_btOn) { m_btAvailable = avail; m_btOn = on; emit changed(); }
        });
    }
    run("brightnessctl", {"-c", "backlight", "-m"}, [this](int code, const QString &out) {
        bool ok = false; double frac = 0;
        if (code == 0) parseBrightnessctl(out, ok, frac);
        if (ok != m_hasBacklight || (ok && qAbs(frac - m_brightness) > 0.005)) {
            m_hasBacklight = ok; m_brightness = frac; emit changed();
        }
    });
}

void SystemStatus::setVolume(double v) {
    v = qBound(0.0, v, 1.0);
    m_volume = v;
    emit changed();
    run("wpctl", {"set-volume", "@DEFAULT_AUDIO_SINK@", QString::number(v, 'f', 2)}, [](int, const QString &) {});
}

void SystemStatus::toggleMute() {
    m_muted = !m_muted;
    emit changed();
    run("wpctl", {"set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"}, [](int, const QString &) {});
}

void SystemStatus::setWifi(bool on) {
    m_wifiEnabled = on;
    emit changed();
    run("nmcli", {"radio", "wifi", on ? "on" : "off"}, [this](int, const QString &) { refresh(); });
}

void SystemStatus::setBrightness(double v) {
    v = qBound(0.05, v, 1.0);
    m_brightness = v;
    emit changed();
    run("brightnessctl", {"set", QString::number(qRound(v * 100)) + "%"}, [](int, const QString &) {});
}

void SystemStatus::setBluetooth(bool on) {
    m_btOn = on;
    emit changed();
    run("bluetoothctl", {"power", on ? "on" : "off"}, [this](int, const QString &) { refresh(); });
}

void SystemStatus::setDnd(bool on) {
    if (on == m_dnd) return;
    m_dnd = on;
    QSettings("BC-OS", "bc-shell").setValue("noMolestar", on);
    emit changed();
}
