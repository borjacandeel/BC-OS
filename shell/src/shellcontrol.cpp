#include "shellcontrol.h"
#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCall>
#include <QDebug>
#include <QProcess>
#include <QStandardPaths>

bool ShellControl::start() {
    QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.isConnected() || !bus.registerService("org.bcos.Shell")) { qWarning() << "[shell] no se pudo registrar org.bcos.Shell"; return false; }
    return bus.registerObject("/org/bcos/Shell", this, QDBusConnection::ExportAllSlots);
}

void ShellControl::invokeApp(const QString &app, const QString &action) {
    QDBusMessage m = QDBusMessage::createMethodCall("org.bcos.App." + app, "/org/bcos/App", "org.bcos.App", "Invoke");
    m << action;
    QDBusConnection::sessionBus().asyncCall(m);
}

AppActions::AppActions(const QString &name, QObject *parent) : QObject(parent), m_name(name) {}

bool AppActions::start() {
    QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.isConnected() || !bus.registerService("org.bcos.App." + m_name)) return false;
    return bus.registerObject("/org/bcos/App", this, QDBusConnection::ExportAllSlots);
}

void NotificationClient::push(const QString &app, const QString &title, const QString &body, const QString &icon, int timeoutMs) {
    QDBusMessage m = QDBusMessage::createMethodCall("org.freedesktop.Notifications", "/org/freedesktop/Notifications",
                                                    "org.freedesktop.Notifications", "Notify");
    m << app << uint(0) << icon << title << body << QStringList() << QVariantMap() << timeoutMs;
    QDBusConnection::sessionBus().asyncCall(m);
}

static void swayForSelf(const QString &verb) {
    const QString exe = QStandardPaths::findExecutable("swaymsg");
    if (exe.isEmpty()) return;
    QProcess::startDetached(exe, {QString("[pid=%1] %2").arg(QCoreApplication::applicationPid()).arg(verb)});
}
void WindowControl::minimize() { swayForSelf("move scratchpad"); }
void WindowControl::toggleFullscreen() { swayForSelf("fullscreen toggle"); }
