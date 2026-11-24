#include "layerhelper.h"
#include <QScreen>
#include <QVariant>
#ifdef BC_HAVE_LAYERSHELL
#include <LayerShellQt/Window>
#endif

bool LayerHelper::supported() const {
#ifdef BC_HAVE_LAYERSHELL
    return qEnvironmentVariable("QT_QPA_PLATFORM") != "offscreen";
#else
    return false;
#endif
}

void LayerHelper::configure(QWindow *window, const QVariantMap &o) {
#ifdef BC_HAVE_LAYERSHELL
    if (!window || !supported()) return;
    using W = LayerShellQt::Window;
    W *w = W::get(window);
    if (!w) return;
    // Solo lo que ha cambiado: cada petición de layer-shell hace que el compositor reorganice TODAS las capas de la
    // pantalla y les mande un «configure» (Hyprland), y Qt redibuja cada superficie entera al recibirlo. Antes, abrir
    // Spotlight o un menú (cambia solo el teclado de la capa de menús) reenviaba todo y redibujaba el escritorio a
    // pantalla completa, la barra y el Dock justo al empezar la animación.
    const QVariantMap prev = window->property("_bcLayerCfg").toMap();
    window->setProperty("_bcLayerCfg", o);
    const bool first = prev.isEmpty();
    auto changed = [&](const char *k) { return first || prev.value(QLatin1String(k)) != o.value(QLatin1String(k)); };
    if (changed("layer")) {
        const QString layer = o.value("layer", "top").toString();
        w->setLayer(layer == "background" ? W::LayerBackground : layer == "bottom" ? W::LayerBottom
                    : layer == "overlay" ? W::LayerOverlay : W::LayerTop);
    }
    if (changed("anchors")) {
        W::Anchors a;
        for (const QVariant &v : o.value("anchors").toList()) {
            const QString s = v.toString();
            if (s == "top") a |= W::AnchorTop;
            else if (s == "bottom") a |= W::AnchorBottom;
            else if (s == "left") a |= W::AnchorLeft;
            else if (s == "right") a |= W::AnchorRight;
        }
        w->setAnchors(a);
    }
    if (changed("exclusive")) w->setExclusiveZone(o.value("exclusive", 0).toInt());
    if (changed("margins")) {
        const QVariantList m = o.value("margins").toList();
        if (m.size() == 4) w->setMargins(QMargins(m[3].toInt(), m[0].toInt(), m[1].toInt(), m[2].toInt()));
    }
    if (changed("keyboard")) {
        const QString kb = o.value("keyboard", "none").toString();
        w->setKeyboardInteractivity(kb == "exclusive" ? W::KeyboardInteractivityExclusive
                                    : kb == "ondemand" ? W::KeyboardInteractivityOnDemand : W::KeyboardInteractivityNone);
    }
    if (changed("scope")) w->setScope(o.value("scope", "bc-shell").toString());
    // Multimonitor: cada superficie en SU pantalla (la de la QWindow), no en la que el compositor tenga activa.
    // Sin esto, la barra y el Dock de la segunda pantalla salían apilados en la primera.
    // (propiedades de layer-shell-qt ≥ 6.6; en versiones anteriores no existen y no hacen nada)
    if (first) w->setProperty("wantsToBeOnActiveScreen", false);
    if (window->screen() && w->property("screen").value<QScreen *>() != window->screen()) w->setProperty("screen", QVariant::fromValue(window->screen()));
    if (changed("width") || changed("height")) w->setDesiredSize(QSize(o.value("width", 0).toInt(), o.value("height", 0).toInt()));
#else
    Q_UNUSED(window); Q_UNUSED(o);
#endif
}
