#include "powercontrol.h"
#include <QDebug>
#include <QProcess>
#include <QProcessEnvironment>

QStringList PowerControl::commandFor(const QString &action) {
    if (action == "poweroff") return {"systemctl", "poweroff"};
    if (action == "reboot") return {"systemctl", "reboot"};
    if (action == "suspend") return {"systemctl", "suspend"};
    if (action == "logout") return {"labwc", "--exit"};
    return {};
}

void PowerControl::run(const QString &action) {
    const QStringList c = commandFor(action);
    if (c.isEmpty()) return;
    if (qEnvironmentVariable("BC_POWER_DRYRUN") == "1") {
        qInfo() << "[power] simulado:" << c.join(' ');
    } else {
        QProcess::startDetached(c.first(), c.mid(1));
    }
    emit executed(action);
}
