#pragma once
#include <QObject>
#include <QSettings>

// Ajustes persistentes del usuario (QSettings): movimiento reducido, idioma...
class AppSettings : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool reducedMotion READ reducedMotion WRITE setReducedMotion NOTIFY changed)
    Q_PROPERTY(QString desktopStyle READ desktopStyle WRITE setDesktopStyle NOTIFY changed)
    Q_PROPERTY(bool widgets READ widgets WRITE setWidgets NOTIFY changed)
    Q_PROPERTY(QString mode READ mode WRITE setMode NOTIFY changed)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY changed)
public:
    explicit AppSettings(QObject *parent = nullptr);
    bool reducedMotion() const { return m_reduced; }
    QString desktopStyle() const { return m_style; }
    void setDesktopStyle(const QString &s);
    bool widgets() const { return m_widgets; }
    void setWidgets(bool on);
    QString mode() const { return m_mode; }
    void setMode(const QString &m);
    QString language() const { return m_language; }
    void setReducedMotion(bool on);
    void setLanguage(const QString &l);
signals:
    void changed();

private:
    bool m_reduced = false;
    QString m_language = "es_ES";
    QString m_style = "mac";
    bool m_widgets = true;
    QString m_mode;
};
