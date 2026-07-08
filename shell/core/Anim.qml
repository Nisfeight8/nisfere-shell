import QtQuick

NumberAnimation {
    enum Type {
        StandardSmall = 0,
        Standard,
        StandardLarge,
        StandardExtraLarge,
        EmphasizedSmall,
        Emphasized,
        EmphasizedLarge,
        EmphasizedExtraLarge,
        FastSpatial,
        DefaultSpatial,
        SlowSpatial,
        FastEffects,
        DefaultEffects,
        SlowEffects
    }

    property int type: Anim.DefaultSpatial

    // ── Durations (ms) — Material Design 3 motion scale ──────────────────
    duration: {
        switch (type) {
        case Anim.StandardSmall:
            return 100;
        case Anim.Standard:
            return 200;
        case Anim.StandardLarge:
            return 400;
        case Anim.StandardExtraLarge:
            return 600;
        case Anim.EmphasizedSmall:
            return 100;
        case Anim.Emphasized:
            return 300;
        case Anim.EmphasizedLarge:
            return 400;
        case Anim.EmphasizedExtraLarge:
            return 600;
        case Anim.FastSpatial:
            return 200;
        case Anim.DefaultSpatial:
            return 500;
        case Anim.SlowSpatial:
            return 700;
        case Anim.FastEffects:
            return 150;
        case Anim.DefaultEffects:
            return 200;
        case Anim.SlowEffects:
            return 500;
        default:
            return 200;
        }
    }

    // ── Easings — custom cubic beziers, no Tokens needed ─────────────────
    //
    //  Standard*    cubic-bezier(0.20, 0.00, 0.00, 1.00)  — M3 standard decelerate
    //  Emphasized*  cubic-bezier(0.05, 0.70, 0.10, 1.00)  — M3 emphasized decelerate
    //  *Spatial     cubic-bezier(0.34, 1.56, 0.64, 1.00)  — expressive spring (slight overshoot)
    //  *Effects     cubic-bezier(0.20, 0.00, 0.00, 1.00)  — smooth, same as standard

    easing.type: Easing.OutCubic

    easing.bezierCurve: {
        switch (type) {
        case Anim.FastSpatial:
        case Anim.DefaultSpatial:
        case Anim.SlowSpatial:
            return [0.34, 1.56, 0.64, 1.0, 1.0, 1.0];
        case Anim.EmphasizedSmall:
        case Anim.Emphasized:
        case Anim.EmphasizedLarge:
        case Anim.EmphasizedExtraLarge:
            return [0.05, 0.70, 0.10, 1.0, 1.0, 1.0];

        // Standard* + Effects* — ίδια καμπύλη, διαφορετική διάρκεια
        default:
            return [0.20, 0.00, 0.00, 1.0, 1.0, 1.0];
        }
    }
}
