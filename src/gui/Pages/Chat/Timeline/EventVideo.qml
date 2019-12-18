import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtAV 1.7
import "../../../Base"
import "../../../Base/MediaPlayer"

VideoPlayer {
    id: video

    onHoveredChanged:
        eventDelegate.hoveredMediaTypeUrl =
            hovered ? [EventDelegate.Media.Video, video.source] : []
}
