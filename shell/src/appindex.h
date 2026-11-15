#pragma once
#include <QObject>
#include <QVariantList>

// Índice de aplicaciones .desktop (XDG) para el lanzador con búsqueda.
class AppIndex : public QObject {
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY changed)
public:
    struct Entry { QString id, name, exec, icon, comment, category; bool terminal = false; };
    explicit AppIndex(const QStringList &dirs = QStringList(), const QString &lang = QString(), QObject *parent = nullptr);
    int count() const { return m_entries.size(); }
    static bool isHiddenId(const QString &id);
    // Ruta de archivo del icono de una app (nombre del tema o ruta absoluta); vacía si no se encuentra. `roots` = carpetas de iconos.
    static QString resolveIcon(const QString &name, const QStringList &roots = {});
    Q_INVOKABLE QVariantList search(const QString &query) const;
    Q_INVOKABLE bool launch(const QString &id);
    Q_INVOKABLE void reload();
    // Datos (id, name, icon) de la app de una ventana a partir de su app_id/clase; vacío si no se encuentra.
    Q_INVOKABLE QVariantMap infoFor(const QString &appId) const;
    // Lectura de un .desktop; devuelve false si debe ocultarse (NoDisplay, Hidden, no es Application...).
    static bool parseDesktop(const QString &text, const QString &lang, Entry &out);
    // Quita códigos de campo (%f %u ...) y separa en programa + argumentos.
    static QStringList commandFor(const QString &exec, bool terminal);
    // Categoría de la vista Aplicaciones a partir de Categories= (Productividad, Creatividad, Utilidades, Juegos, Sistema, Internet)
    static QString categoryFor(const QString &categories);
signals:
    void changed();

private:
    QStringList m_dirs;
    QString m_lang;
    QList<Entry> m_entries;
};
