import QtQuick
import qs.core

// Generic small icon-only button — covers every square/rounded icon
// button pattern in the shell: hover-tint (refresh), toggle/solid-active
// (DND), always-bordered (clear-all), hover-solid (popup close), and
// fixed icon color (destructive actions that stay red regardless of state).
Rectangle {
    id: root

    property string icon: ""
    property int size: 32
    property int iconSize: 16
    property string tooltipText: ""
    property bool enabled: true

    radius: Theme.radius   // dynamic from Theme — override per-instance when a smaller radius is needed

    // ── State ────────────────────────────────────────────────────
    property bool isActive: false   // persistent toggle state (e.g. DND on)
    property bool activeSolid: false   // true: solid activeColor fill when active
    // false: tinted activeColor fill when active
    property bool hoverSolid: false   // true: solid hoverColor fill on hover
    // (instead of the default tint)
    property bool alwaysBorder: false  // true: static Theme.borderColor border,

    // ignoring hover/active (e.g. clear-all button)

    // ── Colors ───────────────────────────────────────────────────
    property color borderColor: Theme.foreground
    property color normalColor: "transparent"
    property color hoverColor: Theme.selected
    property color activeColor: Theme.selected
    property color contrastColor: Theme.background   // icon color on solid fills
    property color fixedIconColor: "transparent"      // alpha>0 = force this icon color always

    // ── Idle appearance ──────────────────────────────────────────
    property real idleOpacity: 0.6   // icon opacity when neither hovered nor active
    property bool dimWhenIdle: true  // false = icon always full opacity (e.g. destructive actions)
    property bool spinning: false // true = icon rotates continuously (e.g. loading state)
    property bool flat: false // true = no background/border ever — icon only (e.g. media controls)

    readonly property bool pressed: tap.pressed

    readonly property bool isHovered: hover.hovered

    signal tapped

    width: size
    height: size

    color: {
        if (flat)
            return "transparent";
        if (isActive && activeSolid)
            return activeColor;
        if (isActive)
            return Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.18);
        if (isHovered && hoverSolid)
            return hoverColor;
        if (isHovered)
            return Qt.rgba(hoverColor.r, hoverColor.g, hoverColor.b, 0.15);
        return normalColor;
    }
    border.width: flat ? 0 : alwaysBorder ? Theme.widgetBorderWidth : ((isActive || isHovered) ? 1 : 0)
    border.color: alwaysBorder ? borderColor : (isActive ? activeColor : hoverColor)

    Behavior on color {
        AnimColor {
            type: Anim.FastEffects
        }
    }
    Behavior on border.color {
        AnimColor {
            type: Anim.FastEffects
        }
    }
    Behavior on border.width {
        Anim {
            type: Anim.FastEffects
        }
    }

    LucideIcon {
        id: iconItem
        anchors.centerIn: parent
        icon: root.icon
        size: root.iconSize

        color: {
            // Solid-fill states need a contrasting icon color, so they
            // take priority over fixedIconColor (which is for the idle state).
            if (root.isActive && root.activeSolid)
                return root.contrastColor;
            if (root.isHovered && root.hoverSolid)
                return root.contrastColor;
            if (root.fixedIconColor.a > 0)
                return root.fixedIconColor;
            if (root.isActive)
                return root.activeColor;
            if (root.isHovered)
                return root.hoverColor;
            if (root.borderColor != Theme.borderColor)
                return root.borderColor;
            return Theme.foreground;
        }
        opacity: {
            if (root.spinning)
                return 0.35;
            if (!root.dimWhenIdle)
                return 1.0;
            return (root.isActive || root.isHovered) ? 1.0 : root.idleOpacity;
        }

        Behavior on color {
            AnimColor {
                type: Anim.FastEffects
            }
        }
        Behavior on opacity {
            Anim {
                type: Anim.FastEffects
            }
        }

        RotationAnimator on rotation {
            from: 0
            to: 360
            duration: 900
            loops: Animation.Infinite
            running: root.spinning
        }
    }

    HoverHandler {
        id: hover
        // Was missing — without this, hover kept firing (and driving
        // every color/opacity computation above) even while disabled,
        // so a "disabled" button still visually reacted to hover, just
        // without responding to taps. Only cursorShape depended on
        // `enabled` before; now the handler itself does too.
        enabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
    TapHandler {
        id: tap
        enabled: root.enabled
        onTapped: root.tapped()
    }
    StyledToolTip {
        visible: root.isHovered && root.tooltipText !== ""
        text: root.tooltipText
    }
}
