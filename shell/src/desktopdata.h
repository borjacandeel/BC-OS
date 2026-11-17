#pragma once
#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>
#include <QPoint>
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
    Q_PROPERTY(QStringList refreshRates READ refreshRates NOTIFY displayModesChanged)
    // Posición de la ventana de esta app en la pantalla (para el cristal de las barras laterales); se sigue con sway
    Q_PROPERTY(QPoint windowPos READ windowPos NOTIFY windowPosChanged)
    Q_PROPERTY(bool trackWindow READ trackWindow WRITE setTrackWindow NOTIFY windowPosChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)   // sondeo de reproducción solo con el panel visible
    // Con Hyprland el compositor desenfoca de verdad lo que hay detrás: el cristal no pinta el fondo precalculado
    Q_PROPERTY(bool realBlur READ realBlur CONSTANT)
    // Render por software (sway sin GPU): las animaciones evitan escalados, que cuestan mucha CPU
    Q_PROPERTY(bool softwareRender READ softwareRender CONSTANT)
public:
    bool active() const { return m_mediaTimer.isActive(); }
    static bool softwareRender() { return qEnvironmentVariable("QT_QUICK_BACKEND") == "software" || qEnvironmentVariable("QT_QUICK_BACKEND") == "softwarecontext"; }
    static bool realBlur() { return qEnvironmentVariable("BC_COMPOSITOR") == "hyprland" || !qEnvironmentVariable("HYPRLAND_INSTANCE_SIGNATURE").isEmpty(); }
    void setActive(bool on) { if (on == active()) return; if (on) { refreshMedia(); m_mediaTimer.start(); } else m_mediaTimer.stop(); emit activeChanged(); }
    explicit QuickTools(QObject *parent = nullptr);
    QVariantList networks() const { return m_networks; }
    QVariantList btDevices() const { return m_bt; }
    QVariantMap media() const { return m_media; }
    QVariantList fileResults() const { return m_files; }
    QStringList displayModes() const { return m_modes; }
    QStringList refreshRates() const { return m_rates; }
    QPoint windowPos() const { return m_winPos; }
    bool trackWindow() const { return m_winTimer.isActive(); }
    void setTrackWindow(bool on);
    Q_INVOKABLE void refreshWindowPos() { if (m_winTimer.isActive()) { pollWindow(); QTimer::singleShot(300, this, &QuickTools::pollWindow); } }
    // Arrastre de la ventana: sigue su posición a ~60 Hz (socket IPC de sway) hasta que se queda quieta
    Q_INVOKABLE void followWindowMove();
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
    Q_INVOKABLE QString savedDisplayMode() const;              // la recordada por bc-display o «auto»
    Q_INVOKABLE void setRefreshRate(const QString &hz);        // «60», «144»… o «auto» (la más alta)
    Q_INVOKABLE QString savedRefreshRate() const;
    Q_INVOKABLE bool setKeyboardLayout(const QString &code);   // es, us, gb, fr, de, it, pt, latam
    Q_INVOKABLE static QString keyboardLayout();
    // Datos JSON de las apps (Calendario…): ~/.local/share/bc/<nombre>.json (nombre: letras minúsculas y guiones)
    Q_INVOKABLE static QString readData(const QString &name);
    Q_INVOKABLE static bool writeData(const QString &name, const QString &json);
    // Archivos ▸ Recientes: ~/.local/share/recently-used.xbel (estándar freedesktop que escriben GTK y Qt)
    Q_INVOKABLE static QVariantList recentFiles(int max = 120);
    // Dónde se ejecuta BC OS: «vm» (máquina virtual: render por software, sin efectos de GPU) o «fisico» (equipo real:
    // GPU, swayfx con desenfoque, sombras y esquinas). Se guarda en ~/.config/bc/equipo y lo lee bc-session.
    Q_INVOKABLE static QString detectedMachine();   // detección automática (systemd-detect-virt / DMI)
    Q_INVOKABLE static QString machineKind();       // elección guardada o, si no hay, la detectada
    Q_INVOKABLE static bool setMachineKind(const QString &kind);
    Q_INVOKABLE static bool hasGpu();               // hay /dev/dri/renderD*
    // Esquinas redondeadas en todas las ventanas sin 3D (swayfx por software): ~/.config/bc/esquinas («no» las quita)
    Q_INVOKABLE static bool roundedCorners();
    // ¿La franja superior del fondo es clara? (texto oscuro en la barra de menús, como macOS). "" = fondo por defecto
    Q_INVOKABLE static bool wallpaperTopLight(const QString &path);
    Q_INVOKABLE static bool setRoundedCorners(bool on);
    // Bloqueo a prueba de fallos: marca en $XDG_RUNTIME_DIR/bc-bloqueado mientras la pantalla está bloqueada.
    // Si el panel se cae bloqueado, la sesión lanza swaylock y el panel, al volver, se vuelve a bloquear.
    Q_INVOKABLE static void setLockFlag(bool on);
    Q_INVOKABLE static bool lockFlag();
    // Instantáneas del sistema (/var/lib/bc/instantaneas, las crea un gancho de pacman): [{id, fecha, paquetes}]
    Q_INVOKABLE static QVariantList snapshots();
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
    void windowPosChanged();
    void captured(const QString &tag, const QString &path, bool ok);
private:
    void run(const QString &prog, const QStringList &args, std::function<void(int, const QString &)> done);
    QVariantList m_networks, m_bt, m_files;
    QStringList m_modes;
    QStringList m_rates;
    QPoint m_winPos;
    QTimer m_winTimer;
    QTimer m_fastTimer;
    int m_still = 0;
    class QLocalSocket *m_ipc = nullptr;
    QByteArray m_ipcBuf;
    bool m_ipcBusy = false;
    void handleTree(const QByteArray &json);
    void pollWindow();
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

// Música: biblioteca de ~/Música y reproducción con mpv (controlado por su socket IPC JSON).
class MusicPlayer : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList songs READ songs NOTIFY libraryChanged)   // [{path, title, artist, album}]
    Q_PROPERTY(int current READ current NOTIFY stateChanged)
    Q_PROPERTY(bool playing READ playing NOTIFY stateChanged)
    Q_PROPERTY(double position READ position NOTIFY progressChanged)
    Q_PROPERTY(double duration READ duration NOTIFY progressChanged)
    Q_PROPERTY(bool available READ available CONSTANT)
public:
    explicit MusicPlayer(QObject *parent = nullptr);
    ~MusicPlayer() override;
    QVariantList songs() const { return m_songs; }
    int current() const { return m_current; }
    bool playing() const { return m_playing; }
    double position() const { return m_pos; }
    double duration() const { return m_dur; }
    bool available() const;
    Q_INVOKABLE void scan();
    Q_INVOKABLE void play(int index);
    Q_INVOKABLE void toggle();
    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();
    Q_INVOKABLE void seek(double seconds);
    static QVariantMap describe(const QString &path);
signals:
    void libraryChanged();
    void stateChanged();
    void progressChanged();
private:
    void send(const QByteArray &json);
    void poll();
    QVariantList m_songs;
    int m_current = -1;
    bool m_playing = false;
    double m_pos = 0, m_dur = 0;
    class QProcess *m_mpv = nullptr;
    class QLocalSocket *m_sock = nullptr;
    QTimer m_timer;
    QString m_sockPath;
};
