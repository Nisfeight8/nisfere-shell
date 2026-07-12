import QtQuick

// Pure geometry math for BaseDrawer — no visuals, no state beyond inputs.
// Given edge/cornerMode/content size/animation offset, computes everything
// needed to position and size the drawer window and its content margins.
QtObject {
    id: root

    // ── Inputs ───────────────────────────────────────────────────
    property int edge: Qt.LeftEdge
    property bool cornerMode: false
    property int cornerSecondaryEdge: Qt.TopEdge
    property real edgeMargin: 10

    property real minPanelWidth: 0
    property real minPanelHeight: 0
    property real maxPanelWidth: -1   // -1 = no limit
    property real maxPanelHeight: -1

    property real contentWidth: 0   // implicit width of loaded content
    property real contentHeight: 0   // implicit height of loaded content

    property real offset: 1.0  // 0 = fully open, 1 = fully closed (off-screen)
    property real screenOffset: 0

    // ── Derived: which edge(s) this drawer sits against ───────────
    readonly property bool isHorizontal: edge === Qt.LeftEdge || edge === Qt.RightEdge

    readonly property real _mTop: (edge === Qt.TopEdge || (cornerMode && cornerSecondaryEdge === Qt.TopEdge)) ? 10 : 30
    readonly property real _mBottom: (edge === Qt.BottomEdge || (cornerMode && cornerSecondaryEdge === Qt.BottomEdge)) ? 0 : 30
    readonly property real _mLeft: (edge === Qt.LeftEdge || (cornerMode && cornerSecondaryEdge === Qt.LeftEdge)) ? 0 : 30
    readonly property real _mRight: (edge === Qt.RightEdge || (cornerMode && cornerSecondaryEdge === Qt.RightEdge)) ? 0 : 30

    // ── Panel size (content + directional margins, clamped) ───────
    readonly property real panelWidth: {
        const w = Math.max(minPanelWidth, contentWidth + _mLeft + _mRight);
        return maxPanelWidth > 0 ? Math.min(w, maxPanelWidth) : w;
    }
    readonly property real panelHeight: {
        const h = Math.max(minPanelHeight, contentHeight + _mTop + _mBottom);
        return maxPanelHeight > 0 ? Math.min(h, maxPanelHeight) : h;
    }

    // ── Which window edges to anchor to ────────────────────────────
    readonly property bool anchorTop: edge === Qt.TopEdge || (cornerMode && cornerSecondaryEdge === Qt.TopEdge)
    readonly property bool anchorBottom: edge === Qt.BottomEdge || (cornerMode && cornerSecondaryEdge === Qt.BottomEdge)
    readonly property bool anchorLeft: edge === Qt.LeftEdge || (cornerMode && cornerSecondaryEdge === Qt.LeftEdge)
    readonly property bool anchorRight: edge === Qt.RightEdge || (cornerMode && cornerSecondaryEdge === Qt.RightEdge)

    // ── Slide-in/out margins driven by `offset` ────────────────────
    readonly property real marginTop: anchorTop ? (screenOffset * (1 - offset)) - (panelHeight * offset) : 0
    readonly property real marginBottom: anchorBottom ? (screenOffset * (1 - offset)) - (panelHeight * offset) : 0
    readonly property real marginLeft: anchorLeft ? (screenOffset * (1 - offset)) - (panelWidth * offset) : 0
    readonly property real marginRight: anchorRight ? (screenOffset * (1 - offset)) - (panelWidth * offset) : 0

    // ── Full window size (panel + the edge gap reserved by edgeMargin) ──
    readonly property real windowWidth: panelWidth + (isHorizontal ? edgeMargin : 0)
    readonly property real windowHeight: panelHeight + (isHorizontal ? 0 : edgeMargin)
}
