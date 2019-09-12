import QtQuick 2.12
import "../../Base"

HImage {
    id: image
    x: eventContent.spacing
    sourceSize.width: theme.chat.message.thumbnailWidth
    sourceSize.height: theme.chat.message.thumbnailWidth
    width: Math.min(
        mainColumn.width - eventContent.spacing * 2,
        implicitWidth,
        theme.chat.message.thumbnailWidth,
    )

    TapHandler {
        onTapped: if (! image.animated) Qt.openUrlExternally(image.source)
        onDoubleTapped: Qt.openUrlExternally(image.source)
    }

    HoverHandler {
        id: hover
        onHoveredChanged:
            eventContent.hoveredImage = hovered ? image.source : ""
    }

    MouseArea {
        anchors.fill: image
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
    }
}
