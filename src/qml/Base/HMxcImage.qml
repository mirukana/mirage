import QtQuick 2.12

HImage {
    id: image
    source: sourceOverride || (show ? cachedPath : "")
    onMxcChanged: Qt.callLater(update)
    onWidthChanged: Qt.callLater(update)
    onHeightChanged: Qt.callLater(update)
    onVisibleChanged: Qt.callLater(update)


    property string clientUserId
    property string mxc
    property string sourceOverride: ""
    property bool thumbnail: true

    property bool show: false
    property string cachedPath: ""


    function update() {
        let w = sourceSize.width || width
        let h = sourceSize.height || height

        if (! image.mxc || w < 1 || h < 1 ) {
            show = false
            return
        }

        if (! image) return  // if it was destroyed

        if (! image.mxc.startsWith("mxc://")) {
            source = mxc
            show   = image.visible
            return
        }

        let method = image.thumbnail ? "get_thumbnail" : "get_media"
        let args = image.thumbnail ? [image.mxc, w, h] : [image.mxc]

        py.callClientCoro(
            clientUserId, "media_cache." + method, args, path => {
                if (! image) return
                image.cachedPath = path
                show             = image.visible
            }
        )
    }
}
