#pragma once
#include <QAbstractListModel>
#include <QFileInfoList>
#include <QVariantList>

// Modelo del directorio real con historial, breadcrumb y filtro por nombre.
class FileBrowser : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(QString path READ path NOTIFY pathChanged)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(bool canBack READ canBack NOTIFY historyChanged)
    Q_PROPERTY(bool canForward READ canForward NOTIFY historyChanged)
    Q_PROPERTY(bool canUp READ canUp NOTIFY pathChanged)
    Q_PROPERTY(bool available READ available NOTIFY pathChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(QVariantList crumbs READ crumbs NOTIFY pathChanged)
    Q_PROPERTY(bool inTrash READ inTrash NOTIFY pathChanged)
public:
    enum Roles { NameRole = Qt::UserRole + 1, PathRole, KindRole, IsDirRole };
    explicit FileBrowser(QObject *parent = nullptr);
    int rowCount(const QModelIndex &p = {}) const override { return p.isValid() ? 0 : m_items.size(); }
    QVariant data(const QModelIndex &i, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString path() const { return m_path; }
    QString filter() const { return m_filter; }
    void setFilter(const QString &f);
    bool canBack() const { return m_hpos > 0; }
    bool canForward() const { return m_hpos + 1 < m_history.size(); }
    bool canUp() const;
    bool available() const { return m_available; }
    QVariantList crumbs() const;

    Q_INVOKABLE void open(const QString &path);          // navega (añade al historial)
    Q_INVOKABLE void activate(int row);                   // doble click: entra si es carpeta; abre el archivo con xdg-open
    Q_INVOKABLE void back();
    Q_INVOKABLE void forward();
    Q_INVOKABLE void up();
    Q_INVOKABLE void place(const QString &name);          // home, desktop, documents, downloads, pictures, music
    Q_INVOKABLE QString placePath(const QString &name) const;
    bool inTrash() const;
    Q_INVOKABLE QString trashPath() const;                // ~/.local/share/Trash/files
    Q_INVOKABLE void openTrash();
    Q_INVOKABLE QString nameAt(int row) const;
    Q_INVOKABLE bool newFolder(const QString &name);
    Q_INVOKABLE bool renameAt(int row, const QString &newName);
    Q_INVOKABLE bool trashAt(int row);                    // mueve a la papelera (especificación FreeDesktop)
    Q_INVOKABLE bool restoreAt(int row);                  // solo dentro de la papelera
    Q_INVOKABLE bool deleteAt(int row);                   // eliminación definitiva, solo en la papelera
    Q_INVOKABLE bool emptyTrash();
    Q_INVOKABLE void reload() { load(m_path); }
    static QString kindFor(const QFileInfo &fi);
signals:
    void operationFailed(const QString &message);
    void pathChanged();
    void filterChanged();
    void historyChanged();
    void countChanged();

private:
    void load(const QString &path);
    void refilter();
    QString m_path, m_filter;
    bool m_available = false;
    QFileInfoList m_all, m_items;
    QStringList m_history;
    int m_hpos = -1;
};
