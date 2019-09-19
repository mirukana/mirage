import QtQuick 2.12
import "../../Base"
import "../../utils.js" as Utils

HImage {
    id: image
    sourceSize.width: theme.chat.message.thumbnailWidth
    sourceSize.height: theme.chat.message.thumbnailWidth
    width: fitSize.width
    height: fitSize.height

    // Leaving PreserveAspectFit creates a binding loop, and is uneeded
    // since we calculate ourself the right size.
    fillMode: Image.Pad


    // source = thumbnail, fullSource = full original image
    property url fullSource: source

    readonly property size fitSize: Utils.fitSize(
        implicitWidth, implicitHeight, theme.chat.message.thumbnailWidth,
    )


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
