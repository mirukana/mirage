import QtQuick 2.12
import "../../Base"
import "../../utils.js" as Utils

HImage {
    id: image
    horizontalAlignment: Image.AlignLeft
    sourceSize.width: theme.chat.message.thumbnailWidth  // FIXME
    source: animated ? openUrl : loader.previewUrl
    animated: loader.singleMediaInfo.media_mime === "image/gif" ||
              Utils.urlExtension(loader.mediaUrl) === "gif"


    property EventMediaLoader loader
    readonly property url openUrl: loader.mediaUrl || loader.previewUrl


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

    EventImageTextBubble {
        anchors.left: parent.left
        anchors.top: parent.top
        text: loader.showSender
        textFormat: Text.StyledText
    }

    EventImageTextBubble {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        text: loader.showDate
    }
}
