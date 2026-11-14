#include <QCommandLineParser>
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
#include "powercontrol.h"
#include "systemstatus.h"
#include "userlist.h"
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
    p.addOptions({oLang, oShot, oCheck, oTitle, oReduced, oNoSplash, oFixed, oSize});
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

    const bool splash = !(p.isSet(oShot) || p.isSet(oCheck)) && !p.isSet(oNoSplash);
    AppConfig cfg(lang, reduced, fixed, nullptr, splash);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "AppConfig", &cfg);

    Launcher launcher;
    FileBrowser files;
    PamAuth pam;
    SystemStatus status;
    PowerControl power;
    UserList users;
    qmlRegisterSingletonInstance("BCShell", 1, 0, "PamAuth", &pam);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "SystemStatus", &status);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Power", &power);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Users", &users);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Launcher", &launcher);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Files", &files);

    g_prev = qInstallMessageHandler(countingHandler);
    QQmlApplicationEngine engine;
    engine.load(QUrl("qrc:/BCShell/Main.qml"));
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
