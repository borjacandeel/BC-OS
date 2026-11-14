#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QSignalSpy>
#include <QtTest>
#include "../src/notifications.h"

class TstNotif : public QObject {
    Q_OBJECT
private slots:
    void colaYNoMolestar() {
        NotificationQueue q;
        QVERIFY(!q.visible());
        q.push("app", "Hola", "cuerpo", "", 5000);
        QVERIFY(q.visible());
        QCOMPARE(q.title(), QString("Hola"));
        q.dismiss();
        QVERIFY(!q.visible());
        q.setDnd(true);
        q.push("app", "Silencio", "x", "", 5000);
        QVERIFY(!q.visible());
        QCOMPARE(q.history().size(), 2);
    }
    void servicioDbus() {
        if (!QDBusConnection::sessionBus().isConnected()) QSKIP("sin bus de sesión");
        NotificationQueue q;
        NotificationServer s(&q);
        QVERIFY(s.start());
        QDBusInterface i("org.freedesktop.Notifications", "/org/freedesktop/Notifications", "org.freedesktop.Notifications");
        QVERIFY(i.isValid());
        QDBusReply<uint> r = i.call("Notify", "prueba", 0u, "", "Título", "Texto", QStringList(), QVariantMap(), 3000);
        QVERIFY(r.isValid());
        QCOMPARE(r.value(), 1u);
        QVERIFY(q.visible());
        QCOMPARE(q.body(), QString("Texto"));
        QDBusReply<QStringList> caps = i.call("GetCapabilities");
        QVERIFY(caps.value().contains("body"));
    }
};
QTEST_MAIN(TstNotif)
#include "tst_notif.moc"
