// Pruebas de BC Adaptive Renderer (lado Qt): cadena de reserva, caché, preferencias y rebaja por fotogramas
#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QTemporaryDir>
#include <QtTest>
#include "../src/renderengine.h"

class TstRender : public QObject {
    Q_OBJECT
    QTemporaryDir tmp;
    void writeCache(const QByteArray &j) {
        QDir().mkpath(tmp.path() + "/cache/bc");
        QFile f(tmp.path() + "/cache/bc/render-profile.json");
        QVERIFY(f.open(QIODevice::WriteOnly)); f.write(j);
    }
private slots:
    void initTestCase() {
        qputenv("XDG_CACHE_HOME", (tmp.path() + "/cache").toUtf8());
        qputenv("XDG_CONFIG_HOME", (tmp.path() + "/config").toUtf8());
        qputenv("BC_RENDER_DISABLE_CORE", "1");
    }
    void init() { QFile::remove(RenderEngine::cachePath()); QFile::remove(RenderEngine::qualityPath()); qunsetenv("BC_RENDER_TIER"); }
    void backendSoftwareSinGpu() {
        // offscreen: no hay GPU utilizable → software aunque se pida vulkan
        QCOMPARE(RenderEngine::instance()->backend(), QString("software"));
        QVERIFY(RenderEngine::instance()->software());
    }
    void valoresSegurosSinNada() {
        auto *e = RenderEngine::instance(); e->reload();
        QCOMPARE(e->tier(), QString("eficiente"));
        QCOMPARE(e->source(), QString("local"));
        QVERIFY(!e->lens()); QVERIFY(!e->genie()); QVERIFY(!e->scaleAnimations());
    }
    void leeLaCache() {
        writeCache(R"({"nivel":"minimo","gpus":[{"fabricante":"VMware","controlador":"vmwgfx"}],"parametros":{"vidrio_lente":false,"vidrio_blur_px":18,"sombras":0,"animaciones":0.7,"translucidez":false}})");
        auto *e = RenderEngine::instance(); e->reload();
        QCOMPARE(e->tier(), QString("minimo")); QCOMPARE(e->source(), QString("cache"));
        QCOMPARE(e->blurPx(), 18); QCOMPARE(e->shadows(), 0); QCOMPARE(RenderEngine::blurPxAtomic(), 18);
        QCOMPARE(e->gpuSummary(), QString("Renderizado por software"));
    }
    void entornoNoSuperaElBackend() {
        qputenv("BC_RENDER_TIER", "ultra");
        auto *e = RenderEngine::instance(); e->reload();
        QCOMPARE(e->tier(), QString("eficiente"));   // por software, como mucho «eficiente»
        qputenv("BC_RENDER_TIER", "minimo"); e->reload();
        QCOMPARE(e->tier(), QString("minimo")); QCOMPARE(e->source(), QString("entorno"));
    }
    void preferenciaDeAjustes() {
        auto *e = RenderEngine::instance();
        QSignalSpy spy(e, &RenderEngine::changed);
        e->setQuality("minimo");
        QCOMPARE(e->quality(), QString("minimo")); QCOMPARE(e->tier(), QString("minimo"));
        QVERIFY(QFile::exists(RenderEngine::qualityPath())); QVERIFY(spy.count() > 0);
        e->setQuality("auto");
        QVERIFY(!QFile::exists(RenderEngine::qualityPath())); QCOMPARE(e->tier(), QString("eficiente"));
    }
    void rebajaPorFotogramasConHisteresis() {
        auto *e = RenderEngine::instance(); e->reload();
        QCOMPARE(e->tier(), QString("eficiente"));
        QVERIFY(!e->frameWindow(25, 20)); QVERIFY(!e->frameWindow(25, 20));
        QVERIFY(e->frameWindow(25, 20));
        QCOMPARE(e->tier(), QString("minimo")); QCOMPARE(e->droppedPct(), 20.0);
        for (int i = 0; i < 5; ++i) QVERIFY(!e->frameWindow(4, 0));
        QVERIFY(e->frameWindow(4, 0));
        QCOMPARE(e->tier(), QString("eficiente"));
    }
};

int main(int argc, char **argv) {
    qputenv("QT_QPA_PLATFORM", "offscreen");
    qputenv("BC_RENDER_BACKEND", "vulkan");
    RenderEngine::configureBackend();
    QGuiApplication app(argc, argv);
    TstRender t;
    return QTest::qExec(&t, argc, argv);
}
#include "tst_render.moc"
