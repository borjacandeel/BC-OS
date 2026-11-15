#pragma once
#include <QFileSystemWatcher>
#include <QHash>
#include <QLocalSocket>
#include <QObject>
#include <QProcess>
#include <QTimer>
#include <QVariantList>
#include <functional>

// Control de sway por IPC (swaymsg): lista de ventanas, enfocar/minimizar/cerrar y modo mosaico/flotante.
class SwayControl : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool available READ available CONSTANT)
    Q_PROPERTY(QVariantList windows READ windows NOTIFY windowsChanged)
    Q_PROPERTY(QStringList appIds READ appIds NOTIFY windowsChanged)
    Q_PROPERTY(int focusedId READ focusedId NOTIFY windowsChanged)
    Q_PROPERTY(QString focusedAppId READ focusedAppId NOTIFY windowsChanged)
    Q_PROPERTY(QString focusedTitle READ focusedTitle NOTIFY windowsChanged)
    Q_PROPERTY(bool tiling READ tiling NOTIFY tilingChanged)
    Q_PROPERTY(QVariantList chromeWindows READ chromeWindows NOTIFY chromeChanged)
    Q_PROPERTY(QVariantList workspaces READ workspaces NOTIFY workspacesChanged)   // escritorios (Mission Control)
    Q_PROPERTY(QString layout READ layout NOTIFY layoutChanged)                  // fuente de entrada: «ES»
public:
    explicit SwayControl(QObject *parent = nullptr);
    bool available() const { return m_available; }
    QVariantList windows() const { return m_windows; }
    QStringList appIds() const { return m_appIds; }
    int focusedId() const { return m_focusedId; }
    QString focusedAppId() const { return m_focusedApp; }
    QString focusedTitle() const { return m_focusedTitle; }
    bool tiling() const { return m_tiling; }
    QVariantList chromeWindows() const { return m_chrome; }
    QVariantList workspaces() const { return m_workspaces; }
    QString layout() const { return m_layout; }
    Q_INVOKABLE void switchWorkspace(const QString &name);
    Q_INVOKABLE void moveToWorkspace(int id, const QString &name);
    static QVariantList parseWorkspaces(const QByteArray &json);
    static QString parseLayout(const QByteArray &json);

    Q_INVOKABLE void command(const QString &cmd);
    Q_INVOKABLE void focusWindow(int id);
    Q_INVOKABLE void closeWindow(int id);
    Q_INVOKABLE void minimizeWindow(int id);
    Q_INVOKABLE void toggleFullscreen(int id);
    Q_INVOKABLE bool hasApp(const QString &appId) const { return m_appIds.contains(appId); }
    // Enfoca (o restaura si está minimizada) la primera ventana de la app; devuelve false si no hay ninguna.
    Q_INVOKABLE bool focusApp(const QString &appId);
    Q_INVOKABLE void toggleTiling();
    Q_INVOKABLE void setTiling(bool on);
    Q_INVOKABLE void refresh();

    Q_PROPERTY(bool hyprland READ hyprland CONSTANT)
    bool hyprland() const { return m_hypr; }
    // Hyprland: traduce una orden de sway (las que usa BC Shell) a despachos de hyprctl (pruebas)
    static QStringList translateToHyprland(const QString &swayCmd, const QHash<int, QString> &addr, const QString &activeWs);
    static QVariantList parseHyprClients(const QByteArray &clients, QHash<int, QString> *addr = nullptr);
    // Analiza la salida de `swaymsg -t get_tree` (pruebas).
    static QVariantList parseTree(const QByteArray &json);
    static QString modeFilePath();
signals:
    void windowsChanged();
    void tilingChanged();
    void chromeChanged();
    void workspacesChanged();
    void layoutChanged();

private:
    void readMode();
    void refreshHypr();
    void hyprConnect();
    bool m_hypr = false;
    QHash<int, QString> m_addr;      // id entero → dirección de Hyprland (0x…)
    QString m_activeWs = "1";
    QLocalSocket m_hyprEvents;
    QString m_exe;
    bool m_available = false;
    QVariantList m_windows, m_chrome;
    QStringList m_appIds;
    int m_focusedId = -1;
    QString m_focusedApp, m_focusedTitle;
    bool m_tiling = false;
    QProcess m_events;
    QTimer m_debounce, m_poll;
    QFileSystemWatcher m_watch;
    bool m_busy = false;
    QVariantList m_workspaces;
    QString m_layout;
    int m_inputTick = 0;
    void query(const QString &type, std::function<void(const QByteArray &)> done);
};
