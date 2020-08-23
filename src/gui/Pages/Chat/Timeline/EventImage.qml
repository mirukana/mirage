// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../../.."
import "../../../Base"

HMxcImage {
    id: image

    property EventMediaLoader loader

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

    function openInternally() {
        eventList.openImageViewer(
            singleMediaInfo,
            loader.mediaUrl.startsWith("mxc://") ? "" : loader.mediaUrl,
        )
    }

    function openExternally() {
        loader.isMedia ?
        eventList.openMediaExternally(singleMediaInfo) :
        Qt.openUrlExternally(loader.mediaUrl)
    }


    width: fitSize.width
    height: fitSize.height
    horizontalAlignment: Image.AlignLeft

    clientUserId: chat.userId
    title: thumbnail ? loader.thumbnailTitle : loader.title
    animated: eventList.isAnimated(loader.singleMediaInfo)
    thumbnail: ! animated && loader.thumbnailMxc
    mxc: thumbnail ?
         (loader.thumbnailMxc || loader.mediaUrl) :
         (loader.mediaUrl || loader.thumbnailMxc)
    cryptDict: JSON.parse(
        thumbnail && loader.thumbnailMxc ?
        loader.singleMediaInfo.thumbnail_crypt_dict :
        loader.singleMediaInfo.media_crypt_dict
    )

    onCachedPathChanged:
        eventList.thumbnailCachedPaths[loader.singleMediaInfo.id] = cachedPath

    Binding on pause {
        value: true
        when: Object.keys(window.visiblePopups).length > 0
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        acceptedModifiers: Qt.NoModifier
        gesturePolicy: TapHandler.ReleaseWithinBounds

        onTapped: {
            print(loader.mediaUrl, loader.singleMediaInfo.media_http_url)
            if (eventList.selectedCount) {
                eventDelegate.toggleChecked()
                return
            }

            window.settings.media.openExternallyOnClick ?
            image.openExternally() :
            image.openInternally()
        }
    }

    TapHandler {
        acceptedButtons: Qt.MiddleButton
        acceptedModifiers: Qt.NoModifier
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped:
            window.settings.media.openExternallyOnClick ?
            image.openInternally() :
            image.openExternally()
    }

    TapHandler {
        acceptedModifiers: Qt.ShiftModifier
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped:
            eventList.checkFromLastToHere(singleMediaInfo.index)
    }

    HoverHandler {
        id: hover
        onHoveredChanged: {
            if (! hovered) {
                eventDelegate.hoveredMediaTypeUrl = []
                return
            }

            eventDelegate.hoveredMediaTypeUrl =
                [Utils.Media.Image, loader.mediaUrl, loader.title]
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
