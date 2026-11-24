#pragma once
#include <QAtomicInt>
#include <QElapsedTimer>
#include <QJsonObject>
#include <QObject>
#include <QPointer>
#include <QString>

class QQuickWindow;

// BC Adaptive Renderer (lado Qt). Un único punto de verdad sobre la calidad gráfica en cada proceso BC (panel,
// apps, login, instalador):
//   1. Antes de crear la aplicación: elige el backend de Qt Quick (vulkan → opengl → software) según
//      BC_RENDER_BACKEND, QT_QUICK_BACKEND, el perfil de BC Core y lo que de verdad hay en el equipo.
//   2. Lee el nivel y sus parámetros de BC Core (org.bcos.Hardware1, 250 ms como mucho), si no de la caché en disco
//      (~/.cache/bc/render-profile.json) y si no usa valores seguros. BC_RENDER_TIER lo fuerza.
//   3. Expone a QML (singleton «Render») los parámetros por efecto: lente, aberración, desenfoque, sombras,
//      animaciones, genio, antialias, capas…, y avisa cuando cambian en caliente (señal de BC Core o Ajustes).
//   4. Vigila el tiempo de fotograma de sus ventanas: si se pierden fotogramas de forma sostenida lo informa a
//      BC Core (que puede bajar el nivel para todo el sistema) y, sin BC Core, rebaja un nivel en local.
class RenderEngine : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString tier READ tier NOTIFY changed)              // ultra, alto, equilibrado, eficiente, minimo
    Q_PROPERTY(int tierIndex READ tierIndex NOTIFY changed)        // 4 … 0
    Q_PROPERTY(QString tierName READ tierName NOTIFY changed)      // nombre para mostrar
    Q_PROPERTY(QString quality READ quality NOTIFY changed)        // preferencia del usuario: auto o un nivel
    Q_PROPERTY(QString backend READ backend CONSTANT)              // backend de Qt Quick de este proceso
    Q_PROPERTY(bool software READ software CONSTANT)
    Q_PROPERTY(QString source READ source NOTIFY changed)          // bc-core, cache, entorno, local
    Q_PROPERTY(bool lens READ lens NOTIFY changed)
    Q_PROPERTY(bool aberration READ aberration NOTIFY changed)
    Q_PROPERTY(int blurPx READ blurPx NOTIFY changed)
    Q_PROPERTY(bool translucency READ translucency NOTIFY changed)
    Q_PROPERTY(int shadows READ shadows NOTIFY changed)            // 0, 1, 2 capas
    Q_PROPERTY(qreal animScale READ animScale NOTIFY changed)      // multiplicador de duraciones
    Q_PROPERTY(bool genie READ genie NOTIFY changed)
    Q_PROPERTY(bool scaleAnimations READ scaleAnimations NOTIFY changed)   // escalar capas al animar (caro sin GPU)
    Q_PROPERTY(bool antialias READ antialias NOTIFY changed)
    Q_PROPERTY(int offscreenLayers READ offscreenLayers NOTIFY changed)
    Q_PROPERTY(QString profileJson READ profileJson NOTIFY changed)
    Q_PROPERTY(QString gpuSummary READ gpuSummary NOTIFY changed)
    Q_PROPERTY(qreal frameMs READ frameMs NOTIFY statsChanged)     // media de la última ventana de medida
    Q_PROPERTY(qreal droppedPct READ droppedPct NOTIFY statsChanged)
public:
    static RenderEngine *instance();
    // Llamar ANTES de crear QGuiApplication: decide el backend de Qt Quick de este proceso
    static QString configureBackend();
    // Rutas (respetan XDG_CACHE_HOME / XDG_CONFIG_HOME): las usan también las pruebas
    static QString cachePath();
    static QString qualityPath();
    static const QStringList &tiers();

    QString tier() const { return m_tier; }
    int tierIndex() const;
    QString tierName() const;
    QString quality() const { return m_quality; }
    QString backend() const { return s_backend; }
    bool software() const { return s_backend == QLatin1String("software"); }
    QString source() const { return m_source; }
    bool lens() const { return param("vidrio_lente").toBool(); }
    bool aberration() const { return param("vidrio_aberracion").toBool(); }
    int blurPx() const { return param("vidrio_blur_px").toInt(); }
    bool translucency() const { return param("translucidez").toBool(); }
    int shadows() const { return param("sombras").toInt(); }
    // BC_ANIM_SLOW=N: animaciones N veces más lentas (diagnóstico, como la «cámara lenta» de macOS)
    qreal animScale() const { const qreal k = qEnvironmentVariable("BC_ANIM_SLOW").toDouble(); return param("animaciones").toDouble() * (k > 0 ? k : 1.0); }
    bool genie() const { return param("genio").toBool() && !software(); }
    bool scaleAnimations() const { return !software() && tierIndex() >= 2; }
    bool antialias() const { return param("antialias").toBool(); }
    int offscreenLayers() const { return param("capas_offscreen").toInt(); }
    QString profileJson() const;
    QString gpuSummary() const;
    qreal frameMs() const { return m_frameMs; }
    qreal droppedPct() const { return m_droppedPct; }
    // Para hilos de carga (GlassProvider): sin bloquear
    static int blurPxAtomic() { return s_blurPx.loadRelaxed(); }
    static bool lensAtomic() { return s_lens.loadRelaxed(); }

    // Ajustes ▸ Pantallas ▸ Calidad gráfica: «auto» o un nivel. Guarda, pide a BC Core que reevalúe y aplica
    // la configuración gráfica del compositor (bc-render-apply).
    Q_INVOKABLE void setQuality(const QString &q);
    Q_INVOKABLE void reload();
    // Empieza a medir los fotogramas de una ventana (las ventanas BC se registran solas desde main)
    void watch(QQuickWindow *w);
    Q_INVOKABLE void watchWindow(QObject *w);
    // Para pruebas: aplica un perfil JSON como si llegara de BC Core
    void applyJson(const QByteArray &json, const QString &source);
    // Ventana de medida terminada (expuesta para pruebas): devuelve true si ha rebajado el nivel en local
    bool frameWindow(qreal meanMs, qreal droppedPct);

protected:
    bool eventFilter(QObject *o, QEvent *e) override;

signals:
    void changed();
    void statsChanged();

private slots:
    void onCoreChanged(const QString &nivel, const QString &perfil);

private:
    explicit RenderEngine(QObject *parent = nullptr);
    QVariant param(const char *k) const { return m_params.value(QLatin1String(k)).toVariant(); }
    void load();
    bool loadFromCore();
    bool loadFromCache();
    void loadDefaults();
    void applyOverrides();
    void publish();

    static QString s_backend;
    static QAtomicInt s_blurPx, s_lens;
    QString m_tier = QStringLiteral("eficiente");
    QString m_quality = QStringLiteral("auto");
    QString m_source;
    QJsonObject m_profile, m_params;
    QJsonObject m_base;           // perfil tal como llegó (BC Core, caché o valores por defecto), sin ajustes locales
    bool m_coreConnected = false;
    int m_localDrop = 0;          // niveles rebajados en local (sin BC Core)
    int m_bad = 0, m_good = 0;
    qreal m_frameMs = 0, m_droppedPct = 0;
    // Medida de fotogramas: tiempo de sincronizar+dibujar de cada fotograma
    struct Meter { QPointer<QQuickWindow> win; QElapsedTimer t; qint64 sum = 0; int n = 0, slow = 0; };
    QList<Meter *> m_meters;
};
