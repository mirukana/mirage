// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12

HImage {
    id: image
    inderterminateProgressBar: isMxc
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
        if (! py) return  // component was destroyed

        const w = sourceSize.width || width
        const h = sourceSize.height || height

        if (! image.mxc || w < 1 || h < 1 ) {
            show = false
            return
        }

        if (! isMxc) {
            if (source !== mxc) source = mxc
            show = image.visible
            return
        }

        const method = image.thumbnail ? "get_thumbnail" : "get_media"
        const args   = image.thumbnail ?
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
