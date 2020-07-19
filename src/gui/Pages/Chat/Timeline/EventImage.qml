// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../../../Base"

HMxcImage {
    id: image

    property EventMediaLoader loader

    readonly property bool isEncrypted: ! utils.isEmptyObject(cryptDict)

    readonly property real maxHeight:
        eventList.height * theme.chat.message.thumbnailMaxHeightRatio

    readonly property size fitSize: utils.fitSize(
        // Minimum display size
        theme.chat.message.thumbnailMinSize.width,
        theme.chat.message.thumbnailMinSize.height,

        // Real size
        (
            loader.singleMediaInfo.thumbnail_width ||
            loader.singleMediaInfo.media_width ||
            implicitWidth ||
            800
        ) * theme.uiScale,

        (
            loader.singleMediaInfo.thumbnail_height ||
            loader.singleMediaInfo.media_height ||
            implicitHeight ||
            600
        ) * theme.uiScale,

        // Maximum display size
        Math.min(
            Math.max(maxHeight, theme.chat.message.thumbnailMinSize.width),
            pureMedia ? Infinity : eventContent.maxMessageWidth,
            eventDelegate.width - eventContent.spacing - avatarWrapper.width -
            eventContent.spacing * 2,  // padding
        ),
        Math.max(maxHeight, theme.chat.message.thumbnailMinSize.height),
    )

    function getOpenUrl(callback) {
        if (image.isEncrypted && loader.mediaUrl) {
            loader.download(callback)
            return
        }

        if (image.isEncrypted) {
            callback(image.cachedPath)
            return
        }

        const toOpen = loader.mediaUrl || loader.thumbnailMxc
        const isMxc  = toOpen.startsWith("mxc://")

        isMxc ?
        py.callClientCoro(chat.userId, "mxc_to_http", [toOpen], callback) :
        callback(toOpen)
    }

    function openUrlExternally() {
        getOpenUrl(Qt.openUrlExternally)
    }

    function openImageViewer() {
        utils.makePopup(
            "Popups/ImageViewerPopup.qml",
            {
                thumbnailTitle: loader.thumbnailTitle,
                thumbnailMxc: loader.thumbnailMxc,
                thumbnailPath: image.cachedPath,
                thumbnailCryptDict:
                    JSON.parse(loader.singleMediaInfo.thumbnail_crypt_dict),

                fullTitle: loader.title,
                // The thumbnail/cached path will be the full GIF
                fullMxc: animated ? "" : loader.mediaUrl,
                fullCryptDict:
                    JSON.parse(loader.singleMediaInfo.media_crypt_dict),

                overallSize: Qt.size(
                    loader.singleMediaInfo.media_width ||
                    loader.singleMediaInfo.thumbnail_width,

                    loader.singleMediaInfo.media_height ||
                    loader.singleMediaInfo.thumbnail_height,
                )
            },
            obj => { obj.openExternallyRequested.connect(openUrlExternally) },
        )
    }


    width: fitSize.width
    height: fitSize.height
    horizontalAlignment: Image.AlignLeft

    title: thumbnail ? loader.thumbnailTitle : loader.title
    animated: loader.singleMediaInfo.media_mime === "image/gif" ||
              utils.urlExtension(loader.mediaUrl).toLowerCase() === "gif"
    thumbnail: ! animated && loader.thumbnailMxc
    mxc: thumbnail ?
         (loader.thumbnailMxc || loader.mediaUrl) :
         (loader.mediaUrl || loader.thumbnailMxc)
    cryptDict: JSON.parse(
        thumbnail && loader.thumbnailMxc ?
        loader.singleMediaInfo.thumbnail_crypt_dict :
        loader.singleMediaInfo.media_crypt_dict
    )

    TapHandler {
        acceptedButtons: Qt.LeftButton
        acceptedModifiers: Qt.NoModifier
        onTapped:
            eventList.selectedCount ?
            eventDelegate.toggleChecked() :
            openImageViewer()

        gesturePolicy: TapHandler.ReleaseWithinBounds
    }

    TapHandler {
        acceptedButtons: Qt.MiddleButton
        acceptedModifiers: Qt.NoModifier
        onTapped: getOpenUrl(Qt.openUrlExternally)
        gesturePolicy: TapHandler.ReleaseWithinBounds
    }

    TapHandler {
        acceptedModifiers: Qt.ShiftModifier
        onTapped:
            eventList.checkFromLastToHere(singleMediaInfo.index)

        gesturePolicy: TapHandler.ReleaseWithinBounds
    }

    HoverHandler {
        id: hover
        onHoveredChanged: {
            if (! hovered) {
                eventDelegate.hoveredMediaTypeUrl = []
                return
            }

            eventDelegate.hoveredMediaTypeUrl = [
                EventDelegate.Media.Image,
                loader.downloadedPath.replace(/^file:\/\//, "") ||
                loader.mediaUrl
            ]
        }
    }

    EventImageTextBubble {
        anchors.left: parent.left
        anchors.top: parent.top
        text: loader.showSender
        textFormat: Text.StyledText
        opacity: hover.hovered ? 0 : 1
        visible: opacity > 0

        Behavior on opacity { HNumberAnimation {} }
    }

    EventImageTextBubble {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        text: [loader.showDate, loader.showLocalEcho].join(" ").trim()
        textFormat: Text.StyledText
        opacity: hover.hovered ? 0 : 1
        visible: opacity > 0

        Behavior on opacity { HNumberAnimation {} }
    }

    Rectangle {
        anchors.fill: parent
        visible: opacity > 0
        color: theme.chat.message.checkedBackground
        opacity:
            eventDelegate.checked ?
            theme.chat.message.thumbnailCheckedOverlayOpacity :
            0

        Behavior on opacity { HNumberAnimation {} }
    }
}
