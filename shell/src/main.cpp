#include <QCommandLineParser>
#include <memory>
#include <QDebug>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QPainter>
#include <QSettings>
#include <QTimer>
#include <QElapsedTimer>
#include "installer.h"
#include <QQmlExpression>
#include <QRegularExpression>
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
#include "sessionlist.h"
#include "filebrowser.h"
#include "launcher.h"
#include "glassprovider.h"
#include "genieitem.h"
#include "geniemesh.h"
#include "desktopdata.h"
#include "renderengine.h"

static int g_warnings = 0;
static QtMessageHandler g_prev = nullptr;
static void countingHandler(QtMsgType t, const QMessageLogContext &c, const QString &m) {
    if (t == QtWarningMsg || t == QtCriticalMsg || t == QtFatalMsg) ++g_warnings;
    g_prev(t, c, m);
}

int main(int argc, char *argv[]) {
    // Texto nítido con hinting nativo (como macOS en pantallas sin Retina); con GPU sigue siendo nítido
    QQuickWindow::setTextRenderType(QQuickWindow::NativeTextRendering);
    // IconCache lee los SVG de los recursos (qrc:) con XMLHttpRequest para teñirlos.
    qputenv("QML_XHR_ALLOW_FILE_READ", "1");
    // El tema de plataforma GTK es para las apps Qt de terceros; BC Shell dibuja su propio aspecto.
    // Se quita solo para este proceso y se devuelve al entorno para que lo hereden las apps que abre.
    const QByteArray platformTheme = qgetenv("QT_QPA_PLATFORMTHEME");
    qunsetenv("QT_QPA_PLATFORMTHEME");
    // BC Adaptive Renderer: backend de Qt Quick (vulkan → opengl → software) antes de crear ventanas
    RenderEngine::configureBackend();
    QGuiApplication app(argc, argv);
    if (!platformTheme.isEmpty()) qputenv("QT_QPA_PLATFORMTHEME", platformTheme);
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
    QCommandLineOption oApp("app", "Modo aplicación: files, monitor, settings, store, calculator, notes o preview", "nombre");
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
        static const QStringList known{"files", "monitor", "settings", "store", "calculator", "notes", "preview", "reminders", "calendar", "music", "installer"};
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
    SessionList sessionList;
    WindowControl windowControl;
    Batteries batteries;
    Reminders reminders;
    SoundPlayer sounds;
    Processes processes;
    NotesStore notesStore;
    MusicPlayer music;
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Settings", &appSettings);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Monitor", &monitor);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Store", &store);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "SystemStatus", &status);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Users", &users);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Launcher", &launcher);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Files", &files);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Layer", &layer);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Sessions", &sessionList);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "WindowControl", &windowControl);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Batteries", &batteries);
    qmlRegisterType<FileBrowser>("BCShell", 1, 0, "FileModel");
    qmlRegisterType<GenieItem>("BCShell", 1, 0, "GenieItem");
    qmlRegisterType<GenieMesh>("BCShell", 1, 0, "GenieMesh");   // genio en la GPU
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Reminders", &reminders);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Sounds", &sounds);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Processes", &processes);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Notes", &notesStore);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Music", &music);
    Installer installer;
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Installer", &installer);

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
    WidgetHost widgetHost;
    QuickTools quickTools;
    if (!appMode) { swayPtr = std::make_unique<SwayControl>(); if (!(p.isSet(oShot) || p.isSet(oCheck))) updates = std::make_unique<UpdateChecker>(); }
    // Solo de las apps
    NotificationClient notifClient;
    AppActions actions(appName);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Quick", &quickTools);
    qmlRegisterSingletonInstance("BCShell", 1, 0, "Render", RenderEngine::instance());   // también en las apps (Archivos: búsqueda, abrir)
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
        qmlRegisterSingletonInstance("BCShell", 1, 0, "WidgetHost", &widgetHost);
        if (updates) QObject::connect(updates.get(), &UpdateChecker::updatesFound, &notifications, [&notifications](int n) {
            // Al pulsarla se abre la Terminal con la actualización completa; solo hay que escribir la contraseña
            notifications.push("BC OS", QObject::tr("Actualizaciones disponibles"),
                               QObject::tr("%n paquete(s) por actualizar. Pulsa para actualizar ahora.", "", n), "", 15000);
            notifications.setAction({"bc-terminal", "--actualizar"});
        });
        qmlRegisterSingletonInstance("BCShell", 1, 0, "AppActions", &actions);
        if (!(p.isSet(oShot) || p.isSet(oCheck))) { notifServer.start(); shell.start(); }
    } else {
        qmlRegisterSingletonInstance("BCShell", 1, 0, "Notifications", &notifClient);
        qmlRegisterSingletonInstance("BCShell", 1, 0, "AppActions", &actions);
        if (!actions.start()) qWarning() << "[app] no se pudo registrar el servicio D-Bus de la app";
    }

    g_prev = qInstallMessageHandler(countingHandler);
    QQuickWindow::setDefaultAlphaBuffer(true);   // superficies del panel transparentes (y capturas compuestas con alfa)
    QQmlApplicationEngine engine;
    engine.addImageProvider("glass", new GlassProvider);
    // Qt.quit() desde QML (cerrar la ventana de una app) debe terminar el proceso
    // (se usa exit(0): con QCoreApplication::quit() el bucle de eventos seguía vivo en Qt 6.4)
    QObject::connect(&engine, &QQmlEngine::quit, &app, [] { QCoreApplication::exit(0); });
    if (appMode) {
        const QString n = appName.left(1).toUpper() + appName.mid(1);
        engine.load(QUrl("qrc:/BCShell/" + n + "App.qml"));
    } else {
        engine.load(QUrl("qrc:/BCShell/Panel.qml"));
    }
    if (engine.rootObjects().isEmpty()) return 2;
    auto *win = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
    RenderEngine::instance()->watch(win);
    if (!win) return 2;

    if (p.isSet(oSize)) {
        const QStringList wh = p.value(oSize).split('x');
        if (wh.size() == 2 && wh[0].toInt() > 0 && wh[1].toInt() > 0) {
            win->resize(wh[0].toInt(), wh[1].toInt());
        } else { qCritical() << "--size inválido"; return 2; }
    }

    // Captura compuesta de todas las superficies (ver comentario dentro)
    auto grabComposite = [&]() -> QImage {
        QImage img = win->grabWindow();
        // Captura compuesta: sin layer-shell (pruebas) cada superficie del panel es una ventana aparte;
        // se pintan encima en orden de capa y en su posición en pantalla (originX/originY de LayerWindow).
        if (!img.isNull() && !LayerHelper().supported()) {
            QPainter pa(&img);
            const QStringList order{"background", "bottom", "top", "overlay"};
            for (const QString &layerName : order) {
                for (QWindow *w : QGuiApplication::topLevelWindows()) {
                    auto *qw = qobject_cast<QQuickWindow *>(w);
                    if (!qw || qw == win || !qw->isVisible() || qw->property("layer").toString() != layerName) continue;
                    // La plataforma de pruebas devuelve RGB sin alfa: se renderiza sobre negro y sobre blanco
                    // y se recupera el alfa de la diferencia (matting), para componer igual que el compositor.
                    const QColor old = qw->color();
                    qw->setColor(Qt::black);
                    const QImage onBlack = qw->grabWindow().convertToFormat(QImage::Format_RGB32);
                    qw->setColor(Qt::white);
                    const QImage onWhite = qw->grabWindow().convertToFormat(QImage::Format_RGB32);
                    qw->setColor(old);
                    QImage part(onBlack.size(), QImage::Format_ARGB32);
                    for (int y = 0; y < part.height(); ++y) {
                        const QRgb *b = reinterpret_cast<const QRgb *>(onBlack.constScanLine(y));
                        const QRgb *wl = reinterpret_cast<const QRgb *>(onWhite.constScanLine(y));
                        QRgb *o = reinterpret_cast<QRgb *>(part.scanLine(y));
                        for (int x = 0; x < part.width(); ++x) {
                            const int a = 255 - qBound(0, ((qRed(wl[x]) - qRed(b[x])) + (qGreen(wl[x]) - qGreen(b[x])) + (qBlue(wl[x]) - qBlue(b[x]))) / 3, 255);
                            o[x] = a == 0 ? 0 : qRgba(qMin(255, qRed(b[x]) * 255 / a), qMin(255, qGreen(b[x]) * 255 / a), qMin(255, qBlue(b[x]) * 255 / a), a);
                        }
                    }
                    pa.drawImage(QPointF(qw->property("originX").toReal(), qw->property("originY").toReal()), part);
                }
            }
        }
        return img;
    };

    // Ráfaga para revisar animaciones a ritmo real: BC_BURST=<propiedad de UiState>:<fotogramas>. Pone la propiedad
    // a true y guarda fotogramas compuestos seguidos con el tiempo transcurrido en el nombre (captura-<ms>.png).
    const QString burst = qEnvironmentVariable("BC_BURST");
    if (p.isSet(oShot) && !burst.isEmpty()) {
        QTimer::singleShot(qEnvironmentVariableIntValue("BC_SHOT_DELAY") > 0 ? qEnvironmentVariableIntValue("BC_SHOT_DELAY") : 1500, &app, [&, burst] {
            const QString prop = burst.section(':', 0, 0);
            static const QRegularExpression okProp("^[A-Za-z]+$");
            if (!okProp.match(prop).hasMatch()) { qCritical() << "BC_BURST inválido"; app.exit(7); return; }
            const int n = qBound(1, burst.section(':', 1, 1).toInt(), 240);
            // BC_FRAMES=1 (con BC_ANIM_SLOW=k, p. ej. 40): fotogramas exactos de 60 Hz. Las animaciones van k veces más
            // lentas y se captura cada 16,67·k ms reales = cada 1/60 s de animación (fotograma-NNN.png + fotogramas.csv)
            const bool fixed = qEnvironmentVariable("BC_FRAMES") == QLatin1String("1");
            const double slow = qMax(1.0, qEnvironmentVariable("BC_ANIM_SLOW").toDouble());
            auto *t = new QElapsedTimer; t->start();
            // Se evalúa en el contexto del panel (tiene importado BCShell y su UiState)
            // «aviso»: un aviso de prueba que entra, dura 500 ms y sale (para ver las dos animaciones)
            // «mover»: seguir la ventana como al arrastrarla (con un sway simulado que la desplaza)
            const QString js = prop == "aviso" ? QStringLiteral("Notifications.push(\"BC OS\", \"Aviso de prueba\", \"Entra, espera y sale\", \"\", 500)")
                             : prop == "mover" ? QStringLiteral("Quick.followWindowMove()")
                             // «genio»: minimizar una ventana de prueba (el fondo de pantalla) hacia el Dock
                             : prop == "genio" ? QStringLiteral("fxBox(Qt.rect(UiState.sw * 0.2, UiState.sh * 0.12, UiState.sw * 0.55, UiState.sh * 0.55), Qt.point(UiState.sw * 0.62, UiState.sh - 40), 48); genieWin.shown = true; genie.run(\"qrc:/BCShell/assets/wallpaper-default.png\", Qt.rect(UiState.sw * 0.2, UiState.sh * 0.12, UiState.sw * 0.55, UiState.sh * 0.55), Qt.point(UiState.sw * 0.62, UiState.sh - 40), 48, false)")
                                               : "UiState." + prop + " = true";
            QQmlExpression ex(QQmlEngine::contextForObject(win), win, js);
            ex.evaluate();
            if (ex.hasError()) { qCritical() << ex.error().toString(); app.exit(7); return; }
            // BC_BURST_CLOSE=1: se abre, se espera a que termine y se capturan los fotogramas del CIERRE
            const bool closing = qEnvironmentVariable("BC_BURST_CLOSE") == QLatin1String("1") && js.startsWith("UiState.");
            auto *count = new int(0);
            // BC_FRAMES=1: fotogramas exactos de 60 Hz (fotograma-NNN.png) y coste de dibujar cada uno (fotogramas.csv)
            auto *tick = new QTimer(&app); tick->setInterval(fixed ? int(16.667 * slow) : qMax(1, qEnvironmentVariableIntValue("BC_BURST_MS")));
            QObject::connect(tick, &QTimer::timeout, &app, [&, t, count, n, tick, fixed, slow] {
                QElapsedTimer cost; cost.start();
                const qint64 ms = fixed ? qint64(t->elapsed() / slow) : t->elapsed();   // tiempo de ANIMACIÓN
                // BC_BURST_SCOPE=<scope de LayerWindow> captura solo esa superficie (mucho más rápido que la compuesta)
                QImage img;
                const QString scope = qEnvironmentVariable("BC_BURST_SCOPE");
                if (!scope.isEmpty()) {
                    for (QWindow *w : QGuiApplication::topLevelWindows())
                        if (auto *qw = qobject_cast<QQuickWindow *>(w); qw && qw->isVisible() && qw->property("scope").toString() == scope) { img = qw->grabWindow(); break; }
                } else img = grabComposite();
                const qint64 drawMs = cost.elapsed();
                const QString base = p.value(oShot);
                const QString out = fixed ? base.left(base.lastIndexOf('/') + 1) + QString("fotograma-%1.png").arg(*count + 1, 3, 10, QChar('0'))
                                          : base.left(base.lastIndexOf('.')) + QString("-%1.png").arg(ms, 4, 10, QChar('0'));
                img.save(out);
                if (fixed) {
                    QFile csv(base.left(base.lastIndexOf('/') + 1) + "fotogramas.csv");
                    if (csv.open(QIODevice::Append)) csv.write(QString("%1,%2,%3\n").arg(*count + 1).arg(ms).arg(drawMs).toUtf8());
                }
                if (++*count >= n) { tick->stop(); app.exit(0); }
            });
            if (closing) {
                QTimer::singleShot(int(1200 * slow), &app, [&, t, tick, prop] {
                    QQmlExpression off(QQmlEngine::contextForObject(win), win, "UiState." + prop + " = false");
                    off.evaluate();
                    t->restart();
                    tick->start();
                });
            } else tick->start();
        });
        return app.exec();
    }
    if (p.isSet(oShot) || p.isSet(oCheck)) {
        QTimer::singleShot(qEnvironmentVariableIntValue("BC_SHOT_DELAY") > 0 ? qEnvironmentVariableIntValue("BC_SHOT_DELAY") : 1500, &app, [&] {
            int rc = 0;
            if (p.isSet(oShot)) {
                QImage img = grabComposite();
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
