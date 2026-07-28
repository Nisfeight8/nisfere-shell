import QtQuick
import qs.core
import qs.services

// Visual content of the wallpaper lyrics overlay — a vertical ticker
// where the current line settles a bit above center, upcoming lines
// wait below (dim), and past lines have already scrolled up and out.
// ListView's own currentIndex-follow animation gives the "comes from
// top, moves down as the song progresses" feel without needing custom
// frame-by-frame interpolation — MPRIS position updates aren't frequent
// enough for that to look smoother anyway.
Item {
    id: root
    anchors.fill: parent

    // Soft cava-reactive glow behind the lyrics — reuses the same
    // AudioVisualizer.bass data Media.qml's own glow already consumes,
    // just a subtler, larger version suited to sitting behind text on
    // the desktop rather than behind album art in a drawer.
    Rectangle {
        anchors.centerIn: parent
        width: 320 + AudioVisualizer.bass
        height: width
        radius: width / 2
        color: Theme.selected
        opacity: 0.06 + Math.min(AudioVisualizer.bass / 4000, 0.10)
        z: -1

        Behavior on width {
            Anim {
                type: Anim.FastEffects
            }
        }
        Behavior on opacity {
            Anim {
                type: Anim.FastEffects
            }
        }
    }

    ListView {
        id: lyricsList
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.6, 900)
        height: parent.height * 0.5
        visible: LyricsService.hasLyrics
        model: LyricsService.lines
        currentIndex: LyricsService.currentIndex
        interactive: false
        clip: true
        spacing: 20

        highlightFollowsCurrentItem: true
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: height * 0.35
        preferredHighlightEnd: height * 0.35
        highlightMoveDuration: 450

        delegate: Text {
            id: lineText
            readonly property bool isCurrent: index === lyricsList.currentIndex

            width: lyricsList.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: modelData.text
            font.family: Theme.fontName
            font.pixelSize: isCurrent ? 32 : 22
            font.bold: isCurrent
            color: "white"
            opacity: isCurrent ? 1.0 : 0.3

            Behavior on font.pixelSize {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }
}
