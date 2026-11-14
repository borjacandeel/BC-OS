#include <QCommandLineParser>
#include <memory>
#include <QDebug>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QSettings>
#include <QTimer>
#include <QTranslator>
#include <QtQml/qqml.h>
#include "appconfig.h"
#include "pamauth.h"
#include "appindex.h"
#include "appsettings.h"
#include "notifications.h"
#include "packagestore.h"
#include "powercontrol.h"
#include "sysmonitor.h"
#include "systemstatus.h"
#include "userlist.h"
#include "swaycontrol.h"
#include "layerhelper.h"
#include "shellcontrol.h"
#include "clipboardhistory.h"
#include "updatechecker.h"
#include "filebrowser.h"
#include "launcher.h"

static int g_warnings = 0;
static QtMessageHandler g_prev = nullptr;
static void countingHandler(QtMsgType t, const QMessageLogContext &c, const QString &m) {
    if (t == QtWarningMsg || t == QtCriticalMsg || t == QtFatalMsg) ++g_warnings;
    g_prev(t, c, m);
}

int main(int argc, char *argv[]) {
    // IconCache lee los SVG de los recursos (qrc:) con XMLHttpRequest para teñirlos.
    qputenv("QML_XHR_ALLOW_FILE_READ", "1");
    QGuiApplication app(argc, argv);
    app.setApplicationName("bc-shell");
    app.setOrganizationName("BC-OS");

    QCommandLineParser p;
    p.addHelpOption();
    QCommandLineOption oLang("lang", "Idioma (es_ES, en)", "idioma");
    QCommandLineOption oShot("screenshot", "Guardar captura PNG", "archivo");
    QCommandLineOption oCheck("check", "Verificación: sale con error si hay avisos QML y termina");
    QCommandLineOption oTitle("expect-title", "Título de notificación esperado", "texto");
    QCommandLineOption oReduced("reduced-motion", "Movimiento reducido");
    QCommandLineOption oNoSplash("no-splash", "Sin pantalla de carga");
    QCommandLineOption oFixed("fixed-time", "Hora fija ISO-8601", "iso");
    QCommandLineOption oSize("size", "Tamaño de ventana, p. ej. 1280x800", "AxA");
    QCommandLineOption oPanel("panel", "Modo panel (por defecto): barra, Dock y ventanas emergentes");
    QCommandLineOption oApp("app", "Modo aplicación: files, monitor, settings o store", "nombre");
    QCommandLineOption oOpen("open", "Argumento de apertura de la app (carpeta o «trash»)", "arg");
    p.addOptions({oPanel, oApp, oOpen, oLang, oShot, oCheck, oTitle, oReduced, oNoSplash, oFixed, oSize});
    p.process(app);

    QSettings st;
    QString lang = p.value(oLang);
    if (lang.isEmpty()) lang = qEnvironmentVariable("BC_LANG");
    if (lang.isEmpty()) lang = st.value("idioma", "es_ES").toString();
    const bool reduced = p.isSet(oReduced) || qEnvironmentVariable("BC_REDUCED_MOTION") == "1"
                         || st.value("movimientoReducido", false).toBool();
    QString fixed = p.isSet(oFixed) ? p.value(oFixed) : qEnvironmentVariable("BC_FIXED_TIME");
    if (p.isSet(oShot) && fixed.isEmpty()) fixed = "2026-11-13T18:11:00";

    QTranslator tr;
    if (tr.load(QLocale(lang), "bcshell", "_", ":/i18n")) app.installTranslator(&tr);
    else qWarning() << "No se pudo cargar la traducción" << lang;

    const QString appName = p.value(oApp);
    const bool appMode = !appName.isEmpty();
    if (appMode) {
        static const QStringList known{"files", "monitor", "settings", "store"};
        if (!known.contains(appName)) { qCritical() << "App desconocida:" << appName; return 2; }
        app.setDesktopFileName("bc-" + appName);  // app_id en sway
        app.setApplicationName("bc-" + appName);
    }
    const bool splash = !appMode && !(p.isSet(oShot) || p.isSet(oCheck)) && !p.isSet(oNoSplash);
    AppConfig cfg(lang, reduced, fixed, nullptr, splash);
    cfg.setOpenArg(p.value(oOpen));
    qmlRegisterSingletonInstance("BCShell", 1, 0, "AppConfig", &cfg);

    // Objetos compartidos por ambos modos
    Launcher launcher;
    FileBrowser files;
    AppSettings appSettings;
    SysMonitor monitor;
    PackageStore store;
    SystemStatus status;
    UserList users;
    LayerHelper layer;
    WindowControl windowControl;
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Settings", &appSettings);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Monitor", &monitor);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Store", &store);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "SystemStatus", &status);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Users", &users);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Launcher", &launcher);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Files", &files);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Layer", &layer);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "WindowControl", &windowControl);

    // Solo del panel
    PamAuth pam;
    AppIndex apps({}, lang);
    std::unique_ptr<SwayControl> swayPtr;
    ShellControl shell;
    NotificationQueue notifications;
    NotificationServer notifServer(&notifications);
    PowerControl power;
    ClipboardHistory clipboard;
    std::unique_ptr<UpdateChecker> updates;
    if (!appMode) { swayPtr = std::make_unique<SwayControl>(); if (!(p.isSet(oShot) || p.isSet(oCheck))) updates = std::make_unique<UpdateChecker>(); }
    // Solo de las apps
    NotificationClient notifClient;
    AppActions actions(appName);
    if (!appMode) {
        notifications.setDnd(status.dnd());
        QObject::connect(&status, &SystemStatus::changed, &notifications, [&] { notifications.setDnd(status.dnd()); });
        qmlRegisterSingletonInstance("BCShell", 1, 0, "PamAuth", &pam);
        qmlRegisterSingletonInstance("BCShell", 1, 0, "Apps", &apps);
        qmlRegisterSingletonInstance("BCShell", 1, 0, "Sway", swayPtr.get());
        qmlRegisterSingletonInstance("BCShell", 1, 0, "Shell", &shell);
        qmlRegisterSingletonInstance("BCShell", 1, 0, "Notifications", &notifications);
        qmlRegisterSingletonInstance("BCShell", 1, 0, "Power", &power);
        qmlRegisterSingletonInstance("BCShell", 1, 0, "Clipboard", &clipboard);
        if (updates) QObject::connect(updates.get(), &UpdateChecker::updatesFound, &notifications, [&notifications](int n) {
            notifications.push("BC OS", QObject::tr("Actualizaciones disponibles"), QObject::tr("%1 paquetes pueden actualizarse desde la Tienda").arg(n), "", 8000);
        });
        qmlRegisterSingletonInstance("BCShell", 1, 0, "AppActions", &actions);
        if (!(p.isSet(oShot) || p.isSet(oCheck))) { notifServer.start(); shell.start(); }
    } else {
        qmlRegisterSingletonInstance("BCShell", 1, 0, "Notifications", &notifClient);
        qmlRegisterSingletonInstance("BCShell", 1, 0, "AppActions", &actions);
        if (!actions.start()) qWarning() << "[app] no se pudo registrar el servicio D-Bus de la app";
    }

    g_prev = qInstallMessageHandler(countingHandler);
    QQmlApplicationEngine engine;
    if (appMode) {
        const QString n = appName.left(1).toUpper() + appName.mid(1);
        engine.load(QUrl("qrc:/BCShell/" + n + "App.qml"));
    } else {
        engine.load(QUrl("qrc:/BCShell/Panel.qml"));
    }
    if (engine.rootObjects().isEmpty()) return 2;
    auto *win = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
    if (!win) return 2;

    if (p.isSet(oSize)) {
        const QStringList wh = p.value(oSize).split('x');
        if (wh.size() == 2 && wh[0].toInt() > 0 && wh[1].toInt() > 0) {
            win->resize(wh[0].toInt(), wh[1].toInt());
        } else { qCritical() << "--size inválido"; return 2; }
    }

    if (p.isSet(oShot) || p.isSet(oCheck)) {
        QTimer::singleShot(1500, &app, [&] {
            int rc = 0;
            if (p.isSet(oShot)) {
                QImage img = win->grabWindow();
                if (img.isNull() || !img.save(p.value(oShot))) {
                    qCritical() << "Fallo al guardar captura";
                    rc = 3;
                }
            }
            if (p.isSet(oCheck)) {
                const int errs = win->property("loadErrors").toInt();
                if (errs != 0) { qCritical() << "Componentes con error:" << errs; rc = 4; }
                if (g_warnings != 0) { qCritical() << "Avisos QML:" << g_warnings; rc = 5; }
                if (p.isSet(oTitle) && win->property("notifTitle").toString() != p.value(oTitle)) {
                    qCritical() << "Título inesperado:" << win->property("notifTitle").toString();
                    rc = 6;
                }
            }
            app.exit(rc);
        });
    }
    return app.exec();
}
