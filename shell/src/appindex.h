#pragma once
#include <QObject>
#include <QVariantList>

// Índice de aplicaciones .desktop (XDG) para el lanzador con búsqueda.
class AppIndex : public QObject {
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY changed)
public:
    struct Entry { QString id, name, exec, icon, comment; bool terminal = false; };
    explicit AppIndex(const QStringList &dirs = QStringList(), const QString &lang = QString(), QObject *parent = nullptr);
    int count() const { return m_entries.size(); }
    Q_INVOKABLE QVariantList search(const QString &query) const;
    Q_INVOKABLE bool launch(const QString &id);
    Q_INVOKABLE void reload();
    // Lectura de un .desktop; devuelve false si debe ocultarse (NoDisplay, Hidden, no es Application...).
    static bool parseDesktop(const QString &text, const QString &lang, Entry &out);
    // Quita códigos de campo (%f %u ...) y separa en programa + argumentos.
    static QStringList commandFor(const QString &exec, bool terminal);
signals:
    void changed();

private:
    QStringList m_dirs;
    QString m_lang;
    QList<Entry> m_entries;
};
