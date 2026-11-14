#pragma once
#include <QObject>
#include <QString>
#include <QVariantList>

// Usuarios "humanos" del sistema (uid 1000..59999 con shell de login) para el login.
class UserList : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList users READ users CONSTANT)
public:
    explicit UserList(const QString &passwdPath = QString(), QObject *parent = nullptr);
    QVariantList users() const { return m_users; }
    static QVariantList parse(const QString &passwdPath);

private:
    QVariantList m_users;
};
