import QtQuick
import QtQuick.Layouts
import qs.core

Item {
    id: root

    // result: { id, title, subtitle, icon, thumbnail?, actions?, swatches?, confirmed? }
    //   thumbnail: optional image path — when present, replaces the
    //              LucideIcon with a small preview image (e.g. a
    //              wallpaper thumbnail, or an app icon path from
    //              DesktopEntryService.resolveIconPath). No corner
    //              masking here — square corners are fine at this
    //              size/context, unlike the wallpaper grid/list cards.
    required property var result
    property bool isSelected: false
    readonly property bool isHovered: rowHover.hovered
    readonly property var actions: root.result.actions || []
    readonly property var swatches: root.result.swatches || []
    readonly property bool hasThumbnail: !!root.result.thumbnail

    // Not every `thumbnail` is the same shape: wallpaper thumbnails are
    // bare filesystem paths (need "file://" added), but
    // DesktopEntryService.resolveIconPath() (used for app icons) can
    // already return a full URL — either an "image://icon/..." theme
    // lookup or an already-absolute path Qt resolves fine on its own.
    // Blindly prepending "file://" to an already-schemed string
    // produces a malformed URL like "file://image://icon/...". Only
    // add it when there's no scheme there yet.
    readonly property string _thumbnailSource: {
        if (!root.hasThumbnail)
            return "";
        const t = root.result.thumbnail;
        return t.indexOf("://") !== -1 ? t : "file://" + t;
    }

    signal activated

    width: ListView.view ? ListView.view.width : implicitWidth
    height: 56

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.selected
        opacity: root.isSelected ? 0.18 : (root.isHovered ? 0.08 : 0)
        Behavior on opacity {
            Anim {
                type: Anim.FastEffects
            }
        }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 14
            rightMargin: 14
        }
        spacing: 12

        // Everything that should activate the row on tap lives inside
        // THIS Item — the actions Row below is a separate sibling with
        // its own bounds, so there's no spatial overlap between "tap
        // to activate" and "tap an action button" regardless of how
        // IconButton handles its own clicks internally. Previously the
        // row-level TapHandler covered the whole row including the
        // actions area, which could fire alongside (or instead of) an
        // action's own tap — e.g. clicking a delete "x" triggering the
        // row's activated() (copy/launch/etc.) instead of just deleting.
        Item {
            id: activatableArea
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                anchors.fill: parent
                spacing: 12

                LucideIcon {
                    visible: !root.hasThumbnail
                    icon: root.result.icon || "circle"
                    size: 20
                    color: root.isSelected ? Theme.selected : Theme.foreground
                    opacity: root.isSelected ? 1.0 : 0.75
                }

                // ── Thumbnail preview (wallpapers, app icons, etc.) ──
                Item {
                    visible: root.hasThumbnail
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40

                    Image {
                        anchors.fill: parent
                        source: root._thumbnailSource
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        sourceSize.width: 40 * 2
                        sourceSize.height: 40 * 2
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: root.result.title
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 14
                        font.bold: root.isSelected
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: !!root.result.subtitle
                        text: root.result.subtitle || ""
                        color: Theme.foreground
                        font.family: Theme.fontName
                        font.pixelSize: 11
                        opacity: 0.45
                        elide: Text.ElideRight
                    }
                }

                Row {
                    visible: root.swatches.length > 0
                    spacing: 4
                    Repeater {
                        model: root.swatches
                        delegate: Rectangle {
                            required property var modelData
                            width: 10
                            height: 10
                            radius: 5
                            color: modelData
                            border.width: 1
                            border.color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.4)
                        }
                    }
                }

                Text {
                    visible: !!root.result.confirmed
                    text: "✓"
                    color: Theme.selected
                    font.pixelSize: 16
                    font.bold: true
                }
            }

            HoverHandler {
                id: rowHover
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
                onTapped: root.activated()
            }
        }

        Row {
            visible: root.actions.length > 0
            spacing: 4
            Repeater {
                model: root.actions
                delegate: IconButton {
                    required property var modelData
                    size: 28
                    iconSize: 14
                    icon: modelData.icon
                    normalColor: "transparent"
                    hoverColor: Theme.selected
                    onTapped: modelData.trigger()
                }
            }
        }
    }
}
