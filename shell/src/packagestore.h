#pragma once
#include <QAbstractListModel>
#include <QProcess>
#include <QVariantMap>

// BC Tienda: interfaz gráfica sobre pacman. Buscar y listar sin privilegios; instalar, quitar y
// actualizar con sudo (la contraseña se envía por la entrada estándar de sudo y no se guarda en disco).
class PackageStore : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString log READ log NOTIFY logChanged)
    Q_PROPERTY(QVariantMap details READ details NOTIFY detailsChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(bool flathub READ flathub WRITE setFlathub NOTIFY flathubChanged)
    Q_PROPERTY(bool flatpakAvailable READ flatpakAvailable CONSTANT)
public:
    enum Roles { NameRole = Qt::UserRole + 1, RepoRole, VersionRole, DescRole, InstalledRole, IdRole };
    struct Pkg { QString name, repo, version, desc, id; bool installed = false; };
    explicit PackageStore(QObject *parent = nullptr);
    int rowCount(const QModelIndex & = {}) const override { return m_rows.size(); }
    QVariant data(const QModelIndex &i, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    bool busy() const { return m_busy; }
    QString log() const { return m_log; }
    QVariantMap details() const { return m_details; }
    bool flathub() const { return m_flathub; }
    void setFlathub(bool on);
    bool flatpakAvailable() const;

    Q_INVOKABLE void search(const QString &query);     // repositorios
    Q_INVOKABLE void listInstalled();                   // paquetes explícitos instalados
    Q_INVOKABLE void showDetails(const QString &name);
    Q_INVOKABLE void install(const QString &name, const QString &password);
    Q_INVOKABLE void remove(const QString &name, const QString &password);
    Q_INVOKABLE void updateAll(const QString &password);

    static QList<Pkg> parseSearch(const QString &out);
    static QList<Pkg> parseInstalled(const QString &out);
    static QVariantMap parseInfo(const QString &out);
    // Salida de `flatpak search/list --columns=application,name,version,description` (columnas separadas por tabulador)
    static QList<Pkg> parseFlatpak(const QString &out, bool installed);
    static bool validFlatpakId(const QString &id);
    static QStringList sudoArgs(const QStringList &pacmanArgs);
signals:
    void busyChanged();
    void logChanged();
    void detailsChanged();
    void countChanged();
    void flathubChanged();
    void finished(bool ok, const QString &action);

private:
    void runRead(const QStringList &args, std::function<void(const QString &)> done);
    void runPrivileged(const QStringList &pacmanArgs, const QString &password, const QString &action);
    void setBusy(bool b);
    void runFlatpakRead(const QStringList &args, std::function<void(const QString &)> done);
    void runFlatpakWrite(const QStringList &args, const QString &action);
    bool m_flathub = false;
    QList<Pkg> m_rows;
    bool m_busy = false;
    QString m_log;
    QVariantMap m_details;
    quint64 m_gen = 0;
};
