#pragma once
#include <QObject>
#include <QSet>
#include <QStringList>
#include <QTimer>
#include <functional>

// Estado real del sistema para la barra y el Centro de control: audio (wpctl), red (nmcli),
// batería (sysfs), brillo (brightnessctl/sysfs), Bluetooth (bluetoothctl) y No molestar.
class SystemStatus : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool audioAvailable READ audioAvailable NOTIFY changed)
    Q_PROPERTY(double volume READ volume NOTIFY changed)
    Q_PROPERTY(bool muted READ muted NOTIFY changed)
    Q_PROPERTY(bool hasWifi READ hasWifi NOTIFY changed)
    Q_PROPERTY(bool wifiEnabled READ wifiEnabled NOTIFY changed)
    Q_PROPERTY(bool online READ online NOTIFY changed)
    Q_PROPERTY(bool wired READ wired NOTIFY changed)
    Q_PROPERTY(QString connection READ connection NOTIFY changed)
    Q_PROPERTY(int signal READ signal NOTIFY changed)
    Q_PROPERTY(bool hasBattery READ hasBattery NOTIFY changed)
    Q_PROPERTY(int batteryPercent READ batteryPercent NOTIFY changed)
    Q_PROPERTY(bool batteryCharging READ batteryCharging NOTIFY changed)
    Q_PROPERTY(bool hasBacklight READ hasBacklight NOTIFY changed)
    Q_PROPERTY(double brightness READ brightness NOTIFY changed)
    Q_PROPERTY(bool bluetoothAvailable READ bluetoothAvailable NOTIFY changed)
    Q_PROPERTY(bool bluetoothOn READ bluetoothOn NOTIFY changed)
    Q_PROPERTY(bool dnd READ dnd WRITE setDnd NOTIFY changed)
public:
    explicit SystemStatus(QObject *parent = nullptr);
    bool audioAvailable() const { return m_audio; }
    double volume() const { return m_volume; }
    bool muted() const { return m_muted; }
    bool hasWifi() const { return m_hasWifi; }
    bool wifiEnabled() const { return m_wifiEnabled; }
    bool online() const { return m_online; }
    bool wired() const { return m_wired; }
    QString connection() const { return m_connection; }
    int signal() const { return m_signal; }
    bool hasBattery() const { return m_hasBattery; }
    int batteryPercent() const { return m_batteryPercent; }
    bool batteryCharging() const { return m_batteryCharging; }
    bool hasBacklight() const { return m_hasBacklight; }
    double brightness() const { return m_brightness; }
    bool bluetoothAvailable() const { return m_btAvailable; }
    bool bluetoothOn() const { return m_btOn; }
    bool dnd() const { return m_dnd; }

    Q_INVOKABLE void setVolume(double v);
    Q_INVOKABLE void toggleMute();
    Q_INVOKABLE void setWifi(bool on);
    Q_INVOKABLE void setBrightness(double v);
    Q_INVOKABLE void setBluetooth(bool on);
    void setDnd(bool on);
    Q_INVOKABLE void refresh();

    // Analizadores puros (probados en tst_shell).
    struct Volume { bool ok = false; double value = 0; bool muted = false; };
    static Volume parseWpctl(const QString &out);
    struct Net { bool hasWifi = false; bool online = false; bool wired = false; QString connection; };
    static Net parseNmcliDevices(const QString &out);
    static int parseNmcliSignal(const QString &out);  // % de la red activa, -1 si ninguna
    Q_INVOKABLE static int signalBars(int percent);   // 0..3
    static bool parseBluetoothPowered(const QString &out);
    static void parseBrightnessctl(const QString &out, bool &ok, double &frac);

signals:
    void changed();

private:
    void run(const QString &program, const QStringList &args, std::function<void(int, const QString &)> done);
    void readBattery();
    QTimer m_timer;
    bool m_audio = false, m_muted = false, m_hasWifi = false, m_wifiEnabled = false, m_online = false, m_wired = false;
    QSet<QString> m_running;
    bool m_hasBattery = false, m_batteryCharging = false, m_hasBacklight = false, m_btAvailable = false, m_btOn = false, m_dnd = false;
    double m_volume = 0, m_brightness = 0;
    int m_signal = -1, m_batteryPercent = 0;
    QString m_connection;
};
