// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import CppUtils 0.1
import "../../../Base"

HTile {
    id: file
    width: Math.min(
        eventDelegate.width,
        eventContent.maxMessageWidth,
        Math.max(theme.chat.message.fileMinWidth, implicitWidth),
    )
    height: Math.max(theme.chat.message.avatarSize, implicitHeight)

    title.text: loader.singleMediaInfo.media_title || qsTr("Untitled file")
    title.elide: Text.ElideMiddle
    subtitle.text: CppUtils.formattedBytes(loader.singleMediaInfo.media_size)

    image: HIcon {
        svgName: "download"
    }

    onLeftClicked: download(Qt.openUrlExternally)
    onRightClicked: eventDelegate.openContextMenu()

    onHoveredChanged: {
        if (! hovered) {
            eventDelegate.hoveredMediaTypeUrl = []
            return
        }

        eventDelegate.hoveredMediaTypeUrl = [
            EventDelegate.Media.File,
            loader.downloadedPath.replace(/^file:\/\//, "") || loader.mediaUrl
        ]
    }


    property EventMediaLoader loader

    readonly property bool cryptDict: loader.singleMediaInfo.media_crypt_dict
    readonly property bool isEncrypted: ! utils.isEmptyObject(cryptDict)
}
