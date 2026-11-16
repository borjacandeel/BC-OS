#include <QDir>
#include <QFile>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QtTest>
#include "../src/filebrowser.h"
#include "../src/appindex.h"
#include "../src/clipboardhistory.h"
#include "../src/updatechecker.h"
#include "../src/sessionlist.h"
#include "../src/sysmonitor.h"
#include "../src/greetd.h"
#include "../src/launcher.h"
#include "../src/packagestore.h"
#include "../src/powercontrol.h"
#include "../src/systemstatus.h"
#include "../src/userlist.h"
#include "../src/swaycontrol.h"
#include "../src/installer.h"

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
    void papeleraYOperaciones() {
        QTemporaryDir t;
        QVERIFY(t.isValid());
        qputenv("XDG_DATA_HOME", (t.path() + "/data").toUtf8());
        QDir d(t.path());
        QVERIFY(d.mkpath("trabajo"));
        QFile f(d.filePath("trabajo/nota.txt"));
        QVERIFY(f.open(QIODevice::WriteOnly));
        f.write("hola");
        f.close();
        FileBrowser b;
        b.open(d.filePath("trabajo"));
        QCOMPARE(b.rowCount(), 1);
        QVERIFY(b.newFolder("Nueva"));
        QVERIFY(b.newFolder("Nueva"));  // nombre repetido: "Nueva 2"
        QCOMPARE(b.rowCount(), 3);
        int row = -1;
        for (int i = 0; i < b.rowCount(); ++i) if (b.nameAt(i) == "nota.txt") row = i;
        QVERIFY(row >= 0);
        QVERIFY(b.renameAt(row, "apuntes.txt"));
        QVERIFY(QFile::exists(d.filePath("trabajo/apuntes.txt")));
        QVERIFY(!b.renameAt(0, "a/b"));
        for (int i = 0; i < b.rowCount(); ++i) if (b.nameAt(i) == "apuntes.txt") row = i;
        QVERIFY(b.trashAt(row));
        QVERIFY(!QFile::exists(d.filePath("trabajo/apuntes.txt")));
        QVERIFY(QFile::exists(t.path() + "/data/Trash/files/apuntes.txt"));
        QFile info(t.path() + "/data/Trash/info/apuntes.txt.trashinfo");
        QVERIFY(info.open(QIODevice::ReadOnly));
        QVERIFY(QString::fromUtf8(info.readAll()).contains("Path=" + d.filePath("trabajo/apuntes.txt")));
        b.openTrash();
        QVERIFY(b.inTrash());
        QCOMPARE(b.rowCount(), 1);
        QVERIFY(b.restoreAt(0));
        QVERIFY(QFile::exists(d.filePath("trabajo/apuntes.txt")));
        b.open(d.filePath("trabajo"));
        for (int i = 0; i < b.rowCount(); ++i) if (b.nameAt(i) == "apuntes.txt") row = i;
        QVERIFY(b.trashAt(row));
        b.openTrash();
        QVERIFY(b.deleteAt(0));
        QCOMPARE(b.rowCount(), 0);
        QVERIFY(b.emptyTrash());
        QVERIFY(!b.trashAt(0));  // no se puede enviar a la papelera desde la papelera
    }
    void carpetaInexistente() {
        FileBrowser b;
        b.open("/no/existe/bc");
        QVERIFY(!b.available());
        QCOMPARE(b.rowCount(), 0);
    }
    void lanzador() {
        Launcher l;
        QCOMPARE(Launcher::appIdFor("archivos"), QString("bc-files"));
        QCOMPARE(Launcher::appIdFor("terminal"), QString("Alacritty"));
        QVERIFY(AppIndex::isHiddenId("cmake-gui.desktop"));
        QVERIFY(!AppIndex::isHiddenId("firefox.desktop"));
        QCOMPARE(Launcher::appIdFor("navegador"), QString("firefox"));
        qputenv("BC_SHELL_BIN", "/bin/true");
        QCOMPARE(l.launch("tienda"), QString("started"));
        QCOMPARE(l.launch("musica"), QString("started"));          // Música ya es una app de BC
        QCOMPARE(l.launch("no-existe"), QString("unavailable"));
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
        const auto x = SystemStatus::parseNmcliDevices("enp0s5:ethernet:connected (externally):enp0s5\n");
        QVERIFY(x.online);
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
    void indiceDeAplicaciones() {
        AppIndex::Entry e;
        QVERIFY(AppIndex::parseDesktop("[Desktop Entry]\nType=Application\nName=Terminal\nName[es]=Terminal de BC\nExec=foot %U\nIcon=foot\n", "es_ES", e));
        QCOMPARE(e.name, QString("Terminal de BC"));
        QVERIFY(!AppIndex::parseDesktop("[Desktop Entry]\nType=Application\nName=X\nExec=x\nNoDisplay=true\n", "es_ES", e));
        QVERIFY(!AppIndex::parseDesktop("[Desktop Entry]\nType=Link\nName=X\nExec=x\n", "es_ES", e));
        QCOMPARE(AppIndex::commandFor("foot --title \"A B\" %U", false), QStringList({"foot", "--title", "A B"}));
        QCOMPARE(AppIndex::commandFor("htop", true), QStringList({"bc-terminal", "-e", "htop"}));
        QTemporaryDir t;
        QDir(t.path()).mkpath("apps");
        QFile f(t.filePath("apps/navegador.desktop"));
        QVERIFY(f.open(QIODevice::WriteOnly));
        f.write("[Desktop Entry]\nType=Application\nName=Navegador web\nExec=true\nComment=Internet\n");
        f.close();
        AppIndex idx({t.filePath("apps")}, "es_ES");
        QCOMPARE(idx.count(), 1);
        QCOMPARE(idx.search("nave").size(), 1);
        QCOMPARE(idx.search("inter").size(), 1);   // por comentario
        QCOMPARE(idx.search("zzz").size(), 0);
        QVERIFY(idx.launch("navegador.desktop"));
    }
    void tiendaPacman() {
        const auto r = PackageStore::parseSearch("extra/firefox 160.0-1 [installed]\n    Standalone web browser from mozilla.org\n"
                                                 "core/linux 6.8 (base) [installed: 6.7]\n    The Linux kernel\nextra/mpv 1:0.41-1\n    Video player\n");
        QCOMPARE(r.size(), 3);
        QCOMPARE(r[0].name, QString("firefox")); QCOMPARE(r[0].repo, QString("extra")); QVERIFY(r[0].installed);
        QCOMPARE(r[0].desc, QString("Standalone web browser from mozilla.org"));
        QVERIFY(r[1].installed); QVERIFY(!r[2].installed);
        QCOMPARE(PackageStore::parseInstalled("bash 5.3\nnano 8.0\n").size(), 2);
        const QVariantMap m = PackageStore::parseInfo("Repository      : extra\nName            : mpv\nVersion         : 1:0.41-1\nDescription     : Video player\nInstalled Size  : 5.00 MiB\n");
        QCOMPARE(m.value("name").toString(), QString("mpv"));
        QCOMPARE(m.value("size").toString(), QString("5.00 MiB"));
        QCOMPARE(PackageStore::sudoArgs({"-S", "x"}), QStringList({"-S", "-p", "", "--", "pacman", "-S", "x"}));
    }
    void installer() {
        // lsblk: solo discos de escritura; marca el disco montado (arranque) y los pequeños
        const QByteArray js = R"({"blockdevices":[
          {"name":"sda","path":"/dev/sda","size":64424509440,"model":"VBOX HARDDISK","type":"disk","rm":false,"ro":false,"tran":"sata","mountpoints":[null]},
          {"name":"sdb","path":"/dev/sdb","size":8000000000,"model":"USB","type":"disk","rm":true,"ro":false,"tran":"usb","mountpoints":[null],
           "children":[{"name":"sdb1","path":"/dev/sdb1","type":"part","mountpoints":["/run/archiso/bootmnt"]}]},
          {"name":"sr0","path":"/dev/sr0","size":1000,"model":"CD","type":"rom","rm":true,"ro":true,"mountpoints":[null]},
          {"name":"loop0","path":"/dev/loop0","size":1000,"type":"loop","rm":false,"ro":false,"mountpoints":["/x"]}]})";
        const QVariantList d = Installer::parseLsblk(js);
        QCOMPARE(d.size(), 2);
        QCOMPARE(d[0].toMap().value("path").toString(), QString("/dev/sda"));
        QVERIFY(!d[0].toMap().value("inUse").toBool());
        QVERIFY(!d[0].toMap().value("tooSmall").toBool());
        QVERIFY(d[1].toMap().value("inUse").toBool());
        QVERIFY(d[1].toMap().value("tooSmall").toBool());
        // Validación: nada que pueda colarse como opción o ruta
        QVariantMap ok{{"disk", "/dev/sda"}, {"user", "ana"}, {"password", "secreto"}, {"hostname", "bcos"}, {"keymap", "es"}, {"timezone", "Europe/Madrid"}};
        QVERIFY(Installer::validate(ok).isEmpty());
        auto bad = [&](const char *k, const QVariant &v) { QVariantMap m = ok; m[k] = v; return !Installer::validate(m).isEmpty(); };
        QVERIFY(bad("disk", "/dev/sda; rm -rf /"));
        QVERIFY(bad("disk", "--auto"));
        QVERIFY(bad("user", "root"));
        QVERIFY(bad("user", "-x"));
        QVERIFY(bad("password", "abc"));
        QVERIFY(bad("password", "a\nb\nc\nd"));
        QVERIFY(bad("hostname", "-bc"));
        QVERIFY(bad("timezone", "../../etc/passwd"));
        { QVariantMap m = ok; m["timezone"] = "America/Argentina/Buenos_Aires"; QVERIFY(Installer::validate(m).isEmpty()); }
        // Progreso: pasos «[NN%]» y copia «@copia NN» dentro de su 30 %
        Installer in(nullptr, "/bin/true");
        in.feedLine("[8%] Particionando el disco (GPT)...");
        QCOMPARE(in.progress(), 8);
        in.feedLine("[50%] Copiando el sistema (puede tardar unos minutos)...");
        QCOMPARE(in.progress(), 20);
        in.feedLine("@copia 50");
        QCOMPARE(in.progress(), 35);
        in.feedLine("ERROR: disco ocupado");
        QCOMPARE(in.error(), QString("disco ocupado"));
        // De extremo a extremo con un bc-install simulado: progreso leído y fichero de contraseña borrado al acabar
        QTemporaryDir tmp; QVERIFY(tmp.isValid());
        const QString fake = tmp.filePath("fake-install");
        { QFile f(fake); QVERIFY(f.open(QIODevice::WriteOnly));
          f.write("#!/bin/sh\nwhile [ $# -gt 0 ]; do [ \"$1\" = --password-file ] && pw=\"$2\"; shift; done\ntest -f \"$pw\" || exit 9\n"
                  "echo '[8%] Particionando' >&2; echo '[50%] Copiando el sistema' >&2; echo '@copia 100' >&2; echo '[100%] Fin' >&2; exit 0\n"); }
        QFile::setPermissions(fake, QFile::ReadOwner | QFile::WriteOwner | QFile::ExeOwner);
        qputenv("BC_INSTALL_TEST", "1"); qputenv("BC_INSTALL_RUNNER", "-"); qputenv("XDG_RUNTIME_DIR", tmp.path().toUtf8());
        Installer e2e(nullptr, fake);
        QSignalSpy spy(&e2e, &Installer::stateChanged);
        QCOMPARE(e2e.start(ok), QString());
        QTRY_VERIFY_WITH_TIMEOUT(e2e.finished() || !e2e.error().isEmpty(), 5000);
        QVERIFY2(e2e.finished(), qPrintable(e2e.error()));
        QCOMPARE(e2e.progress(), 100);
        QCOMPARE(QDir(tmp.path()).entryList({"bc-install-*"}, QDir::Files).size(), 0);
        qunsetenv("BC_INSTALL_TEST"); qunsetenv("BC_INSTALL_RUNNER");
    }
    void hyprland() {
        const QByteArray j = R"([{"address":"0x5a1b2c3d","mapped":true,"at":[100,80],"size":[800,600],"workspace":{"id":1,"name":"1"},
          "floating":true,"fullscreen":0,"class":"Alacritty","title":"bc@bcos","pid":42,"focusHistoryID":0,"monitor":0},
          {"address":"0x5a1b2c4e","mapped":true,"at":[0,0],"size":[10,10],"workspace":{"id":-99,"name":"special:minimized"},
          "floating":true,"fullscreen":false,"class":"firefox","title":"Web","pid":43,"focusHistoryID":1,"monitor":0}])";
        QHash<int, QString> addr;
        const QVariantList w = SwayControl::parseHyprClients(j, &addr);
        QCOMPARE(w.size(), 2);
        const int id = w[0].toMap().value("id").toInt();
        QCOMPARE(addr.value(id), QString("0x5a1b2c3d"));
        QVERIFY(w[0].toMap().value("focused").toBool());
        QVERIFY(w[1].toMap().value("minimized").toBool());
        const QString t = QString::number(id);
        QCOMPARE(SwayControl::translateToHyprland("[con_id=" + t + "] focus", addr, "1"),
                 QStringList{"hl.dispatch(hl.dsp.focus({ window = [==[address:0x5a1b2c3d]==] }))"});
        QCOMPARE(SwayControl::translateToHyprland("[con_id=" + t + "] move scratchpad", addr, "1"),
                 QStringList{"hl.dispatch(hl.dsp.window.move({ workspace = \"special:minimized\", window = [==[address:0x5a1b2c3d]==] }))"});
        QCOMPARE(SwayControl::translateToHyprland("[con_id=" + t + "] floating enable, resize set 400 300, move absolute position 8 40", addr, "1").size(), 3);
        QCOMPARE(SwayControl::translateToHyprland("workspace \"3\"", addr, "1"), QStringList{"hl.dispatch(hl.dsp.focus({ workspace = 3 }))"});
        QCOMPARE(SwayControl::translateToHyprland("exec bc-shell --app files", addr, "1"),
                 QStringList{"hl.dispatch(hl.dsp.exec_cmd([==[bc-shell --app files]==]))"});
        QCOMPARE(SwayControl::translateToHyprland("kill", addr, "1"), QStringList{"hl.dispatch(hl.dsp.window.close())"});
    }
    void arbolDeSway() {
        const QByteArray j = R"({"type":"root","nodes":[{"type":"output","nodes":[
          {"type":"workspace","name":"1","nodes":[
            {"type":"con","id":10,"pid":100,"app_id":"foot","name":"bc@bcos: ~","focused":true,"deco_rect":{"x":4,"y":8,"width":300,"height":24},"rect":{"x":10,"y":64,"width":300,"height":200},"nodes":[],"floating_nodes":[]},
            {"type":"con","id":11,"pid":101,"app_id":null,"window_properties":{"class":"Firefox"},"name":"Web","nodes":[],"floating_nodes":[]}],
           "floating_nodes":[{"type":"floating_con","id":12,"pid":102,"app_id":"bc-files","name":"Archivos","nodes":[],"floating_nodes":[]}]},
          {"type":"workspace","name":"__i3_scratch","nodes":[],"floating_nodes":[
            {"type":"floating_con","id":13,"pid":103,"app_id":"bc-store","name":"Tienda","nodes":[],"floating_nodes":[]}]}]}]})";
        const QVariantList w = SwayControl::parseTree(j);
        QCOMPARE(w.size(), 4);
        QCOMPARE(w[0].toMap().value("appId").toString(), QString("foot"));
        QVERIFY(w[0].toMap().value("focused").toBool());
        QCOMPARE(w[0].toMap().value("decoH").toInt(), 24);
        QCOMPARE(w[0].toMap().value("decoX").toInt(), 10);
        QCOMPARE(w[0].toMap().value("decoY").toInt(), 40);   // rect empieza bajo la barra de título
        QCOMPARE(w[0].toMap().value("rectH").toInt(), 224);
        QCOMPARE(w[1].toMap().value("appId").toString(), QString("Firefox"));
        QVERIFY(w[2].toMap().value("floating").toBool());
        QVERIFY(w[3].toMap().value("minimized").toBool());
    }
    void flatpakAnalizador() {
        const auto l = PackageStore::parseFlatpak("org.mozilla.firefox\tFirefox\t128.0\tWeb browser\nSin coincidencias\norg.gimp.GIMP\tGIMP\t3.0\tImage editor\n", false);
        QCOMPARE(l.size(), 2);
        QCOMPARE(l[0].id, QString("org.mozilla.firefox"));
        QCOMPARE(l[1].name, QString("GIMP"));
        QCOMPARE(l[0].repo, QString("flathub"));
    }
    void datosDelSistema() {
        QCOMPARE(SysMonitor::cpuNameFromInfo("processor\t: 0\nCPU implementer\t: 0x61\nCPU part\t: 0x022\n"), QString("Apple Silicon (ARM64)"));
        QCOMPARE(SysMonitor::cpuNameFromInfo("model name\t: Cortex-A72\n"), QString("Cortex-A72"));
        QCOMPARE(SysMonitor::cpuNameFromInfo(""), QString("ARM64"));
        QCOMPARE(SysMonitor::osNameFromRelease("NAME=\"BC OS\"\nPRETTY_NAME=\"BC OS 0.4.1-beta\"\n"), QString("BC OS 0.4.1-beta"));
        QCOMPARE(SysMonitor::osNameFromRelease(""), QString("BC OS"));
    }
    void sesiones() {
        QTemporaryDir d, st;
        QVERIFY(d.isValid() && st.isValid());
        auto w = [&](const char *n, const char *body) { QFile f(d.filePath(n)); QVERIFY(f.open(QIODevice::WriteOnly)); f.write(body); };
        w("bc.desktop", "[Desktop Entry]\nName=BC OS\nExec=bc-session --greetd\nX-BC-Order=1\n");
        w("dotfiles.desktop", "[Desktop Entry]\nName=Dotfiles (bspwm)\nExec=bc-session-bspwm --greetd\nX-BC-Type=x11\nX-BC-Order=2\n");
        w("mal id.desktop", "[Desktop Entry]\nName=Mal\nExec=x\n");
        SessionList s(d.path(), st.path());
        QCOMPARE(s.sessions().size(), 2);
        QCOMPARE(s.currentId(), QString("bc"));
        QCOMPARE(s.currentCommand(), QStringList({"bc-session", "--greetd"}));
        s.setCurrent(1);
        QCOMPARE(s.currentId(), QString("dotfiles"));
        QVERIFY(s.currentEnv().contains("XDG_SESSION_TYPE=x11"));
        QVERIFY(s.remember("borja", "dotfiles"));
        QVERIFY(!s.remember("../x", "dotfiles"));
        QVERIFY(!s.remember("borja", "inexistente"));
        s.setCurrent(0);
        s.selectFor("borja");
        QCOMPARE(s.currentId(), QString("dotfiles"));
        s.rememberLast("bc");
        SessionList s2(d.path(), st.path());
        QCOMPARE(s2.currentId(), QString("bc"));
    }
    void historialPortapapeles() {
        const auto l = ClipboardHistory::parseList("12\thola mundo\n11\t[[ binary data 12 KiB png 10x10 ]]\nabc\tno numerico\n10\t   \n9\tadiós\n");
        QCOMPARE(l.size(), 2);
        QCOMPARE(l[0].toMap().value("id").toString(), QString("12"));
        QCOMPARE(l[1].toMap().value("text").toString(), QString("adiós"));
    }
    void avisoDeActualizaciones() {
        QCOMPARE(UpdateChecker::parseCount("linux 6.1-1 -> 6.2-1\nfoo 1-1 -> 1-2\n"), 2);
        QCOMPARE(UpdateChecker::parseCount(""), 0);
    }
    void iconosDeApps() {
        QTemporaryDir d;
        QVERIFY(d.isValid());
        QFile f(d.filePath("miapp.svg")); QVERIFY(f.open(QIODevice::WriteOnly)); f.write("<svg/>"); f.close();
        QCOMPARE(AppIndex::resolveIcon("miapp", {d.path()}), d.filePath("miapp.svg"));
        QCOMPARE(AppIndex::resolveIcon("../miapp", {d.path()}), QString());
        QCOMPARE(AppIndex::resolveIcon("noexiste", {d.path()}), QString());
        QCOMPARE(AppIndex::resolveIcon(d.filePath("miapp.svg")), d.filePath("miapp.svg"));
        QCOMPARE(AppIndex::resolveIcon(""), QString());
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
