#pragma once
#include <QObject>
#include <QVariantList>

// Historial del portapapeles (cliphist + wl-clipboard). Solo texto en la lista; elegir un elemento lo copia de nuevo.
class ClipboardHistory : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList items READ items NOTIFY itemsChanged)
    Q_PROPERTY(bool available READ available CONSTANT)
public:
    explicit ClipboardHistory(QObject *parent = nullptr) : QObject(parent) {}
    QVariantList items() const { return m_items; }
    bool available() const;
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void pick(const QString &id);     // id numérico de cliphist
    Q_INVOKABLE void clear();
    // `cliphist list`: «<id>\t<vista previa>» por línea; se descartan binarios e ids no numéricos.
    static QVariantList parseList(const QString &out, int max = 40);
signals:
    void itemsChanged();

private:
    QVariantList m_items;
    bool m_busy = false;
};
