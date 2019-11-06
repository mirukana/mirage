import QtQuick 2.12
import "../../Base"
import "../../utils.js" as Utils

HMxcImage {
    id: image
    width: fitSize.width
    height: fitSize.height
    horizontalAlignment: Image.AlignLeft
    animated: loader.singleMediaInfo.media_mime === "image/gif" ||
              Utils.urlExtension(loader.mediaUrl) === "gif"
    clientUserId: chatPage.userId
    thumbnail: ! animated && loader.thumbnailMxc
    mxc: thumbnail ?
         (loader.thumbnailMxc || loader.mediaUrl) :
         (loader.mediaUrl || loader.thumbnailMxc)
    cryptDict: thumbnail && loader.thumbnailMxc ?
               loader.singleMediaInfo.thumbnail_crypt_dict :
               loader.singleMediaInfo.media_crypt_dict


    property EventMediaLoader loader
    readonly property bool isEncrypted: ! Utils.isEmptyObject(cryptDict)
    readonly property string openUrl: isEncrypted ? cachedPath : image.httpUrl

    readonly property size fitSize: Utils.fitSize(
        // Minimum display size
        192,
        192,

        // Real size
        loader.singleMediaInfo.thumbnail_width ||
        loader.singleMediaInfo.media_width ||
        implicitWidth ||
        800,

        loader.singleMediaInfo.thumbnail_height ||
        loader.singleMediaInfo.media_height ||
        implicitHeight ||
        600,

        // Maximum display size
        Math.min(eventList.height / 3, eventContent.messageBodyWidth),
        eventList.height / 3,
    )


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
