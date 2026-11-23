#include "geniemesh.h"
#include <QQuickWindow>
#include <QSGGeometryNode>
#include <QSGOpacityNode>
#include <QSGTexture>
#include <QSGTextureMaterial>
#include <QUrl>
#include <QtMath>

static inline qreal clamp01(qreal x) { return x < 0 ? 0 : (x > 1 ? 1 : x); }
static inline qreal smoothstep(qreal t) { t = clamp01(t); return t * t * (3 - 2 * t); }
static constexpr int kRows = 96;   // tiras: curva suave sin escalones, coste despreciable en la GPU

GenieMesh::GenieMesh(QQuickItem *parent) : QQuickItem(parent) { setFlag(ItemHasContents, true); }

void GenieMesh::setSource(const QString &s) {
    if (s == m_source) return;
    m_source = s;
    if (s.isEmpty()) m_img = QImage();
    else {
        const QUrl u(s);
        m_img = QImage(u.isLocalFile() ? u.toLocalFile() : (s.startsWith("qrc:") ? s.mid(3) : s));
    }
    m_newImage = true;
    update();
    emit changed();
}

// Misma geometría que GenieItem: fase 1 (p < 0,42) el embudo se curva hacia el icono; fase 2 la ventana se desliza
// por él. Cada fila v de la ventana (0 arriba, 1 abajo) cae en la posición t del embudo; las que ya han entrado en el
// icono (t ≥ 1) se pliegan sobre su borde superior.
QVector<float> GenieMesh::strip(const QRectF &from, const QPointF &target, qreal icon, qreal p, int rows) {
    QVector<float> out;
    out.reserve((rows + 1) * 8);
    const qreal W = from.width(), H = from.height(), y0 = from.y();
    const qreal y1 = target.y() - icon / 2;
    const qreal dist = qMax<qreal>(1, y1 - y0);
    const qreal bend = clamp01(p / 0.42);
    const qreal slide = qPow(clamp01((p - 0.3) / 0.7), 1.35);
    const qreal h = H / dist;
    const qreal cx0 = from.x() + W / 2;
    for (int i = 0; i <= rows; ++i) {
        const qreal v = qreal(i) / rows;
        const qreal t = qMin<qreal>(1, slide * (1 + h) + v * h);
        const qreal hw = W / 2 + (icon / 2 - W / 2) * bend * smoothstep(t);
        const qreal cx = cx0 + (target.x() - cx0) * bend * smoothstep(t);
        const float y = float(y0 + t * dist);
        out << float(cx - hw) << y << 0.f << float(v) << float(cx + hw) << y << 1.f << float(v);
    }
    return out;
}

QSGNode *GenieMesh::updatePaintNode(QSGNode *old, UpdatePaintNodeData *) {
    auto *root = static_cast<QSGOpacityNode *>(old);
    if (m_img.isNull() || m_from.width() < 2 || m_from.height() < 2 || m_p >= 0.999 || !window()) {
        delete root;
        return nullptr;
    }
    QSGGeometryNode *node;
    if (!root) {
        root = new QSGOpacityNode;
        node = new QSGGeometryNode;
        auto *g = new QSGGeometry(QSGGeometry::defaultAttributes_TexturedPoint2D(), 2 * (kRows + 1));
        g->setDrawingMode(QSGGeometry::DrawTriangleStrip);
        node->setGeometry(g);
        node->setFlag(QSGNode::OwnsGeometry);
        auto *m = new QSGTextureMaterial;
        m->setFiltering(QSGTexture::Linear);
        m->setMipmapFiltering(QSGTexture::None);
        node->setMaterial(m);
        node->setFlag(QSGNode::OwnsMaterial);
        root->appendChildNode(node);
        m_newImage = true;
    } else node = static_cast<QSGGeometryNode *>(root->firstChild());
    auto *mat = static_cast<QSGTextureMaterial *>(node->material());
    if (m_newImage) {
        delete mat->texture();
        mat->setTexture(window()->createTextureFromImage(m_img));
        m_newImage = false;
        node->markDirty(QSGNode::DirtyMaterial);
    }
    const QVector<float> s = strip(m_from, m_target, m_icon, m_p, kRows);
    auto *v = node->geometry()->vertexDataAsTexturedPoint2D();
    for (int i = 0; i < 2 * (kRows + 1); ++i) v[i].set(s[i * 4], s[i * 4 + 1], s[i * 4 + 2], s[i * 4 + 3]);
    node->markDirty(QSGNode::DirtyGeometry);
    root->setOpacity(m_p > 0.96 ? clamp01((1 - m_p) * 25) : 1.0);
    return root;
}
