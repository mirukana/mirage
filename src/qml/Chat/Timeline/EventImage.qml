import QtQuick 2.12
import "../../Base"
import "../../utils.js" as Utils

HImage {
    id: image
    horizontalAlignment: Image.AlignLeft
    sourceSize.width: theme.chat.message.thumbnailWidth  // FIXME


    // source = thumbnail, fullSource = full original image
    property url fullSource: source


    TapHandler {
        onTapped: if (! image.animated) Qt.openUrlExternally(fullSource)
        onDoubleTapped: Qt.openUrlExternally(fullSource)
    }

    HoverHandler {
        id: hover
        onHoveredChanged:
            eventDelegate.hoveredMediaTypeUrl =
                hovered ? [EventDelegate.Media.Image, fullSource] : []
    }
}
