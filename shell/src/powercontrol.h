#pragma once
#include <QObject>
#include <QString>

// Apagar, reiniciar, suspender y cerrar sesión. BC_POWER_DRYRUN=1 solo registra la acción (pruebas).
class PowerControl : public QObject {
    Q_OBJECT
public:
    explicit PowerControl(QObject *parent = nullptr) : QObject(parent) {}
    Q_INVOKABLE void poweroff() { run("poweroff"); }
    Q_INVOKABLE void reboot() { run("reboot"); }
    Q_INVOKABLE void suspend() { run("suspend"); }
    Q_INVOKABLE void logout() { run("logout"); }
    // Programa y argumentos de cada acción (vacío si la acción no existe).
    static QStringList commandFor(const QString &action);
signals:
    void executed(const QString &action);

private:
    void run(const QString &action);
};
