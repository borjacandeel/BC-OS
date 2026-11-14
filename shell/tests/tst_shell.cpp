#include <QDir>
#include <QFile>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QtTest>
#include "../src/filebrowser.h"
#include "../src/greetd.h"
#include "../src/launcher.h"
#include "../src/powercontrol.h"
#include "../src/systemstatus.h"
#include "../src/userlist.h"

class TstShell : public QObject {
    Q_OBJECT
private slots:
    void navegacionYFiltro() {
        QTemporaryDir t;
        QVERIFY(t.isValid());
        QDir d(t.path());
        QVERIFY(d.mkpath("Carpeta/Sub"));
        for (const char *n : {"nota.txt", "foto.png", "Carpeta/dentro.md"}) {
            QFile f(d.filePath(n));
            QVERIFY(f.open(QIODevice::WriteOnly));
        }
        FileBrowser b;
        b.open(t.path());
        QCOMPARE(b.path(), QDir::cleanPath(t.path()));
        QCOMPARE(b.rowCount(), 3);
        QCOMPARE(b.data(b.index(0), FileBrowser::NameRole).toString(), QString("Carpeta"));  // carpetas primero
        QCOMPARE(b.data(b.index(0), FileBrowser::KindRole).toString(), QString("carpeta"));
        QCOMPARE(b.data(b.index(1), FileBrowser::KindRole).toString(), QString("imagen"));
        b.setFilter("NOTA");
        QCOMPARE(b.rowCount(), 1);
        b.setFilter("zzz");
        QCOMPARE(b.rowCount(), 0);
        b.setFilter("");
        b.activate(0);  // entra en Carpeta
        QVERIFY(b.path().endsWith("/Carpeta"));
        QCOMPARE(b.rowCount(), 2);
        QVERIFY(b.canBack());
        QVERIFY(!b.canForward());
        b.back();
        QCOMPARE(b.rowCount(), 3);
        QVERIFY(b.canForward());
        b.forward();
        QVERIFY(b.path().endsWith("/Carpeta"));
        b.up();
        QCOMPARE(b.path(), QDir::cleanPath(t.path()));
        b.open(d.filePath("Carpeta/Sub"));
        const QVariantList c = b.crumbs();
        QCOMPARE(c.last().toMap().value("name").toString(), QString("Sub"));
        QCOMPARE(c.first().toMap().value("path").toString(), QString("/"));
    }
    void carpetaInexistente() {
        FileBrowser b;
        b.open("/no/existe/bc");
        QVERIFY(!b.available());
        QCOMPARE(b.rowCount(), 0);
    }
    void lanzador() {
        Launcher l;
        QCOMPARE(l.launch("archivos"), QString("internal"));
        QCOMPARE(l.launch("monitor"), QString("internal"));
        QCOMPARE(l.launch("ajustes"), QString("internal"));
        QCOMPARE(l.launch("tienda"), QString("unavailable"));
        qputenv("BC_TERMINAL", "bc-no-existe-xyz");
        QCOMPARE(l.launch("terminal"), QString("failed"));
        qputenv("BC_TERMINAL", "sleep");  // sin argumentos termina con error; basta para ver el ciclo de vida
        QCOMPARE(l.launch("terminal"), QString("started"));
        QVERIFY(l.isRunning("terminal"));
        QTRY_VERIFY_WITH_TIMEOUT(!l.isRunning("terminal"), 6000);
    }
    void analizadoresDeEstado() {
        auto v = SystemStatus::parseWpctl("Volume: 0.45\n");
        QVERIFY(v.ok); QCOMPARE(v.value, 0.45); QVERIFY(!v.muted);
        v = SystemStatus::parseWpctl("Volume: 0.80 [MUTED]\n");
        QVERIFY(v.ok); QVERIFY(v.muted);
        QVERIFY(!SystemStatus::parseWpctl("Could not connect").ok);
        const auto n = SystemStatus::parseNmcliDevices("lo:loopback:unmanaged:\nwlan0:wifi:connected:Casa\\:5G\neth0:ethernet:unavailable:\n");
        QVERIFY(n.hasWifi); QVERIFY(n.online); QVERIFY(!n.wired); QCOMPARE(n.connection, QString("Casa:5G"));
        const auto e = SystemStatus::parseNmcliDevices("eth0:ethernet:connected:Wired connection 1\n");
        QVERIFY(!e.hasWifi); QVERIFY(e.online); QVERIFY(e.wired);
        QCOMPARE(SystemStatus::parseNmcliSignal("no:40:Otra\nyes:78:Casa\n"), 78);
        QCOMPARE(SystemStatus::parseNmcliSignal("no:40:Otra\n"), -1);
        QCOMPARE(SystemStatus::signalBars(10), 0);
        QCOMPARE(SystemStatus::signalBars(30), 1);
        QCOMPARE(SystemStatus::signalBars(60), 2);
        QCOMPARE(SystemStatus::signalBars(90), 3);
        QVERIFY(SystemStatus::parseBluetoothPowered("Controller AA\n\tPowered: yes\n"));
        QVERIFY(!SystemStatus::parseBluetoothPowered("Controller AA\n\tPowered: no\n"));
        bool ok = false; double f = 0;
        SystemStatus::parseBrightnessctl("intel_backlight,backlight,500,50%,1000\n", ok, f);
        QVERIFY(ok); QCOMPARE(f, 0.5);
    }
    void listaDeUsuarios() {
        QTemporaryDir t;
        QFile f(t.filePath("passwd"));
        QVERIFY(f.open(QIODevice::WriteOnly));
        f.write("root:x:0:0:root:/root:/bin/bash\nbc:x:1000:1000:Borja Candel,,,:/home/bc:/bin/bash\n"
                "nadie:x:65534:65534:Nobody:/:/usr/bin/nologin\nsvc:x:1001:1001::/var/svc:/usr/bin/nologin\n");
        f.close();
        const QVariantList u = UserList::parse(t.filePath("passwd"));
        QCOMPARE(u.size(), 1);
        QCOMPARE(u[0].toMap().value("name").toString(), QString("bc"));
        QCOMPARE(u[0].toMap().value("display").toString(), QString("Borja Candel"));
    }
    void protocoloGreetd() {
        const QByteArray fr = GreetdClient::frame({{"type", "cancel_session"}});
        quint32 n; memcpy(&n, fr.constData(), 4);
        QCOMPARE(int(n), fr.size() - 4);
        GreetdClient g;
        // sin GREETD_SOCK no hay conexión: error claro, no cuelgue
        qunsetenv("GREETD_SOCK");
        QSignalSpy err(&g, &GreetdClient::errorOccurred);
        g.login("bc", "x");
        QCOMPARE(err.count(), 1);
        // máquina de estados: auth_message secreto -> respuesta con la contraseña
        qputenv("GREETD_SOCK", "/tmp/no-existe-greetd.sock");
    }
    void energia() {
        qputenv("BC_POWER_DRYRUN", "1");
        PowerControl p;
        QSignalSpy sp(&p, &PowerControl::executed);
        p.poweroff();
        QCOMPARE(sp.count(), 1);
        QCOMPARE(sp.at(0).at(0).toString(), QString("poweroff"));
        QCOMPARE(PowerControl::commandFor("reboot"), QStringList({"systemctl", "reboot"}));
        QVERIFY(PowerControl::commandFor("nada").isEmpty());
    }
};

QTEST_GUILESS_MAIN(TstShell)
#include "tst_shell.moc"
