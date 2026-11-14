#pragma once
#include <QFileSystemWatcher>
#include <QObject>
#include <QProcess>
#include <QTimer>
#include <QVariantList>

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

    // Analiza la salida de `swaymsg -t get_tree` (pruebas).
    static QVariantList parseTree(const QByteArray &json);
    static QString modeFilePath();
signals:
    void windowsChanged();
    void tilingChanged();
    void chromeChanged();

private:
    void readMode();
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
};
