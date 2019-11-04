import QtQuick 2.12
import "../../Base"
import "../../utils.js" as Utils

HMxcImage {
    id: image
    horizontalAlignment: Image.AlignLeft
    sourceSize.width: 640  // FIXME
    sourceSize.height: 480  // FIXME
    animated: loader.singleMediaInfo.media_mime === "image/gif" ||
              Utils.urlExtension(loader.mediaUrl) === "gif"
    clientUserId: chatPage.userId
    mxc: animated ? openUrl : (loader.thumbnailMxc || loader.mediaUrl)


    property EventMediaLoader loader
    readonly property url openUrl: loader.mediaUrl || loader.thumbnailMxc


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
