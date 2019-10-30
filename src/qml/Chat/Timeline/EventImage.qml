import QtQuick 2.12
import "../../Base"
import "../../utils.js" as Utils

HImage {
    id: image
    horizontalAlignment: Image.AlignLeft
    sourceSize.width: theme.chat.message.thumbnailWidth  // FIXME
    source: animated ? openUrl : thumbnailUrl


    property url thumbnailUrl
    property url fullImageUrl

    readonly property url openUrl: fullImageUrl || thumbnailUrl


    TapHandler {
        onTapped: if (! image.animated) Qt.openUrlExternally(openUrl)
        onDoubleTapped: Qt.openUrlExternally(openUrl)
    }

    HoverHandler {
        id: hover
        onHoveredChanged:
            eventDelegate.hoveredMediaTypeUrl =
                hovered ? [EventDelegate.Media.Image, openUrl] : []
    }
}
