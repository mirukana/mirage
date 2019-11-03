import QtQuick 2.12
import "../utils.js" as Utils

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

    property bool show: false
    property string cachedPath: ""


    function update() {
        let w = sourceSize.width || width
        let h = sourceSize.height || height

        if (! image.mxc || w < 1 || h < 1 ) {
            show = false
            return
        }

        let arg = [image.mxc, w, h]

        if (! image) return  // if it was destroyed

        py.callClientCoro(clientUserId, "media_cache.thumbnail", arg, path => {
            if (! image) return
            image.cachedPath = path
            show             = image.visible
        })
    }
}
