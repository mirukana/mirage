// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12
import "../../Base"

HPopup {
    id: popup

    property string thumbnailTitle
    property string thumbnailMxc
    property string thumbnailPath: ""
    property var thumbnailCryptDict
    property string fullTitle
    property string fullMxc
    property var fullCryptDict
    property size overallSize

    property bool alternateScaling: false
    property bool activedFullScreen: false

    readonly property alias canvas: canvas

    readonly property bool imageLargerThanWindow:
        overallSize.width > window.width || overallSize.height > window.height

    readonly property bool imageEqualToWindow:
        overallSize.width == window.width &&
        overallSize.height == window.height

    readonly property int paintedWidth:
        canvas.full.status === Image.Ready ?
        canvas.full.animatedPaintedWidth || canvas.full.paintedWidth :
        canvas.thumbnail.animatedPaintedWidth || canvas.thumbnail.paintedWidth

    readonly property int paintedHeight:
        canvas.full.status === Image.Ready ?
        canvas.full.animatedPaintedHeight || canvas.full.paintedHeight :
        canvas.thumbnail.animatedPaintedHeight || canvas.thumbnail.paintedHeight

    signal openExternallyRequested()

    function showFullScreen() {
        if (activedFullScreen) return

        window.showFullScreen()
        popup.activedFullScreen = true
        if (! imageLargerThanWindow) popup.alternateScaling = true
    }

    function exitFullScreen() {
        if (! activedFullScreen) return

        window.showNormal()
        popup.activedFullScreen = false
        if (! imageLargerThanWindow) popup.alternateScaling = false
    }

    function toggleFulLScreen() {
        const isFull = window.visibility === Window.FullScreen
        return isFull ? exitFullScreen() : showFullScreen()
    }


    margins: 0
    background: null

    onAboutToHide: exitFullScreen()

    Item {
        implicitWidth: window.width
        implicitHeight: window.height

        ViewerCanvas {
            id: canvas
            anchors.fill: parent
            viewer: popup
        }
    }
}
