import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtAV 1.7
import "../../Base"
import "../../Base/MediaPlayer"
import "../../utils.js" as Utils

AudioPlayer {
    id: audio
    width: Math.min(
        mainColumn.width - eventContent.spacing * 2,
        theme.chat.message.audioWidth,
    )

    HoverHandler {
        onHoveredChanged:
            eventDelegate.hoveredMediaTypeUrl =
                hovered ? [EventDelegate.Media.Audio, audio.source] : []
    }
}
