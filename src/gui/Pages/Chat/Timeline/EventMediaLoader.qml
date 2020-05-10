// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../../../Base"

HLoader {
    id: loader
    visible: Boolean(item)
    x: eventContent.spacing

    onTypeChanged: {
        if (type === EventDelegate.Media.Image) {
            var file = "EventImage.qml"

        } else if (type !== EventDelegate.Media.Page) {
            var file  = "EventFile.qml"

        } else { return }

        loader.setSource(file, {loader})
    }


    property QtObject singleMediaInfo
    property string mediaUrl
    property string showSender: ""
    property string showDate: ""
    property string showLocalEcho: ""

    property string downloadedPath: ""

    readonly property string title:
        singleMediaInfo.media_title || utils.urlFileName(mediaUrl)

    readonly property string thumbnailTitle:
        singleMediaInfo.media_title.replace(
            /\.[^\.]+$/,
            singleMediaInfo.thumbnail_mime === "image/jpeg"    ? ".jpg" :
            singleMediaInfo.thumbnail_mime === "image/png"     ? ".png" :
            singleMediaInfo.thumbnail_mime === "image/gif"     ? ".gif" :
            singleMediaInfo.thumbnail_mime === "image/tiff"    ? ".tiff" :
            singleMediaInfo.thumbnail_mime === "image/svg+xml" ? ".svg" :
            singleMediaInfo.thumbnail_mime === "image/webp"    ? ".webp" :
            singleMediaInfo.thumbnail_mime === "image/bmp"     ? ".bmp" :
            ".thumbnail"
        ) || utils.urlFileName(mediaUrl)

    readonly property var imageExtensions: [
		"bmp", "gif", "jpg", "jpeg", "png", "pbm", "pgm", "ppm", "xbm", "xpm",
		"tiff", "webp", "svg",
    ]

    readonly property var videoExtensions: [
        "3gp", "avi", "flv", "m4p", "m4v", "mkv", "mov", "mp4",
		"mpeg", "mpg", "ogv", "qt", "vob", "webm", "wmv", "yuv",
    ]

    readonly property var audioExtensions: [
        "pcm", "wav", "raw", "aiff", "flac", "m4a", "tta", "aac", "mp3",
        "ogg", "oga", "opus",
    ]

    readonly property int type: {
        if (singleMediaInfo.event_type === "RoomAvatarEvent")
            return EventDelegate.Media.Image

        const mainType = singleMediaInfo.media_mime.split("/")[0].toLowerCase()

        if (mainType === "image") return EventDelegate.Media.Image
        if (mainType === "video") return EventDelegate.Media.Video
        if (mainType === "audio") return EventDelegate.Media.Audio

        const fileEvents = ["RoomMessageFile", "RoomEncryptedFile"]

        if (fileEvents.includes(singleMediaInfo.event_type))
            return EventDelegate.Media.File

        // If this is a preview for a link in a normal message
        const ext = utils.urlExtension(mediaUrl).toLowerCase()

        if (imageExtensions.includes(ext)) return EventDelegate.Media.Image
        if (videoExtensions.includes(ext)) return EventDelegate.Media.Video
        if (audioExtensions.includes(ext)) return EventDelegate.Media.Audio

        return EventDelegate.Media.Page
    }

    readonly property string thumbnailMxc: singleMediaInfo.thumbnail_url


    function download(callback) {
        if (! loader.mediaUrl.startsWith("mxc://")) {
            downloadedPath = loader.mediaUrl
            callback(loader.mediaUrl)
            return
        }

        if (! downloadedPath) print("Downloading " + loader.mediaUrl + " ...")

        const args = [
            loader.mediaUrl,
            loader.title,
            JSON.parse(loader.singleMediaInfo.media_crypt_dict)
        ]

        py.callCoro("media_cache.get_media", args, path => {
            if (! downloadedPath) print("Done: " + path)
            downloadedPath = path
            callback(path)
        })
    }
}
