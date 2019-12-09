import QtQuick 2.12

HImage {
    id: image
    progressBar.indeterminate: isMxc
    source: sourceOverride || (show ? cachedPath : "")
    onWidthChanged: Qt.callLater(update)
    onHeightChanged: Qt.callLater(update)
    onVisibleChanged: Qt.callLater(update)
    onMxcChanged: Qt.callLater(update)


    property string mxc
    property string sourceOverride: ""
    property bool thumbnail: true
    property var cryptDict: ({})

    property bool show: false
    property string cachedPath: ""
    readonly property bool isMxc: mxc.startsWith("mxc://")


    function update() {
        let w = sourceSize.width || width
        let h = sourceSize.height || height

        if (! image.mxc || w < 1 || h < 1 ) {
            show = false
            return
        }

        if (! image) return  // if it was destroyed

        if (! isMxc) {
            if (source !== mxc) source = mxc
            show = image.visible
            return
        }

        let method = image.thumbnail ? "get_thumbnail" : "get_media"
        let args = image.thumbnail ?
                   [image.mxc, w, h, cryptDict] : [image.mxc, cryptDict]

        py.callCoro("media_cache." + method, args, path => {
                if (! image) return
                if (image.cachedPath !== path) image.cachedPath = path

                image.broken = false
                image.show   = image.visible

            }, () => {
                image.broken = true
            },
        )
    }
}
