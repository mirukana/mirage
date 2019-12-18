import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtAV 1.7
import "../../../Base"
import "../../../Base/MediaPlayer"

AudioPlayer {
    id: audio

    HoverHandler {
        onHoveredChanged:
            eventDelegate.hoveredMediaTypeUrl =
                hovered ? [EventDelegate.Media.Audio, audio.source] : []
    }
}
