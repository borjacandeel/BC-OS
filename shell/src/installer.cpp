#include "installer.h"
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QSaveFile>
#include <QUuid>
#include <functional>

Installer::Installer(QObject *parent, const QString &program)
    : QObject(parent), m_program(program.isEmpty() ? QStringLiteral("/usr/lib/bc-install/bc-install") : program) {
    // Pruebas: BC_INSTALL_TEST=1 permite usar otro programa (BC_INSTALL_PROGRAM) y otro lanzador (BC_INSTALL_RUNNER)
    if (program.isEmpty() && qEnvironmentVariableIsSet("BC_INSTALL_TEST") && qEnvironmentVariableIsSet("BC_INSTALL_PROGRAM"))
        m_program = qEnvironmentVariable("BC_INSTALL_PROGRAM");
    m_proc.setProcessChannelMode(QProcess::MergedChannels);
    connect(&m_proc, &QProcess::readyRead, this, [this] {
        m_buf += m_proc.readAll();
        // rsync usa «\r» para refrescar la línea: se trata igual que un salto de línea
        for (;;) {
            const int a = m_buf.indexOf('\n'), b = m_buf.indexOf('\r');
            const int cut = a < 0 ? b : (b < 0 ? a : qMin(a, b));
            if (cut < 0) break;
            feedLine(QString::fromUtf8(m_buf.left(cut)).trimmed());
            m_buf.remove(0, cut + 1);
        }
    });
    connect(&m_proc, &QProcess::finished, this, [this](int code, QProcess::ExitStatus st) {
        cleanupSecrets();
        if (st == QProcess::NormalExit && code == 0) { m_finished = true; m_progress = 100; m_step = tr("Instalación completada"); }
        else if (m_error.isEmpty()) m_error = code == 126 || code == 127 ? tr("No se concedió el permiso de administrador.")
                                                                         : tr("La instalación no se pudo completar (código %1). Revisa /var/log/bc-install.log.").arg(code);
        emit stateChanged();
    });
}

bool Installer::live() const {
    if (QFileInfo::exists("/run/archiso") || qEnvironmentVariableIsSet("BC_INSTALL_TEST")) return true;
    QFile f("/proc/cmdline");   // la ISO live arranca con archisolabel=…
    return f.open(QIODevice::ReadOnly) && f.readAll().contains("archisolabel=");
}

QVariantList Installer::parseLsblk(const QByteArray &json) {
    QVariantList out;
    const QJsonArray devs = QJsonDocument::fromJson(json).object().value("blockdevices").toArray();
    for (const QJsonValue &v : devs) {
        const QJsonObject d = v.toObject();
        if (d.value("type").toString() != "disk" || d.value("ro").toBool()) continue;
        const QString path = d.value("path").toString();
        static const QRegularExpression okPath("^/dev/(sd[a-z]+|vd[a-z]+|nvme\\d+n\\d+|mmcblk\\d+|xvd[a-z]+)$");
        if (!okPath.match(path).hasMatch()) continue;
        // En uso si él o alguna partición está montada (p. ej. el USB/ISO desde el que arranca el sistema live)
        bool inUse = false;
        std::function<void(const QJsonObject &)> scan = [&](const QJsonObject &o) {
            for (const QJsonValue &m : o.value("mountpoints").toArray()) if (!m.toString().isEmpty()) inUse = true;
            for (const QJsonValue &c : o.value("children").toArray()) scan(c.toObject());
        };
        scan(d);
        const qint64 size = d.value("size").toVariant().toLongLong();
        QString model = d.value("model").toString().trimmed();
        if (model.isEmpty()) model = d.value("tran").toString() == "usb" ? tr("Disco USB") : tr("Disco");
        out.append(QVariantMap{{"path", path}, {"name", d.value("name").toString()}, {"model", model}, {"size", size},
                               {"sizeText", QString::number(size / 1e9, 'f', size >= 1e11 ? 0 : 1) + " GB"},
                               {"removable", d.value("rm").toBool()}, {"inUse", inUse}, {"tooSmall", size < 12LL * 1024 * 1024 * 1024}});
    }
    return out;
}

void Installer::refreshDisks() {
    QProcess p;
    p.start("lsblk", {"-J", "-b", "-o", "NAME,PATH,SIZE,MODEL,TYPE,RM,RO,TRAN,MOUNTPOINTS"});
    if (!p.waitForFinished(5000)) return;
    m_disks = parseLsblk(p.readAllStandardOutput());
    emit disksChanged();
}

QString Installer::validate(const QVariantMap &o) {
    static const QRegularExpression disk("^/dev/(sd[a-z]+|vd[a-z]+|nvme\\d+n\\d+|mmcblk\\d+|xvd[a-z]+)$"),
        user("^[a-z_][a-z0-9_-]{0,31}$"), host("^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$"),
        keymap("^[a-z]{2}(-[a-z0-9]+)?$"), tz("^([A-Z][A-Za-z_]+(/[A-Za-z_+-]+){1,2}|UTC)$");
    if (!disk.match(o.value("disk").toString()).hasMatch()) return tr("Elige un disco.");
    const QString u = o.value("user").toString();
    if (!user.match(u).hasMatch() || u == "root") return tr("El nombre de cuenta solo admite minúsculas, números, «-» y «_».");
    if (o.value("password").toString().size() < 4) return tr("La contraseña debe tener al menos 4 caracteres.");
    if (o.value("password").toString().contains('\n')) return tr("La contraseña no puede tener saltos de línea.");
    if (!host.match(o.value("hostname").toString()).hasMatch()) return tr("El nombre del equipo solo admite letras, números y «-».");
    if (!keymap.match(o.value("keymap").toString()).hasMatch()) return tr("Distribución de teclado no válida.");
    if (!tz.match(o.value("timezone").toString()).hasMatch()) return tr("Zona horaria no válida.");
    return {};
}

QString Installer::start(const QVariantMap &opts) {
    if (running()) return tr("Ya hay una instalación en curso.");
    const QString why = validate(opts);
    if (!why.isEmpty()) return why;
    const QString dir = qEnvironmentVariable("XDG_RUNTIME_DIR");
    if (dir.isEmpty() || !QFileInfo(dir).isDir()) return tr("Falta XDG_RUNTIME_DIR.");
    auto secret = [&](const QString &value) -> QString {
        const QString f = dir + "/bc-install-" + QUuid::createUuid().toString(QUuid::Id128);
        QSaveFile s(f);
        if (!s.open(QIODevice::WriteOnly)) return {};
        s.setPermissions(QFile::ReadOwner | QFile::WriteOwner);
        s.write(value.toUtf8() + "\n");
        if (!s.commit()) return {};
        m_secretFiles << f;
        return f;
    };
    const QString pw = secret(opts.value("password").toString());
    if (pw.isEmpty()) return tr("No se pudo preparar la instalación.");
    QStringList args{m_program, "--auto", "--gui", "--disk", opts.value("disk").toString(), "--user", opts.value("user").toString(),
                     "--password-file", pw, "--hostname", opts.value("hostname").toString(),
                     "--keymap", opts.value("keymap").toString(), "--timezone", opts.value("timezone").toString()};
    if (opts.value("encrypt").toBool()) args << "--encrypt";
    m_progress = 0; m_copyBase = -1; m_step = tr("Preparando…"); m_error.clear(); m_finished = false; m_buf.clear();
    // pkexec: la ISO live trae una regla polkit que lo permite al usuario de la sesión (org.bcos.instalar)
    const QString runner = qEnvironmentVariableIsSet("BC_INSTALL_TEST") ? qEnvironmentVariable("BC_INSTALL_RUNNER", "pkexec") : QStringLiteral("pkexec");
    if (runner == "-") m_proc.start(args.takeFirst(), args); else m_proc.start(runner, args);
    emit stateChanged();
    return {};
}

void Installer::feedLine(const QString &line) {
    static const QRegularExpression stepRe("^\\[(\\d{1,3})%\\]\\s*(.*)$"), copyRe("^@copia\\s+(\\d{1,3})$"),
        errRe("^ERROR:\\s*(.*)$");
    if (const auto m = stepRe.match(line); m.hasMatch()) {
        m_progress = qBound(0, m.captured(1).toInt(), 99);
        m_step = m.captured(2);
        // La copia es el paso largo: ocupa del valor anterior al anunciado (30 %)
        m_copyBase = line.contains(QStringLiteral("Copi"), Qt::CaseInsensitive) ? qMax(0, m_progress - 30) : -1;
        if (m_copyBase >= 0) m_progress = m_copyBase;   // la barra avanza con la copia real, sin saltar al final
        emit stateChanged();
    } else if (const auto c = copyRe.match(line); c.hasMatch() && m_copyBase >= 0) {
        m_progress = qBound(0, m_copyBase + c.captured(1).toInt() * 30 / 100, 99);
        emit stateChanged();
    } else if (const auto e = errRe.match(line); e.hasMatch()) {
        m_error = e.captured(1);
        emit stateChanged();
    }
}

void Installer::cleanupSecrets() {
    for (const QString &f : std::as_const(m_secretFiles)) {
        QFile x(f);
        if (x.open(QIODevice::ReadWrite)) { x.write(QByteArray(x.size(), '\0')); x.close(); }
        QFile::remove(f);
    }
    m_secretFiles.clear();
}

void Installer::reboot() { QProcess::startDetached("systemctl", {"reboot"}); }
