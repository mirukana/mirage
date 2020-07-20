// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../../.."
import "../../../Base"

HLoader {
    id: loader

    property QtObject singleMediaInfo
    property string mediaUrl
    property string showSender: ""
    property string showDate: ""
    property string showLocalEcho: ""

    readonly property string title:
        singleMediaInfo.media_title || utils.urlFileName(mediaUrl)

    readonly property string thumbnailTitle:
        eventList.getThumbnailTitle(singleMediaInfo)

    readonly property bool isMedia:
        eventList.getMediaType(singleMediaInfo) !== null

    readonly property int type:
        isMedia ?
        eventList.getMediaType(singleMediaInfo) :
        utils.getLinkType(mediaUrl)

    readonly property string thumbnailMxc: singleMediaInfo.thumbnail_url


    visible: Boolean(item)
    x: eventContent.spacing

    onTypeChanged: {
        if (type === Utils.Media.Image) {
            var file = "EventImage.qml"

        } else if (type !== Utils.Media.Page) {
            var file  = "EventFile.qml"

        } else { return }

        loader.setSource(file, {loader})
    }
}
