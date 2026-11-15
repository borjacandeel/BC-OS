#pragma once
#include <QObject>
#include <QVariantMap>

// Servicio D-Bus org.bcos.Shell del panel: lo usan los atajos de sway (busctl) y los menús de las apps.
class ShellControl : public QObject {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.bcos.Shell")
public:
    explicit ShellControl(QObject *parent = nullptr) : QObject(parent) {}
    bool start();
    // Envía una acción a una app de BC (org.bcos.App.<nombre>.Invoke).
    Q_INVOKABLE void invokeApp(const QString &app, const QString &action);
public slots:
    void ToggleLauncher() { emit launcherToggled(); }
    void ToggleControlCenter() { emit controlCenterToggled(); }
    void Lock() { emit lockRequested(); }
    void ToggleTiling() { emit tilingToggled(); }
    void Power(const QString &action) { emit powerRequested(action); }
    void ToggleClipboard() { emit clipboardToggled(); }
    void ShowWelcome() { emit welcomeRequested(); }
    void ShowOsd(const QString &kind) { if (kind == "volume" || kind == "brightness") emit osdRequested(kind); }
    void SetStyle(const QString &style) { emit styleChanged(style); }
    void SetOption(const QString &key, const QString &value);   // valida clave y valor antes de emitir
    // Golden Gate: spotlight, mission, switcher, switcher-back, launchpad, notifications, minimize, appearance
    void Action(const QString &name) {
        static const QStringList ok{"spotlight", "mission", "switcher", "switcher-back", "launchpad", "notifications", "minimize", "appearance", "desktop"};
        if (ok.contains(name)) emit actionRequested(name);
    }
signals:
    void actionRequested(const QString &name);
    void launcherToggled();
    void controlCenterToggled();
    void lockRequested();
    void tilingToggled();
    void powerRequested(const QString &action);
    void styleChanged(const QString &style);
    void welcomeRequested();
    void clipboardToggled();
    void osdRequested(const QString &kind);
    void optionChanged(const QString &key, const QString &value);
};

// Servicio D-Bus de una app de BC (org.bcos.App.<nombre>): recibe acciones del menú global.
class AppActions : public QObject {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.bcos.App")
public:
    explicit AppActions(const QString &name, QObject *parent = nullptr);
    bool start();
public slots:
    void Invoke(const QString &action) { emit actionInvoked(action); }
signals:
    void actionInvoked(const QString &action);

private:
    QString m_name;
};

// Cliente de notificaciones para las apps (singleton «Notifications» en modo app): envía por D-Bus al panel.
class NotificationClient : public QObject {
    Q_OBJECT
public:
    explicit NotificationClient(QObject *parent = nullptr) : QObject(parent) {}
    Q_INVOKABLE void push(const QString &app, const QString &title, const QString &body, const QString &icon, int timeoutMs = 5000);
};

// Control de la ventana propia de una app (minimizar a scratchpad / pantalla completa) vía swaymsg.
class WindowControl : public QObject {
    Q_OBJECT
public:
    explicit WindowControl(QObject *parent = nullptr) : QObject(parent) {}
    Q_INVOKABLE void minimize();
    Q_INVOKABLE void toggleFullscreen();
};
