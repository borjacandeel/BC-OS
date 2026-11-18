// Terminal de BC OS: como el Terminal de macOS. Ventana sin marco con esquinas redondeadas y fondo translúcido
// dibujados por la propia app (funciona igual con sway por software, sin GPU), semáforo, título centrado
// «usuario — proceso — columnas×filas» con el icono de carpeta, paleta clara u oscura según el aspecto del sistema,
// redimensionable desde los bordes y con atajos de macOS (⌃⇧C/V, ⌃N, ⌃W, ⌃+/⌃−).
// El texto lo dibuja QTermWidget con la CPU (QPainter): rápido aunque no haya aceleración 3D.
#include <qtermwidget.h>

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QScreen>
#include <functional>
#include <QApplication>
#include <QContextMenuEvent>
#include <QDir>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QFontDatabase>
#include <QIcon>
#include <QMenu>
#include <QMouseEvent>
#include <QPainter>
#include <QPainterPath>
#include <QProcess>
#include <QSettings>
#include <QShortcut>
#include <QStandardPaths>
#include <QTime>
#include <QTimer>
#include <QVBoxLayout>
#include <QWindow>

namespace {
constexpr int kShadow = 18;      // margen transparente para la sombra (sway por software no dibuja sombras)
constexpr int kRadius = 12;      // radio de la ventana del Terminal de macOS
constexpr int kTitleH = 28;      // barra de título del Terminal de macOS
constexpr int kGrip = 6;
constexpr qreal kOpacity = 0.94;  // translucidez del perfil «Básico» con transparencia

bool systemDark() {
    QSettings s("BC-OS", "bc-shell");
    const QString a = s.value("aspecto", "dark").toString();
    if (a == "light") return false;
    if (a == "auto") { const int h = QTime::currentTime().hour(); return h < 8 || h >= 20; }
    return true;
}
}

class TitleBar;

class TerminalWindow : public QWidget {
public:
    explicit TerminalWindow(const QString &workdir) {
        setAttribute(Qt::WA_TranslucentBackground);
        setWindowFlag(Qt::FramelessWindowHint);
        setWindowTitle(QStringLiteral("Terminal"));
        setMouseTracking(true);
        setMinimumSize(360 + 2 * kShadow, 200 + 2 * kShadow);

        term = new QTermWidget(0, this);
        // Paletas propias (BC-Oscuro y BC-Claro: perfil «Básico» del Terminal de macOS)
        for (const QString &d : {QStringLiteral("/usr/share/bc/terminal"), QCoreApplication::applicationDirPath() + "/../share/bc/terminal",
                                 QCoreApplication::applicationDirPath() + "/terminal"})
            if (QFileInfo::exists(d)) QTermWidget::addCustomColorSchemeDir(d);
        // CaskaydiaCove Nerd Font (Cascadia Code con iconos Nerd: git, carpetas…); si falta, DejaVu Sans Mono
        QFont f(QFontDatabase::families().contains(QStringLiteral("CaskaydiaCove Nerd Font")) ? QStringLiteral("CaskaydiaCove Nerd Font")
                                                                                               : QStringLiteral("DejaVu Sans Mono"));
        f.setPointSizeF(11);
        f.setStyleHint(QFont::Monospace);
        term->setTerminalFont(f);
        // QTermWidget pinta su fondo «reemplazando» lo de debajo: se le da la misma translucidez que a la ventana y
        // termina 12 px antes del borde inferior para no tapar las esquinas redondeadas
        term->setTerminalOpacity(kOpacity);
        term->setScrollBarPosition(QTermWidget::NoScrollBar);   // como macOS: sin barra fija
        term->setHistorySize(10000);
        term->setKeyboardCursorShape(QTermWidget::KeyboardCursorShape::BlockCursor);
        term->setBlinkingCursor(true);
        term->setMargin(6);
        term->setTerminalSizeHint(false);
        term->setFlowControlEnabled(false);
        if (!workdir.isEmpty()) term->setWorkingDirectory(workdir);
        QStringList env = QProcess::systemEnvironment();
        env << QStringLiteral("TERM=xterm-256color") << QStringLiteral("COLORTERM=truecolor") << QStringLiteral("TERM_PROGRAM=BC-Terminal");
        term->setEnvironment(env);
        applyAppearance();

        auto *lay = new QVBoxLayout(this);
        lay->setContentsMargins(kShadow + 1, kShadow + kTitleH, kShadow + 1, kShadow + kRadius);
        lay->addWidget(term);

        connect(term, &QTermWidget::finished, this, &QWidget::close);
        connect(term, &QTermWidget::titleChanged, this, [this] { update(); });
        // Cambio de aspecto en caliente (Ajustes ▸ Aspecto escribe el archivo de configuración de BC)
        const QString conf = QSettings("BC-OS", "bc-shell").fileName();
        watcher.addPath(QFileInfo(conf).absolutePath());
        if (QFileInfo::exists(conf)) watcher.addPath(conf);
        connect(&watcher, &QFileSystemWatcher::fileChanged, this, [this, conf] { if (!watcher.files().contains(conf)) watcher.addPath(conf); applyAppearance(); });
        connect(&watcher, &QFileSystemWatcher::directoryChanged, this, [this] { applyAppearance(); });
        auto *minute = new QTimer(this); minute->setInterval(60000);
        connect(minute, &QTimer::timeout, this, [this] { applyAppearance(); });   // «Automático» a las 8:00 y 20:00
        minute->start();

        // Atajos de macOS adaptados (⌘ → Ctrl+Mayús para no chocar con la shell)
        auto sc = [this](const QKeySequence &k, auto fn) { auto *s = new QShortcut(k, this); s->setContext(Qt::WindowShortcut); connect(s, &QShortcut::activated, this, fn); };
        sc(QKeySequence(QStringLiteral("Ctrl+Shift+C")), [this] { term->copyClipboard(); });
        sc(QKeySequence(QStringLiteral("Ctrl+Shift+V")), [this] { term->pasteClipboard(); });
        sc(QKeySequence(QStringLiteral("Ctrl+Shift+N")), [] { QProcess::startDetached(QCoreApplication::applicationFilePath(), {}); });
        sc(QKeySequence(QStringLiteral("Ctrl+Shift+W")), [this] { close(); });
        sc(QKeySequence(QStringLiteral("Ctrl+Shift+K")), [this] { term->clear(); });
        sc(QKeySequence(QStringLiteral("Ctrl++")), [this] { term->zoomIn(); });
        sc(QKeySequence(QStringLiteral("Ctrl+=")), [this] { term->zoomIn(); });
        sc(QKeySequence(QStringLiteral("Ctrl+-")), [this] { term->zoomOut(); });

        // 80×24 como el Terminal de macOS
        const QFontMetrics fm(f);
        resize(fm.horizontalAdvance(QLatin1Char('M')) * 80 + 2 * kShadow + 2 + 12 + 14,
               fm.lineSpacing() * 24 + 2 * kShadow + kTitleH + kRadius + 12);
        term->startShellProgram();
        term->setFocus();
    }

    QTermWidget *term = nullptr;

protected:
    void paintEvent(QPaintEvent *) override {
        QPainter p(this);
        p.setRenderHint(QPainter::Antialiasing);
        const QRectF r = QRectF(rect()).adjusted(kShadow, kShadow, -kShadow, -kShadow);
        // Sombra suave en capas (sin desenfoque: barata por software)
        if (!isMaximized() && !isFullScreen()) {
            for (int i = kShadow; i > 0; i -= 2) {
                const qreal a = (isActiveWindow() ? 0.10 : 0.06) * (1.0 - qreal(i) / kShadow);
                p.setPen(Qt::NoPen); p.setBrush(QColor(0, 0, 0, int(255 * a * 0.6)));
                p.drawRoundedRect(r.adjusted(-i, -i + 4, i, i + 4), kRadius + i, kRadius + i);
            }
        }
        QPainterPath win; win.addRoundedRect(r, kRadius, kRadius);
        // Fondo translúcido como el perfil «Básico» con transparencia del Terminal de macOS
        p.fillPath(win, dark ? QColor(30, 30, 30, int(255 * kOpacity)) : QColor(255, 255, 255, int(255 * kOpacity)));
        // Barra de título: un poco más clara/oscura que el contenido y separada por una línea fina
        QPainterPath tb; tb.addRoundedRect(QRectF(r.x(), r.y(), r.width(), kTitleH + kRadius), kRadius, kRadius);
        QPainterPath tbClip; tbClip.addRect(QRectF(r.x(), r.y(), r.width(), kTitleH));
        p.fillPath(tb.intersected(tbClip), dark ? QColor(56, 56, 58, 245) : QColor(236, 236, 236, 250));
        p.setPen(QPen(dark ? QColor(0, 0, 0, 160) : QColor(0, 0, 0, 40), 1));
        p.drawLine(QPointF(r.x(), r.y() + kTitleH - 0.5), QPointF(r.right(), r.y() + kTitleH - 0.5));
        // Borde fino de la ventana
        p.setPen(QPen(dark ? QColor(255, 255, 255, 38) : QColor(0, 0, 0, 46), 1));
        p.setBrush(Qt::NoBrush);
        p.drawRoundedRect(r.adjusted(0.5, 0.5, -0.5, -0.5), kRadius, kRadius);
        // Semáforo (12 px, separación 8, como macOS) con los símbolos al pasar el puntero
        const QColor cols[3] = {QColor("#FF5F57"), QColor("#FEBC2E"), QColor("#28C840")};
        const bool on = isActiveWindow() || hoverLights;
        for (int i = 0; i < 3; ++i) {
            const QRectF c = light(i);
            p.setPen(QPen(on ? cols[i].darker(115) : (dark ? QColor(80, 80, 82) : QColor(200, 200, 200)), 0.5));
            p.setBrush(on ? cols[i] : (dark ? QColor(74, 74, 76) : QColor(208, 208, 208)));
            p.drawEllipse(c);
            if (hoverLights) {
                p.setPen(QPen(QColor(0, 0, 0, 150), 1.2, Qt::SolidLine, Qt::RoundCap));
                const QPointF m = c.center(); const qreal d = 2.6;
                if (i == 0) { p.drawLine(m + QPointF(-d, -d), m + QPointF(d, d)); p.drawLine(m + QPointF(-d, d), m + QPointF(d, -d)); }
                else if (i == 1) p.drawLine(m + QPointF(-d - 0.6, 0), m + QPointF(d + 0.6, 0));
                else { p.setBrush(QColor(0, 0, 0, 150)); p.setPen(Qt::NoPen);
                       p.drawPolygon(QPolygonF({m + QPointF(-d, -d), m + QPointF(d * 0.7, -d), m + QPointF(-d, d * 0.7)}));
                       p.drawPolygon(QPolygonF({m + QPointF(d, d), m + QPointF(-d * 0.7, d), m + QPointF(d, -d * 0.7)})); }
            }
        }
        // Título centrado con el icono de carpeta: «usuario — fish — 80×24»
        QString t = term && !term->title().isEmpty() && term->title() != QLatin1String("QTermWidget") ? term->title()
                    : QStringLiteral("%1 — %2×%3").arg(qEnvironmentVariable("USER", "bc")).arg(term ? term->screenColumnsCount() : 80).arg(term ? term->screenLinesCount() : 24);
        QFont tf(QStringLiteral("Inter")); tf.setPixelSize(13); tf.setWeight(QFont::DemiBold);
        p.setFont(tf);
        const QFontMetrics tm(tf);
        t = tm.elidedText(t, Qt::ElideMiddle, int(r.width() - 160));
        const int iconSz = 16, tw = tm.horizontalAdvance(t) + iconSz + 6;
        const qreal tx = r.center().x() - tw / 2.0, ty = r.y() + kTitleH / 2.0;
        const QIcon folder = QIcon::fromTheme(QStringLiteral("folder"));
        if (!folder.isNull()) folder.paint(&p, QRect(int(tx), int(ty - iconSz / 2.0), iconSz, iconSz));
        p.setPen(isActiveWindow() ? (dark ? QColor(230, 230, 232) : QColor(40, 40, 42)) : (dark ? QColor(140, 140, 144) : QColor(150, 150, 150)));
        p.drawText(QRectF(tx + iconSz + 6, r.y(), tw, kTitleH), Qt::AlignVCenter | Qt::AlignLeft, t);
    }

    void mousePressEvent(QMouseEvent *e) override {
        if (e->button() != Qt::LeftButton) return;
        for (int i = 0; i < 3; ++i) if (light(i).adjusted(-3, -3, 3, 3).contains(e->position())) { lightClicked(i); return; }
        if (const Qt::Edges ed = edgesAt(e->position()); ed && windowHandle()) { windowHandle()->startSystemResize(ed); return; }
        if (titleRect().contains(e->position()) && windowHandle()) windowHandle()->startSystemMove();
    }
    void mouseDoubleClickEvent(QMouseEvent *e) override { if (titleRect().contains(e->position())) toggleZoom(); }
    void mouseMoveEvent(QMouseEvent *e) override {
        const Qt::Edges ed = edgesAt(e->position());
        setCursor((ed == (Qt::LeftEdge | Qt::TopEdge) || ed == (Qt::RightEdge | Qt::BottomEdge)) ? Qt::SizeFDiagCursor
                  : (ed == (Qt::RightEdge | Qt::TopEdge) || ed == (Qt::LeftEdge | Qt::BottomEdge)) ? Qt::SizeBDiagCursor
                  : (ed & (Qt::LeftEdge | Qt::RightEdge)) ? Qt::SizeHorCursor : (ed & (Qt::TopEdge | Qt::BottomEdge)) ? Qt::SizeVerCursor : Qt::ArrowCursor);
        const bool h = QRectF(light(0).topLeft() - QPointF(4, 4), light(2).bottomRight() + QPointF(4, 4)).contains(e->position());
        if (h != hoverLights) { hoverLights = h; update(titleRect().toRect()); }
    }
    void leaveEvent(QEvent *) override { if (hoverLights) { hoverLights = false; update(); } }
    void changeEvent(QEvent *e) override { if (e->type() == QEvent::ActivationChange || e->type() == QEvent::WindowStateChange) update(); QWidget::changeEvent(e); }
    void contextMenuEvent(QContextMenuEvent *e) override {
        QMenu m(this);
        m.addAction(tr("Copiar"), term, &QTermWidget::copyClipboard);
        m.addAction(tr("Pegar"), term, &QTermWidget::pasteClipboard);
        m.addSeparator();
        m.addAction(tr("Limpiar"), term, &QTermWidget::clear);
        m.addAction(tr("Nueva ventana"), [] { QProcess::startDetached(QCoreApplication::applicationFilePath(), {}); });
        m.exec(e->globalPos());
    }

private:
    QRectF frameRect() const { return QRectF(rect()).adjusted(kShadow, kShadow, -kShadow, -kShadow); }
    QRectF titleRect() const { const QRectF r = frameRect(); return QRectF(r.x(), r.y(), r.width(), kTitleH); }
    QRectF light(int i) const { const QRectF r = frameRect(); return QRectF(r.x() + 13 + i * 20, r.y() + (kTitleH - 12) / 2.0, 12, 12); }
    Qt::Edges edgesAt(const QPointF &p) const {
        const QRectF r = frameRect(); Qt::Edges e;
        if (isMaximized() || isFullScreen()) return e;
        if (p.x() >= r.left() - kGrip && p.x() <= r.left() + kGrip) e |= Qt::LeftEdge;
        if (p.x() >= r.right() - kGrip && p.x() <= r.right() + kGrip) e |= Qt::RightEdge;
        if (p.y() >= r.top() - kGrip && p.y() <= r.top() + 3) e |= Qt::TopEdge;
        if (p.y() >= r.bottom() - kGrip && p.y() <= r.bottom() + kGrip) e |= Qt::BottomEdge;
        return e;
    }
    void lightClicked(int i) {
        if (i == 0) close();
        else if (i == 1) { if (!QProcess::startDetached(QStringLiteral("bc-ctl"), {QStringLiteral("minimize")})) showMinimized(); }
        else toggleZoom();
    }
    // Zoom de macOS (botón verde o doble clic en la barra): sway ignora «maximizar» en ventanas flotantes, así que se
    // pide al compositor que la ventana ocupe el área bajo la barra de menús y, otra vez, que vuelva a su sitio
    QRect zoomBack;
    void toggleZoom() {
        const QString pid = QString::number(QCoreApplication::applicationPid());
        if (!qEnvironmentVariableIsEmpty("HYPRLAND_INSTANCE_SIGNATURE")) { QProcess::startDetached("hyprctl", {"dispatch", "fullscreen", "1"}); return; }
        if (qEnvironmentVariableIsEmpty("SWAYSOCK")) { if (isMaximized()) showNormal(); else showMaximized(); return; }
        auto sway = [&](const QString &cmd) { QProcess::startDetached("swaymsg", {QString("[pid=%1] %2").arg(pid, cmd)}); };
        if (zoomBack.isValid()) {
            sway(QString("resize set %1 %2, move absolute position %3 %4").arg(zoomBack.width()).arg(zoomBack.height()).arg(zoomBack.x()).arg(zoomBack.y()));
            zoomBack = QRect();
            return;
        }
        // Posición actual (para volver): del árbol de sway
        QProcess q; q.start("swaymsg", {"-t", "get_tree", "-r"}); q.waitForFinished(1500);
        std::function<bool(const QJsonObject &)> find = [&](const QJsonObject &n) {
            if (n.value("pid").toInt() == QCoreApplication::applicationPid()) {
                const QJsonObject r = n.value("rect").toObject();
                zoomBack = QRect(r.value("x").toInt(), r.value("y").toInt(), r.value("width").toInt(), r.value("height").toInt());
                return true;
            }
            for (const char *k : {"nodes", "floating_nodes"})
                for (const QJsonValue &c : n.value(k).toArray()) if (find(c.toObject())) return true;
            return false;
        };
        find(QJsonDocument::fromJson(q.readAllStandardOutput()).object());
        if (!zoomBack.isValid()) zoomBack = QRect(geometry());
        const QRect sg = screen() ? screen()->geometry() : QRect(0, 0, 1280, 800);
        const int bar = qRound(30 * qBound(0.7, sg.height() / 1080.0, 2.0));
        sway(QString("resize set %1 %2, move absolute position %3 %4").arg(sg.width() + 2 * kShadow).arg(sg.height() - bar + 2 * kShadow)
                 .arg(sg.x() - kShadow).arg(sg.y() + bar - kShadow));
    }
    void applyAppearance() {
        const bool d = systemDark();
        if (d == dark && schemeSet) return;
        dark = d; schemeSet = true;
        if (term) term->setColorScheme(dark ? QStringLiteral("BC-Oscuro") : QStringLiteral("BC-Claro"));
        update();
    }

    bool dark = true, schemeSet = false, hoverLights = false;
    QFileSystemWatcher watcher;
};

int main(int argc, char **argv) {
    QApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("bc-terminal"));
    app.setDesktopFileName(QStringLiteral("bc-terminal"));   // app_id en sway: «bc-…» = sin marco del compositor
    if (QIcon::themeName().isEmpty()) QIcon::setThemeName(QStringLiteral("MacOS-Like-Dark"));
    QString dir, run;
    const QStringList a = app.arguments();
    for (int i = 1; i < a.size(); ++i) {
        if (a[i] == QLatin1String("--working-directory") && i + 1 < a.size()) dir = a[++i];
        // Aviso «Actualizaciones disponibles»: la Terminal se abre con la actualización completa ya escrita y en
        // marcha (pacman -Syyu desde el repositorio firmado de BC y Arch); solo hay que poner la contraseña
        else if (a[i] == QLatin1String("--actualizar")) run = QStringLiteral("sudo bc-actualizar");
        else if (QFileInfo(a[i]).isDir()) dir = a[i];
    }
    if (dir.isEmpty()) dir = QDir::homePath();
    TerminalWindow w(dir);
    w.show();
    if (!run.isEmpty()) QTimer::singleShot(400, &w, [&w, run] { w.term->sendText(run + QLatin1Char('\r')); });
    // Pruebas: BC_TERMINAL_SHOT=<png> guarda una captura a los 2,5 s y sale
    if (const QString shot = qEnvironmentVariable("BC_TERMINAL_SHOT"); !shot.isEmpty())
        QTimer::singleShot(2500, &app, [&w, shot] { w.grab().save(shot); QCoreApplication::exit(0); });
    return app.exec();
}
