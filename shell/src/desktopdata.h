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
    Q_PROPERTY(QStringList displayModes READ displayModes NOTIFY displayModesChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)   // sondeo de reproducción solo con el panel visible
public:
    bool active() const { return m_mediaTimer.isActive(); }
    void setActive(bool on) { if (on == active()) return; if (on) { refreshMedia(); m_mediaTimer.start(); } else m_mediaTimer.stop(); emit activeChanged(); }
    explicit QuickTools(QObject *parent = nullptr);
    QVariantList networks() const { return m_networks; }
    QVariantList btDevices() const { return m_bt; }
    QVariantMap media() const { return m_media; }
    QVariantList fileResults() const { return m_files; }
    QStringList displayModes() const { return m_modes; }
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
    Q_INVOKABLE static QString iconPath(const QString &name); // ruta del icono del tema (vacía si no existe)
    // Ajustes del Sistema ▸ Pantallas y Teclado
    Q_INVOKABLE void listDisplayModes();                       // → displayModes
    Q_INVOKABLE void setDisplayMode(const QString &mode);      // «1920x1080» o «auto»
    Q_INVOKABLE bool setKeyboardLayout(const QString &code);   // es, us, gb, fr, de, it, pt, latam
    Q_INVOKABLE static QString keyboardLayout();
    // Datos JSON de las apps (Calendario…): ~/.local/share/bc/<nombre>.json (nombre: letras minúsculas y guiones)
    Q_INVOKABLE static QString readData(const QString &name);
    Q_INVOKABLE static bool writeData(const QString &name, const QString &json);
    // Captura con grim de la pantalla (geom vacía) o de una región «x,y wxh» → señal captured(tag, ruta)
    Q_INVOKABLE void capture(const QString &tag, const QString &geom);
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
    void displayModesChanged();
    void captured(const QString &tag, const QString &path, bool ok);
private:
    void run(const QString &prog, const QStringList &args, std::function<void(int, const QString &)> done);
    QVariantList m_networks, m_bt, m_files;
    QStringList m_modes;
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

// Monitor de Actividad: procesos reales de /proc (CPU % entre muestras, memoria residente, hilos, usuario).
class Processes : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList list READ list NOTIFY changed)   // [{pid, name, cpu, cpuTime, mem, memText, threads, user, mine}]
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(QString sortKey READ sortKey WRITE setSortKey NOTIFY changed)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY changed)
    Q_PROPERTY(int threadCount READ threadCount NOTIFY changed)
    Q_PROPERTY(double userCpu READ userCpu NOTIFY changed)
    Q_PROPERTY(double systemCpu READ systemCpu NOTIFY changed)
public:
    explicit Processes(QObject *parent = nullptr);
    QVariantList list() const { return m_list; }
    bool active() const { return m_timer.isActive(); }
    void setActive(bool on);
    QString sortKey() const { return m_sort; }
    void setSortKey(const QString &k) { if (k != m_sort) { m_sort = k; rebuild(); } }
    QString filter() const { return m_filter; }
    void setFilter(const QString &f) { if (f != m_filter) { m_filter = f; rebuild(); } }
    int threadCount() const { return m_threads; }
    double userCpu() const { return m_userCpu; }
    double systemCpu() const { return m_sysCpu; }
    Q_INVOKABLE void refresh();
    Q_INVOKABLE bool quit(int pid, bool force = false);   // «Salir» / «Forzar salida» (solo procesos propios)
signals:
    void changed();
    void activeChanged();
private:
    void rebuild();
    QTimer m_timer;
    QHash<int, qulonglong> m_prevTicks;
    qulonglong m_prevTotal = 0, m_prevUser = 0, m_prevSys = 0;
    QVariantList m_all, m_list;
    QString m_sort = "cpu", m_filter;
    int m_threads = 0;
    double m_userCpu = 0, m_sysCpu = 0;
};

// Notas: cada nota es un archivo de texto en ~/.local/share/bc/notas (la primera línea es el título).
// Eliminar las mueve a «Eliminadas recientemente» (subcarpeta .eliminadas).
class NotesStore : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList notes READ notes NOTIFY changed)       // [{id, title, snippet, date, modified}]
    Q_PROPERTY(QVariantList deleted READ deleted NOTIFY changed)
public:
    explicit NotesStore(QObject *parent = nullptr, const QString &dir = QString());
    QVariantList notes() const { return m_notes; }
    QVariantList deleted() const { return m_deleted; }
    Q_INVOKABLE QString create();                          // devuelve el id de la nota nueva
    Q_INVOKABLE QString text(const QString &id) const;
    Q_INVOKABLE void save(const QString &id, const QString &text);
    Q_INVOKABLE void remove(const QString &id);            // a Eliminadas recientemente (o definitivo si ya estaba)
    Q_INVOKABLE void restore(const QString &id);
    Q_INVOKABLE void reload();
signals:
    void changed();
private:
    QString path(const QString &id) const;
    QVariantList scan(const QString &dir) const;
    QString m_dir;
    QVariantList m_notes, m_deleted;
};
