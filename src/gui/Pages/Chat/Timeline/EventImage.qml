// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../../.."
import "../../../Base"

HMxcImage {
    id: image

    property EventMediaLoader loader

    readonly property real zoom: window.settings.General.zoom

    readonly property real maxHeight:
        eventList.height *
        window.settings.Chat.Files.max_thumbnail_height_ratio * zoom

    readonly property size fitSize: utils.fitSize(
        // Minimum display size
        window.settings.Chat.Files.min_thumbnail_size[0] * zoom,
        window.settings.Chat.Files.min_thumbnail_size[1] * zoom,

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
            Math.max(
                maxHeight,
                window.settings.Chat.Files.min_thumbnail_size[0] * zoom,
            ),
            pureMedia ? Infinity : eventContent.maxMessageWidth,
            eventDelegate.width - eventContent.spacing - avatarWrapper.width -
            eventContent.spacing * 2,  // padding
        ),
        Math.max(
            maxHeight,
            window.settings.Chat.Files.min_thumbnail_size[1] * zoom,
        ),
    )

    readonly property bool hovered: hover.hovered

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
    animated: eventList.isAnimated(loader.singleMediaInfo, loader.mediaUrl)
    forcePause: Object.keys(window.visiblePopups).length > 0
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

    TapHandler {
        acceptedButtons: Qt.LeftButton
        acceptedModifiers: Qt.NoModifier
        gesturePolicy: TapHandler.ReleaseWithinBounds

        onTapped: {
            if (eventList.selectedCount) {
                eventDelegate.toggleChecked()
                return
            }

            window.settings.Chat.Files.click_opens_externally ?
            image.openExternally() :
            image.openInternally()
        }
    }

    TapHandler {
        acceptedButtons: Qt.MiddleButton
        acceptedModifiers: Qt.NoModifier
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped:
            window.settings.Chat.Files.click_opens_externally ?
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
        text: loader.showDate + loader.showLocalEcho

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
