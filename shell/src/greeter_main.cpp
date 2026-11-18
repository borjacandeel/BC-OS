#include <QQuickImageProvider>
#include <QUrl>
#include <QCommandLineParser>
#include <QDebug>
#include <QFile>
#include <QGuiApplication>
#include <QImage>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QTimer>
#include <QTranslator>
#include <QtQml/qqml.h>
#include "appconfig.h"
#include "appsettings.h"
#include "greetd.h"
#include "powercontrol.h"
#include "sessionlist.h"
#include "userlist.h"

static int g_warnings = 0;
static QtMessageHandler g_prev = nullptr;
static void countingHandler(QtMsgType t, const QMessageLogContext &c, const QString &m) {
    if (t == QtWarningMsg || t == QtCriticalMsg || t == QtFatalMsg) ++g_warnings;
    g_prev(t, c, m);
}

int main(int argc, char *argv[]) {
    qputenv("QML_XHR_ALLOW_FILE_READ", "1");
    QGuiApplication app(argc, argv);
    app.setApplicationName("bc-greeter");
    app.setOrganizationName("BC-OS");

    QCommandLineParser p;
    p.addHelpOption();
    QCommandLineOption oLang("lang", "Idioma", "idioma");
    QCommandLineOption oShot("screenshot", "Guardar captura PNG", "archivo");
    QCommandLineOption oCheck("check", "Verificación: sale con error si hay avisos QML");
    QCommandLineOption oSize("size", "Tamaño de ventana", "AnchoxAlto");
    QCommandLineOption oReduced("reduced-motion", "Movimiento reducido");
    QCommandLineOption oFixed("fixed-time", "Hora fija ISO-8601", "iso");
    QCommandLineOption oTest("test-login", "Prueba: usuario:contraseña", "u:p");
    QCommandLineOption oPasswd("passwd", "Fichero passwd alternativo", "ruta");
    p.addOptions({oLang, oShot, oCheck, oSize, oReduced, oFixed, oTest, oPasswd});
    p.process(app);

    QString lang = p.value(oLang);
    if (lang.isEmpty()) lang = qEnvironmentVariable("BC_LANG", qEnvironmentVariable("LANG", "es_ES").left(5));
    if (!lang.startsWith("en")) lang = "es_ES"; else lang = "en";
    const bool reduced = p.isSet(oReduced) || qEnvironmentVariable("BC_REDUCED_MOTION") == "1";
    QString fixed = p.isSet(oFixed) ? p.value(oFixed) : qEnvironmentVariable("BC_FIXED_TIME");
    if (p.isSet(oShot) && fixed.isEmpty()) fixed = "2026-11-14T07:03:00";

    QTranslator tr;
    if (tr.load(QLocale(lang), "bcshell", "_", ":/i18n")) app.installTranslator(&tr);

    AppConfig cfg(lang, reduced, fixed);
    GreetdClient greetd;
    PowerControl power;
    UserList users(p.value(oPasswd));
    AppSettings appSettings;
    SessionList sessions;
    qmlRegisterSingletonInstance("BCShell", 1, 0, "AppConfig", &cfg);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Greetd", &greetd);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Power", &power);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Users", &users);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Settings", &appSettings);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Sessions", &sessions);
    auto applySession = [&] { greetd.setSession(sessions.currentCommand(), sessions.currentEnv()); };
    QObject::connect(&sessions, &SessionList::currentChanged, &app, applySession);
    applySession();

    const QString counter = qEnvironmentVariable("BC_GREETER_DIR", "/run/bc-greeter") + "/count";
    QObject::connect(&greetd, &GreetdClient::succeeded, &app, [&] {
        sessions.rememberLast(sessions.currentId());
        QFile f(counter);
        if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) f.write("0\n");
    });

    g_prev = qInstallMessageHandler(countingHandler);
    QQmlApplicationEngine engine;
    // «image://blur/<ruta>»: el fondo del usuario muy desenfocado (como el login de macOS), calculado una vez
    class BlurProvider : public QQuickImageProvider {
    public:
        BlurProvider() : QQuickImageProvider(QQuickImageProvider::Image) {}
        QImage requestImage(const QString &id, QSize *size, const QSize &req) override {
            QString path = QUrl::fromPercentEncoding(id.toUtf8());
            QImage src(path);
            if (src.isNull()) src = QImage(":/BCShell/assets/wallpaper-default.png");
            const QSize out = req.isValid() ? req : QSize(1920, 1080);
            src = src.scaled(out, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);
            // Reducción por mitades (promedia y quita el tramado) y ampliación suave: desenfoque gaussiano amplio
            QImage small = src.convertToFormat(QImage::Format_RGB32);
            while (small.width() > 48) small = small.scaled(small.width() / 2, small.height() / 2, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
            // Ampliación de 2 en 2 (cada paso bilineal suaviza el anterior): sin los bloques que dejaba ampliar ×10 de golpe
            QImage res = small;
            while (res.width() * 2 < src.width()) res = res.scaled(res.width() * 2, res.height() * 2, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
            res = res.scaled(src.size(), Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
            if (size) *size = res.size();
            return res;
        }
    };
    engine.addImageProvider("blur", new BlurProvider);
    QObject::connect(&engine, &QQmlEngine::quit, &app, [] { QCoreApplication::exit(0); });   // Qt.quit() de QML
    engine.load(QUrl("qrc:/BCShell/Greeter.qml"));
    if (engine.rootObjects().isEmpty()) return 2;
    auto *win = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
    if (!win) return 2;

    if (p.isSet(oSize)) {
        const QStringList wh = p.value(oSize).split('x');
        if (wh.size() == 2 && wh[0].toInt() > 0 && wh[1].toInt() > 0) win->resize(wh[0].toInt(), wh[1].toInt());
        else { qCritical() << "--size inválido"; return 2; }
    }

    if (p.isSet(oTest)) {
        const QStringList up = p.value(oTest).split(':');
        QObject::connect(&greetd, &GreetdClient::succeeded, &app, [&] { app.exit(0); });
        QObject::connect(&greetd, &GreetdClient::authFailed, &app, [&] { app.exit(10); });
        QObject::connect(&greetd, &GreetdClient::errorOccurred, &app, [&](const QString &m) { qCritical() << m; app.exit(11); });
        QTimer::singleShot(800, &app, [&, up] { greetd.login(up.value(0), up.value(1)); });
        QTimer::singleShot(10000, &app, [&] { app.exit(12); });
    } else if (p.isSet(oShot) || p.isSet(oCheck)) {
        QTimer::singleShot(1800, &app, [&] {
            int rc = 0;
            if (p.isSet(oShot)) {
                QImage img = win->grabWindow();
                if (img.isNull() || !img.save(p.value(oShot))) { qCritical() << "Fallo al guardar captura"; rc = 3; }
            }
            if (p.isSet(oCheck) && g_warnings != 0) { qCritical() << "Avisos QML:" << g_warnings; rc = 5; }
            app.exit(rc);
        });
    }
    return app.exec();
}
