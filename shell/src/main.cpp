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

static int g_warnings = 0;
static QtMessageHandler g_prev = nullptr;
static void countingHandler(QtMsgType t, const QMessageLogContext &c, const QString &m) {
    if (t == QtWarningMsg || t == QtCriticalMsg || t == QtFatalMsg) ++g_warnings;
    g_prev(t, c, m);
}

int main(int argc, char *argv[]) {
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
    QCommandLineOption oFixed("fixed-time", "Hora fija ISO-8601", "iso");
    p.addOptions({oLang, oShot, oCheck, oTitle, oReduced, oFixed});
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

    AppConfig cfg(lang, reduced, fixed);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "AppConfig", &cfg);

    g_prev = qInstallMessageHandler(countingHandler);
    QQmlApplicationEngine engine;
    engine.load(QUrl("qrc:/BCShell/Main.qml"));
    if (engine.rootObjects().isEmpty()) return 2;
    auto *win = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
    if (!win) return 2;

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
