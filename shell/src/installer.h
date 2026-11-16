#pragma once
#include <QObject>
#include <QProcess>
#include <QVariantList>

// Instalador gráfico (app «Instalar BC OS», estilo macOS): lista los discos y ejecuta bc-install --auto con pkexec,
// leyendo su progreso («[NN%] paso» y «@copia NN» durante la copia). Las contraseñas van en ficheros 0600 de
// $XDG_RUNTIME_DIR que se borran al terminar; nunca en argumentos ni en el registro.
class Installer : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool live READ live CONSTANT)
    Q_PROPERTY(QVariantList disks READ disks NOTIFY disksChanged)
    Q_PROPERTY(int progress READ progress NOTIFY stateChanged)
    Q_PROPERTY(QString step READ step NOTIFY stateChanged)
    Q_PROPERTY(bool running READ running NOTIFY stateChanged)
    Q_PROPERTY(bool finished READ finished NOTIFY stateChanged)
    Q_PROPERTY(QString error READ error NOTIFY stateChanged)
public:
    explicit Installer(QObject *parent = nullptr, const QString &program = {});
    bool live() const;
    QVariantList disks() const { return m_disks; }
    int progress() const { return m_progress; }
    QString step() const { return m_step; }
    bool running() const { return m_proc.state() != QProcess::NotRunning; }
    bool finished() const { return m_finished; }
    QString error() const { return m_error; }

    Q_INVOKABLE void refreshDisks();
    // opts: disk, user, fullName, password, hostname, keymap, timezone, encrypt (bool). Devuelve "" o el motivo del rechazo.
    Q_INVOKABLE QString start(const QVariantMap &opts);
    Q_INVOKABLE void reboot();
    // Analizadores (públicos para las pruebas)
    static QVariantList parseLsblk(const QByteArray &json);
    static QString validate(const QVariantMap &opts);
    void feedLine(const QString &line);

signals:
    void disksChanged();
    void stateChanged();

private:
    void cleanupSecrets();
    QString m_program;
    QVariantList m_disks;
    QProcess m_proc;
    QByteArray m_buf;
    int m_progress = 0, m_copyBase = -1;
    QString m_step, m_error;
    bool m_finished = false;
    QStringList m_secretFiles;
};
