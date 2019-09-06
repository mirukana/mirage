import QtQuick 2.12
import "../../Base"

HImage {
    id: image
    x: eventContent.spacing
    sourceSize.width: maxDimension
    sourceSize.height: maxDimension
    width: Math.min(
        mainColumn.width - eventContent.spacing * 2,
        implicitWidth,
        maxDimension,
    )

    property int maxDimension: window.settings.messageImageMaxThumbnailSize

    TapHandler {
        onTapped: Qt.openUrlExternally(image.source)
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
