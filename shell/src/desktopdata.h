#pragma once
#include <QObject>
#include <QTimer>
#include <QVariantList>

// Datos reales para los widgets del escritorio (Golden Gate).

// Baterías: la del equipo y las de periféricos (/sys/class/power_supply) y Bluetooth (org.bluez Battery1).
class Batteries : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList devices READ devices NOTIFY changed)   // [{name, percent, charging, kind}]
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
public:
    explicit Batteries(QObject *parent = nullptr);
    QVariantList devices() const { return m_devices; }
    bool active() const { return m_timer.isActive(); }
    void setActive(bool on);
    Q_INVOKABLE void refresh();
    static QString kindFor(const QString &type, const QString &name);   // laptop, mouse, keyboard, headphones, gamepad, phone, battery
signals:
    void changed();
    void activeChanged();
private:
    QVariantList m_devices;
    QTimer m_timer;
};

// Recordatorios: lista local persistente (~/.local/share/bc/recordatorios.json).
class Reminders : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList items READ items NOTIFY changed)       // [{id, title, done}]
    Q_PROPERTY(int pending READ pending NOTIFY changed)
public:
    explicit Reminders(QObject *parent = nullptr, const QString &file = QString());
    QVariantList items() const { return m_items; }
    int pending() const;
    Q_INVOKABLE void add(const QString &title);
    Q_INVOKABLE void toggle(int id);
    Q_INVOKABLE void remove(int id);
    Q_INVOKABLE void clearDone();
    QString file() const { return m_file; }
signals:
    void changed();
private:
    QString m_file;
    QVariantList m_items;
    void load();
    void save();
};

// Widgets de otras apps: cada app deja un JSON en ~/.local/share/bc/widgets/<id>.json
// { "title": "…", "icon": "nombre-icono", "rows": [{ "label": "…", "detail": "…", "value": 0.4, "right": "…" }] }
// BC OS publica su propio widget «Uso del equipo» con el mismo formato.
class WidgetHost : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList widgets READ widgets NOTIFY changed)
public:
    explicit WidgetHost(QObject *parent = nullptr, const QString &dir = QString());
    QVariantList widgets() const { return m_widgets; }
    Q_INVOKABLE void refresh();
    static QVariantMap parse(const QByteArray &json, const QString &id);
    QString dir() const { return m_dir; }
signals:
    void changed();
private:
    QString m_dir;
    QVariantList m_widgets;
    QTimer m_timer;
};
