#pragma once
#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>
#include <functional>

// Datos reales para los widgets del escritorio (Golden Gate).

// Baterías: la del equipo y las de periféricos (/sys/class/power_supply) y Bluetooth (org.bluez Battery1).
class Batteries : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList devices READ devices NOTIFY changed)   // [{name, percent, charging, kind}]
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
public:
    explicit Batteries(QObject *parent = nullptr);
    QVariantList devices() const { return m_devices; }
    bool active() const { return m_timer.isActive(); }
    void setActive(bool on);
    Q_INVOKABLE void refresh();
    static QString kindFor(const QString &type, const QString &name);   // laptop, mouse, keyboard, headphones, gamepad, phone, battery
signals:
    void changed();
    void activeChanged();
private:
    QVariantList m_devices;
    QTimer m_timer;
};

// Recordatorios: lista local persistente (~/.local/share/bc/recordatorios.json).
class Reminders : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList items READ items NOTIFY changed)       // [{id, title, done}]
    Q_PROPERTY(int pending READ pending NOTIFY changed)
public:
    explicit Reminders(QObject *parent = nullptr, const QString &file = QString());
    QVariantList items() const { return m_items; }
    int pending() const;
    Q_INVOKABLE void add(const QString &title);
    Q_INVOKABLE void toggle(int id);
    Q_INVOKABLE void remove(int id);
    Q_INVOKABLE void clearDone();
    QString file() const { return m_file; }
signals:
    void changed();
private:
    QString m_file;
    QVariantList m_items;
    void load();
    void save();
};

// Widgets de otras apps: cada app deja un JSON en ~/.local/share/bc/widgets/<id>.json
// { "title": "…", "icon": "nombre-icono", "rows": [{ "label": "…", "detail": "…", "value": 0.4, "right": "…" }] }
// BC OS publica su propio widget «Uso del equipo» con el mismo formato.
class WidgetHost : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList widgets READ widgets NOTIFY changed)
public:
    explicit WidgetHost(QObject *parent = nullptr, const QString &dir = QString());
    QVariantList widgets() const { return m_widgets; }
    Q_INVOKABLE void refresh();
    static QVariantMap parse(const QByteArray &json, const QString &id);
    QString dir() const { return m_dir; }
signals:
    void changed();
private:
    QString m_dir;
    QVariantList m_widgets;
    QTimer m_timer;
};

// Control Center: redes Wi-Fi (nmcli), dispositivos Bluetooth (bluetoothctl) y reproducción (playerctl).
class QuickTools : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList networks READ networks NOTIFY networksChanged)     // [{ssid, signal, secure, active}]
    Q_PROPERTY(QVariantList btDevices READ btDevices NOTIFY btChanged)         // [{mac, name, connected, paired}]
    Q_PROPERTY(QVariantMap media READ media NOTIFY mediaChanged)               // {title, artist, playing, available}
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QVariantList fileResults READ fileResults NOTIFY filesChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)   // sondeo de reproducción solo con el panel visible
public:
    bool active() const { return m_mediaTimer.isActive(); }
    void setActive(bool on) { if (on == active()) return; if (on) { refreshMedia(); m_mediaTimer.start(); } else m_mediaTimer.stop(); emit activeChanged(); }
    explicit QuickTools(QObject *parent = nullptr);
    QVariantList networks() const { return m_networks; }
    QVariantList btDevices() const { return m_bt; }
    QVariantMap media() const { return m_media; }
    QVariantList fileResults() const { return m_files; }
    bool busy() const { return m_busy > 0; }
    Q_INVOKABLE void scanWifi();
    Q_INVOKABLE void connectWifi(const QString &ssid, const QString &password = QString());
    Q_INVOKABLE void scanBluetooth();
    Q_INVOKABLE void toggleBluetoothDevice(const QString &mac, bool connect);
    Q_INVOKABLE void refreshMedia();
    Q_INVOKABLE void mediaCommand(const QString &cmd);     // play-pause, next, previous
    // Spotlight: archivos de la carpeta personal cuyo nombre contiene el texto (asíncrono → fileResults)
    Q_INVOKABLE void searchFiles(const QString &text);
    Q_INVOKABLE static QString calculate(const QString &expr);   // «2+2*3» → «8»; vacío si no es una operación
    Q_INVOKABLE void open(const QString &path);              // xdg-open
    static QVariantList parseWifi(const QString &nmcliTerse);
    static QVariantList parseBluetooth(const QString &devices, const QString &connected);
signals:
    void networksChanged();
    void btChanged();
    void mediaChanged();
    void busyChanged();
    void activeChanged();
    void wifiResult(bool ok, const QString &ssid);
    void filesChanged();
private:
    void run(const QString &prog, const QStringList &args, std::function<void(int, const QString &)> done);
    QVariantList m_networks, m_bt, m_files;
    int m_searchSeq = 0;
    QVariantMap m_media;
    int m_busy = 0;
    QTimer m_mediaTimer;
};

// Sonidos del sistema (originales de BC OS, en /usr/share/sounds/bc/<nombre>.wav): se reproducen con pw-play o paplay
// si «Sonidos de la interfaz» está activado en Ajustes.
class SoundPlayer : public QObject {
    Q_OBJECT
public:
    using QObject::QObject;
    Q_INVOKABLE void play(const QString &name);
};
