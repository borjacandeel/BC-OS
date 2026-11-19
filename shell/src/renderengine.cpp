#include "renderengine.h"
#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCall>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QProcess>
#include <QQuickWindow>
#include <QSGRendererInterface>
#include <QStandardPaths>
#include <QThread>

static const char *kService = "org.bcos.Hardware";
static const char *kPath = "/org/bcos/Hardware";
static const char *kIface = "org.bcos.Hardware1";

QString RenderEngine::s_backend = QStringLiteral("opengl");
QAtomicInt RenderEngine::s_blurPx(22);
QAtomicInt RenderEngine::s_lens(0);

const QStringList &RenderEngine::tiers() {
    static const QStringList t{QStringLiteral("minimo"), QStringLiteral("eficiente"), QStringLiteral("equilibrado"),
                               QStringLiteral("alto"), QStringLiteral("ultra")};
    return t;
}

static QString xdg(const char *var, const char *fallback) {
    const QString v = qEnvironmentVariable(var);
    return v.isEmpty() ? QDir::homePath() + QLatin1Char('/') + QLatin1String(fallback) : v;
}
QString RenderEngine::cachePath() { return xdg("XDG_CACHE_HOME", ".cache") + QStringLiteral("/bc/render-profile.json"); }
QString RenderEngine::qualityPath() { return xdg("XDG_CONFIG_HOME", ".config") + QStringLiteral("/bc/calidad"); }

static bool hasRenderNode() {
    const QString root = qEnvironmentVariable("BC_HW_ROOT", QStringLiteral("/"));
    return !QDir(root + QStringLiteral("/dev/dri")).entryList({QStringLiteral("renderD*")}, QDir::System | QDir::Files | QDir::AllEntries).isEmpty();
}
static bool hasVulkanIcd() {
    for (const char *d : {"/usr/share/vulkan/icd.d", "/etc/vulkan/icd.d"})
        if (!QDir(QLatin1String(d)).entryList({QStringLiteral("*.json")}, QDir::Files).isEmpty()) return true;
    return false;
}

QString RenderEngine::configureBackend() {
    // Petición: BC_RENDER_BACKEND > QT_QUICK_BACKEND de la sesión > perfil de BC Core en caché > automático
    QString want = qEnvironmentVariable("BC_RENDER_BACKEND").trimmed().toLower();
    const QString qtb = qEnvironmentVariable("QT_QUICK_BACKEND");
    if (want.isEmpty() && (qtb == QLatin1String("software") || qtb == QLatin1String("softwarecontext"))) want = QStringLiteral("software");
    QJsonObject cached;
    {
        QFile f(cachePath());
        if (f.open(QIODevice::ReadOnly)) cached = QJsonDocument::fromJson(f.readAll()).object();
    }
    if (want.isEmpty()) want = cached.value(QLatin1String("parametros")).toObject().value(QLatin1String("backend")).toString();
    if (want.isEmpty()) want = QStringLiteral("auto");
    // Cadena de reserva: vulkan → opengl → software, según lo que haya de verdad
    const QString platform = qEnvironmentVariable("QT_QPA_PLATFORM");
    const bool offscreen = platform.startsWith(QLatin1String("offscreen")) || platform.startsWith(QLatin1String("minimal"));
    const bool gpu = hasRenderNode() && !offscreen;
    QString b = want;
    if (b == QLatin1String("auto")) b = gpu ? QStringLiteral("opengl") : QStringLiteral("software");
    if (b == QLatin1String("vulkan") && !(gpu && hasVulkanIcd())) b = QStringLiteral("opengl");
    if ((b == QLatin1String("opengl") || b == QLatin1String("rhi")) && !gpu) b = QStringLiteral("software");
    if (b != QLatin1String("vulkan") && b != QLatin1String("opengl") && b != QLatin1String("software")) b = gpu ? QStringLiteral("opengl") : QStringLiteral("software");
    if (b == QLatin1String("vulkan")) QQuickWindow::setGraphicsApi(QSGRendererInterface::Vulkan);
    else if (b == QLatin1String("opengl")) {
        QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);
        // El panel tiene muchas superficies (barra, Dock, widgets, capas emergentes…): con el bucle «threaded» de Qt
        // cada una lleva su hilo, su contexto OpenGL y sus búferes. En un equipo real con nouveau eran 25 hilos y
        // 456 MB. Con GPU lenta (nouveau) o nivel bajo, bucle «basic»: un solo contexto compartido por todas.
        const QString nivel = cached.value(QLatin1String("nivel")).toString();
        const QJsonArray g = cached.value(QLatin1String("gpus")).toArray();
        const bool nouveau = !g.isEmpty() && g.first().toObject().value(QLatin1String("controlador")).toString() == QLatin1String("nouveau");
        if (!qEnvironmentVariableIsSet("QSG_RENDER_LOOP") && (nouveau || nivel == QLatin1String("eficiente") || nivel == QLatin1String("minimo")))
            qputenv("QSG_RENDER_LOOP", "basic");
    }
    else {
        QQuickWindow::setGraphicsApi(QSGRendererInterface::Software);
        // Las ventanas hijas y procesos que lancen lo heredan; el resto del código lo consulta así
        qputenv("QT_QUICK_BACKEND", "software");
    }
    s_backend = b;
    return b;
}

static QString compositorNow() {
    if (qEnvironmentVariable("BC_COMPOSITOR") == QLatin1String("hyprland") || qEnvironmentVariableIsSet("HYPRLAND_INSTANCE_SIGNATURE"))
        return QStringLiteral("hyprland");
    if (qEnvironmentVariable("XDG_SESSION_TYPE") == QLatin1String("x11")) return QStringLiteral("x11");
    if (qEnvironmentVariableIsSet("BC_FX")) return QStringLiteral("swayfx");
    return QStringLiteral("sway");
}

// Misma tabla que BC Core (core/crates/bc-hardware-service/src/render.rs, fn parametros): se usa sin BC Core
static QJsonObject localParams(int n, bool gpuReal) {
    struct P { bool lente, aberr; int blur; bool transl; int sombras; double anim; bool genio; int tex, capas, cbs, cbp; };
    static const P t[5] = {
        {false, false, 18, false, 0, 0.70, false, 96, 1, 0, 0},     // mínimo
        {false, false, 22, true, 1, 0.85, false, 160, 2, 4, 1},     // eficiente
        {true, false, 26, true, 1, 1.0, true, 256, 4, 6, 2},        // equilibrado
        {true, true, 30, true, 2, 1.0, true, 384, 6, 8, 3},         // alto
        {true, true, 32, true, 2, 1.0, true, 512, 8, 10, 3},        // ultra
    };
    const P &p = t[qBound(0, n, 4)];
    const QString comp = compositorNow();
    const bool hypr = comp == QLatin1String("hyprland"), fx = hypr || comp == QLatin1String("swayfx");
    return QJsonObject{
        {"backend", gpuReal ? "opengl" : "software"}, {"vidrio_lente", p.lente}, {"vidrio_aberracion", p.aberr},
        {"vidrio_blur_px", p.blur}, {"vidrio_blur_real", hypr && p.cbs > 0}, {"translucidez", p.transl},
        {"sombras", p.sombras}, {"animaciones", p.anim}, {"genio", p.genio && gpuReal}, {"antialias", n >= 2},
        {"texturas_mb", p.tex}, {"capas_offscreen", p.capas}, {"compositor_blur_size", fx ? p.cbs : 0},
        {"compositor_blur_passes", fx ? p.cbp : 0}, {"compositor_sombras", fx && p.sombras > 0},
        {"compositor_animaciones", hypr && n >= 1}, {"radio_esquinas", 12}};
}

RenderEngine *RenderEngine::instance() {
    static RenderEngine *e = new RenderEngine(QCoreApplication::instance());
    return e;
}

RenderEngine::RenderEngine(QObject *parent) : QObject(parent) {
    QDBusConnection bus = QDBusConnection::sessionBus();
    if (bus.isConnected())
        bus.connect(QLatin1String(kService), QLatin1String(kPath), QLatin1String(kIface), QStringLiteral("NivelRenderCambiado"),
                    this, SLOT(onCoreChanged(QString, QString)));
    load();
}

int RenderEngine::tierIndex() const { return qMax(0, tiers().indexOf(m_tier)); }

QString RenderEngine::tierName() const {
    static const char *n[5] = {QT_TR_NOOP("Mínimo"), QT_TR_NOOP("Eficiente"), QT_TR_NOOP("Equilibrado"), QT_TR_NOOP("Alto"), QT_TR_NOOP("Ultra")};
    return tr(n[tierIndex()]);
}

QString RenderEngine::profileJson() const {
    return QString::fromUtf8(QJsonDocument(m_profile).toJson(QJsonDocument::Compact));
}

QString RenderEngine::gpuSummary() const {
    const QJsonArray g = m_profile.value(QLatin1String("gpus")).toArray();
    if (g.isEmpty() || software()) return tr("Renderizado por software");
    const QJsonObject o = g.first().toObject();
    return QStringLiteral("%1 (%2)").arg(o.value(QLatin1String("fabricante")).toString(), o.value(QLatin1String("controlador")).toString());
}

void RenderEngine::load() {
    QFile q(qualityPath());
    m_quality = q.open(QIODevice::ReadOnly) ? QString::fromUtf8(q.readAll()).trimmed().toLower() : QString();
    if (!tiers().contains(m_quality)) m_quality = QStringLiteral("auto");
    // BC_RENDER_DISABLE_CORE=1 (pruebas): no preguntar a BC Core
    const bool core = qEnvironmentVariable("BC_RENDER_DISABLE_CORE") != QLatin1String("1");
    if (!(core && loadFromCore()) && !loadFromCache()) loadDefaults();
    applyOverrides();
    publish();
}

void RenderEngine::applyJson(const QByteArray &json, const QString &source) {
    const QJsonObject o = QJsonDocument::fromJson(json).object();
    if (o.isEmpty() || !tiers().contains(o.value(QLatin1String("nivel")).toString())) return;
    m_profile = o;
    m_params = o.value(QLatin1String("parametros")).toObject();
    m_tier = o.value(QLatin1String("nivel")).toString();
    m_source = source;
    m_base = m_profile;
}

bool RenderEngine::loadFromCore() {
    QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.isConnected()) return false;
    const QDBusMessage r = bus.call(QDBusMessage::createMethodCall(QLatin1String(kService), QLatin1String(kPath),
                                                                    QLatin1String(kIface), QStringLiteral("PerfilRender")),
                                    QDBus::Block, 250);
    if (r.type() != QDBusMessage::ReplyMessage || r.arguments().isEmpty()) return false;
    applyJson(r.arguments().first().toString().toUtf8(), QStringLiteral("bc-core"));
    m_coreConnected = m_source == QLatin1String("bc-core");
    return m_coreConnected;
}

bool RenderEngine::loadFromCache() {
    QFile f(cachePath());
    if (!f.open(QIODevice::ReadOnly)) return false;
    applyJson(f.readAll(), QStringLiteral("cache"));
    return m_source == QLatin1String("cache");
}

void RenderEngine::loadDefaults() {
    // Sin BC Core ni caché: con GPU, «equilibrado»; por software, «eficiente»
    const bool gpu = !software();
    m_tier = gpu ? QStringLiteral("equilibrado") : QStringLiteral("eficiente");
    m_params = localParams(tierIndex(), gpu);
    m_profile = QJsonObject{{"nivel", m_tier}, {"parametros", m_params}};
    m_source = QStringLiteral("local");
    m_base = m_profile;
}

void RenderEngine::applyOverrides() {
    // Siempre desde el perfil de partida: las rebajas no se acumulan al recalcular
    m_profile = m_base;
    m_params = m_base.value(QLatin1String("parametros")).toObject();
    m_tier = m_base.value(QLatin1String("nivel")).toString();
    if (m_source == QLatin1String("entorno")) m_source = m_coreConnected ? QStringLiteral("bc-core") : QStringLiteral("local");
    int n = tierIndex();
    const QString env = qEnvironmentVariable("BC_RENDER_TIER").trimmed().toLower();
    const bool gpu = !software();
    // El nivel nunca supera lo que el backend de este proceso puede dibujar con fluidez
    const int techo = gpu ? 4 : 1;
    if (tiers().contains(env)) { n = qMin(tiers().indexOf(env), techo); m_source = QStringLiteral("entorno"); }
    else if (m_source != QLatin1String("bc-core") && m_quality != QLatin1String("auto")) n = qMin(tiers().indexOf(m_quality), techo);
    n = qMax(0, n - m_localDrop);
    if (n != tierIndex() || m_source == QLatin1String("entorno") || m_localDrop > 0) {
        m_tier = tiers().at(n);
        m_params = localParams(n, gpu);
        m_profile.insert(QStringLiteral("nivel"), m_tier);
        m_profile.insert(QStringLiteral("parametros"), m_params);
    }
}

void RenderEngine::publish() {
    s_blurPx.storeRelaxed(blurPx());
    s_lens.storeRelaxed(lens() ? 1 : 0);
    emit changed();
}

void RenderEngine::reload() { load(); }

void RenderEngine::onCoreChanged(const QString &nivel, const QString &perfil) {
    Q_UNUSED(nivel)
    applyJson(perfil.toUtf8(), QStringLiteral("bc-core"));
    m_coreConnected = true;
    m_localDrop = 0;
    QFile q(qualityPath());
    m_quality = q.open(QIODevice::ReadOnly) ? QString::fromUtf8(q.readAll()).trimmed().toLower() : QStringLiteral("auto");
    if (!tiers().contains(m_quality)) m_quality = QStringLiteral("auto");
    applyOverrides();
    publish();
}

void RenderEngine::setQuality(const QString &q) {
    const QString v = tiers().contains(q) ? q : QStringLiteral("auto");
    QDir().mkpath(QFileInfo(qualityPath()).absolutePath());
    if (v == QLatin1String("auto")) QFile::remove(qualityPath());
    else {
        QFile f(qualityPath());
        if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) f.write(v.toUtf8() + '\n');
    }
    m_quality = v;
    m_localDrop = 0;
    if (m_coreConnected) {
        // BC Core lee la preferencia, recalcula y avisa a todos los procesos con NivelRenderCambiado
        QDBusConnection::sessionBus().asyncCall(QDBusMessage::createMethodCall(
            QLatin1String(kService), QLatin1String(kPath), QLatin1String(kIface), QStringLiteral("ReevaluarRender")));
    } else {
        load();
    }
    // Compositor (Hyprland/swayfx): desenfoque, sombras y animaciones según el nivel, en caliente
    const QString apply = QStandardPaths::findExecutable(QStringLiteral("bc-render-apply"));
    if (!apply.isEmpty()) QProcess::startDetached(apply, {});
    emit changed();
}

void RenderEngine::watchWindow(QObject *w) { watch(qobject_cast<QQuickWindow *>(w)); }

void RenderEngine::watch(QQuickWindow *w) {
    if (!w) return;
    for (const Meter *m : std::as_const(m_meters)) if (m->win == w) return;
    auto *m = new Meter;
    m->win = w;
    m_meters.append(m);
    connect(w, &QObject::destroyed, this, [this, m] { m_meters.removeOne(m); delete m; });
    // Coste de cada fotograma: de sincronizar a terminar de dibujar (en el hilo de render si lo hay)
    connect(w, &QQuickWindow::beforeSynchronizing, w, [m] { m->t.start(); }, Qt::DirectConnection);
    connect(w, &QQuickWindow::afterRendering, w, [this, m] {
        if (!m->t.isValid()) return;
        const qint64 us = m->t.nsecsElapsed() / 1000;
        m->t.invalidate();
        m->sum += us;
        ++m->n;
        if (us > 16667) ++m->slow;
        if (m->n >= 180) {
            const qreal mean = qreal(m->sum) / m->n / 1000.0, dropped = 100.0 * m->slow / m->n;
            m->sum = 0; m->n = 0; m->slow = 0;
            QMetaObject::invokeMethod(this, [this, mean, dropped] { frameWindow(mean, dropped); }, Qt::QueuedConnection);
        }
    }, Qt::DirectConnection);
}

bool RenderEngine::frameWindow(qreal meanMs, qreal droppedPct) {
    m_frameMs = meanMs;
    m_droppedPct = droppedPct;
    emit statsChanged();
    if (m_coreConnected) {
        // BC Core decide para todo el sistema (con histéresis): un solo criterio para todos los procesos
        QDBusMessage msg = QDBusMessage::createMethodCall(QLatin1String(kService), QLatin1String(kPath), QLatin1String(kIface),
                                                          QStringLiteral("ReportarFotogramas"));
        msg << meanMs << droppedPct;
        QDBusConnection::sessionBus().asyncCall(msg);
        return false;
    }
    // Sin BC Core: misma regla en local (3 ventanas malas rebajan; 6 buenas devuelven)
    if (droppedPct >= 8.0) { ++m_bad; m_good = 0; }
    else if (droppedPct <= 1.0) { ++m_good; m_bad = 0; }
    int drop = m_localDrop;
    if (m_bad >= 3 && tierIndex() > 0) { ++drop; m_bad = 0; }
    else if (m_good >= 6 && m_localDrop > 0) { --drop; m_good = 0; }
    if (drop == m_localDrop) return false;
    m_localDrop = drop;
    const int before = tierIndex();
    applyOverrides();
    publish();
    return tierIndex() != before;
}
