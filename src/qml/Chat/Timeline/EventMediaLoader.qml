import QtQuick 2.12
import "../../Base"
import "../../utils.js" as Utils

HLoader {
    id: loader


    enum Type { Page, File, Image, Video, Audio }

    property QtObject info
    property url mediaUrl

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
        let main_type = info.media_mime.split("/")[0].toLowerCase()

        if (main_type === "image") return EventMediaLoader.Type.Image
        if (main_type === "video") return EventMediaLoader.Type.Video
        if (main_type === "audio") return EventMediaLoader.Type.Audio

        if (info.event_type === "RoomMessageFile")
            return EventMediaLoader.Type.File

        let ext = Utils.urlExtension(mediaUrl)

        if (imageExtensions.includes(ext)) return EventMediaLoader.Type.Image
        if (videoExtensions.includes(ext)) return EventMediaLoader.Type.Video
        if (audioExtensions.includes(ext)) return EventMediaLoader.Type.Audio

        return EventMediaLoader.Type.Page
    }

    readonly property url previewUrl: (
        type === EventMediaLoader.Type.File ||
        type === EventMediaLoader.Type.Image ?
        info.thumbnail_url : ""
    ) || mediaUrl


    onPreviewUrlChanged: {
        if (type === EventMediaLoader.Type.Image) {
            var file  = "EventImage.qml"
            var props = { source: previewUrl }
        } else {
            return
        }

        loader.setSource(file, props)
    }
}
