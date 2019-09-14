import QtQuick 2.12
import "../../Base"

HImage {
    id: image
    sourceSize.width: theme.chat.message.thumbnailWidth
    sourceSize.height: theme.chat.message.thumbnailWidth
    width: Math.min(
        mainColumn.width - eventContent.spacing * 2,
        implicitWidth,
        theme.chat.message.thumbnailWidth,
    )


    // source = thumbnail, fullSource = full original image
    property url fullSource: source


    TapHandler {
        onTapped: if (! image.animated) Qt.openUrlExternally(image.fullSource)
        onDoubleTapped: Qt.openUrlExternally(image.fullSource)
    }

    HoverHandler {
        id: hover
        onHoveredChanged:
            eventContent.hoveredImage = hovered ? image.fullSource : ""
    }

    MouseArea {
        anchors.fill: image
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
    }
}
