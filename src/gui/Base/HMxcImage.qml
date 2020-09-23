// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../PythonBridge"

HImage {
    id: image

    property string clientUserId
    property string mxc
    property string title
    property string sourceOverride: ""
    property bool thumbnail: true
    property var cryptDict: ({})

    property string cachedPath: ""
    property bool canUpdate: true
    property bool show: ! canUpdate

    property Future getFuture: null

    readonly property bool isMxc: mxc.startsWith("mxc://")

    function reload() {
        if (! py || ! canUpdate) return  // component was destroyed

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
        const args   =
            image.thumbnail ?
            [clientUserId, image.mxc, image.title, w, h, cryptDict] :
            [clientUserId, image.mxc, image.title, cryptDict]

        getFuture = py.callCoro("media_cache." + method, args, path => {
                if (! image) return
                if (image.cachedPath !== path) image.cachedPath = path

                image.broken = Qt.binding(() => image.status === Image.Error)
                image.show   = image.visible

            }, (type, args, error, traceback) => {
                print(`Error retrieving ${mxc} (${title}): ${type} ${args}`)
                if (image) image.broken = true
            },
        )
    }


    source: sourceOverride || (show ? cachedPath : "")
    showProgressBar:
        (isMxc && status === Image.Null) || status === Image.Loading

    onWidthChanged: Qt.callLater(reload)
    onHeightChanged: Qt.callLater(reload)
    onVisibleChanged: Qt.callLater(reload)
    onMxcChanged: Qt.callLater(reload)
    Component.onDestruction: if (getFuture) getFuture.cancel()
}
