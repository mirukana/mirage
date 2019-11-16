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
    thumbnail: ! animated && loader.thumbnailMxc
    mxc: thumbnail ?
         (loader.thumbnailMxc || loader.mediaUrl) :
         (loader.mediaUrl || loader.thumbnailMxc)
    cryptDict: thumbnail && loader.thumbnailMxc ?
               loader.singleMediaInfo.thumbnail_crypt_dict :
               loader.singleMediaInfo.media_crypt_dict


    property EventMediaLoader loader
    readonly property bool isEncrypted: ! Utils.isEmptyObject(cryptDict)

    readonly property real maxHeight:
        theme.chat.message.thumbnailMaxHeightRatio

    readonly property size fitSize: Utils.fitSize(
        // Minimum display size
        theme.chat.message.thumbnailMinSize.width,
        theme.chat.message.thumbnailMinSize.height,

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
        Math.min(eventList.height * maxHeight, eventContent.messageBodyWidth),
        eventList.height * maxHeight,
    )


    function getOpenUrl(callback) {
        if (image.isEncrypted) {
            callback(image.cachedPath)
            return
        }

        let toOpen = loader.mediaUrl || loader.thumbnailMxc
        let isMxc  = toOpen.startsWith("mxc://")

        isMxc ?
        py.callCoro("mxc_to_http", [toOpen], callback) : callback(toOpen)
    }


    TapHandler {
        onTapped: if (! image.animated) getOpenUrl(Qt.openUrlExternally)
        onDoubleTapped: getOpenUrl(Qt.openUrlExternally)
    }

    HoverHandler {
        id: hover
        onHoveredChanged: {
            if (hovered) {
                getOpenUrl(url => {
                    eventDelegate.hoveredMediaTypeUrl =
                        [EventDelegate.Media.Image, url]
                })
            } else {
                eventDelegate.hoveredMediaTypeUrl = []
            }
        }
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
        text: [loader.showDate, loader.showLocalEcho].join(" ").trim()
        textFormat: Text.StyledText
    }
}
