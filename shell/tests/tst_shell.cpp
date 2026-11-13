#include <QDir>
#include <QFile>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QtTest>
#include "../src/filebrowser.h"
#include "../src/launcher.h"

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
        QCOMPARE(l.launch("tienda"), QString("unavailable"));
        qputenv("BC_TERMINAL", "bc-no-existe-xyz");
        QCOMPARE(l.launch("terminal"), QString("failed"));
        qputenv("BC_TERMINAL", "sleep");  // sin argumentos termina con error; basta para ver el ciclo de vida
        QCOMPARE(l.launch("terminal"), QString("started"));
        QVERIFY(l.isRunning("terminal"));
        QTRY_VERIFY_WITH_TIMEOUT(!l.isRunning("terminal"), 6000);
    }
};

QTEST_GUILESS_MAIN(TstShell)
#include "tst_shell.moc"
