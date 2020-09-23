// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import ".."
import "../.."
import "../../Base"

HFlickable {
    id: flickable

    property HPopup viewer

    readonly property alias thumbnail: thumbnail
    readonly property alias full: full


    contentWidth:
        Math.max(window.width, viewer.paintedWidth * thumbnail.scale)
    contentHeight:
        Math.max(window.height, viewer.paintedHeight * thumbnail.scale)

    ScrollBar.vertical: null

    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onTapped: viewer.close()
        gesturePolicy: TapHandler.ReleaseWithinBounds
    }

    TapHandler {
        acceptedButtons: Qt.MiddleButton
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: viewer.openExternallyRequested()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: {
            if (wheel.modifiers !== Qt.ControlModifier) {
                wheel.accepted = false
                return
            }

            wheel.accepted  = true
            const add       = wheel.angleDelta.y / 120 / 5
            thumbnail.scale = Math.max(
                0.1, Math.min(10, thumbnail.scale + add),
            )
        }
    }

    HPopupShortcut {
        sequences: window.settings.keys.imageViewer.panLeft
        onActivated: utils.flickPages(flickable, -0.2, true, 5)
    }

    HPopupShortcut {
        sequences: window.settings.keys.imageViewer.panRight
        onActivated: utils.flickPages(flickable, 0.2, true, 5)
    }

    HPopupShortcut {
        sequences: window.settings.keys.imageViewer.panUp
        onActivated: utils.flickPages(flickable, -0.2, false, 5)
    }

    HPopupShortcut {
        sequences: window.settings.keys.imageViewer.panDown
        onActivated: utils.flickPages(flickable, 0.2, false, 5)
    }

    HPopupShortcut {
        sequences: window.settings.keys.imageViewer.zoomOut
        onActivated: thumbnail.scale = Math.max(0.1, thumbnail.scale - 0.2)
    }

    HPopupShortcut {
        sequences: window.settings.keys.imageViewer.zoomIn
        onActivated: thumbnail.scale = Math.min(10, thumbnail.scale + 0.2)
    }

    HPopupShortcut {
        sequences: window.settings.keys.imageViewer.zoomReset
        onActivated: resetScaleAnimation.start()
    }

    HMxcImage {
        id: thumbnail
        anchors.centerIn: parent
        width:
            viewer.alternateScaling && viewer.imageLargerThanWindow ?
            viewer.overallSize.width :

            viewer.alternateScaling ?
            window.width :

            Math.min(window.width, viewer.overallSize.width)

        height:
            viewer.alternateScaling && viewer.imageLargerThanWindow ?
            viewer.overallSize.height :

            viewer.alternateScaling ?
            window.height :

            Math.min(window.height, viewer.overallSize.height)

        clientUserId: viewer.clientUserId
        showPauseButton: false
        showProgressBar: false
        pause: viewer.imagesPaused
        speed: viewer.imagesSpeed
        rotation: viewer.imagesRotation
        fillMode: HMxcImage.PreserveAspectFit
        title: viewer.thumbnailTitle
        mxc: viewer.thumbnailMxc
        cachedPath: viewer.thumbnailPath
        cryptDict: viewer.thumbnailCryptDict
        // Use only cachedPath if set, don't waste time refetching thumb
        canUpdate: ! cachedPath

        Behavior on width {
            HNumberAnimation { overshoot: viewer.alternateScaling? 2 : 3 }
        }

        Behavior on height {
            HNumberAnimation { overshoot: viewer.alternateScaling? 2 : 3 }
        }

        Binding on showProgressBar {
            value: false
            when: ! thumbnail.show
        }

        HNumberAnimation {
            id: resetScaleAnimation
            target: thumbnail
            property: "scale"
            from: thumbnail.scale
            to: 1
            overshoot: 2
        }

        Timer {
            // Timer to not disappear before full image is done rendering
            interval: 1000
            running: full.status === HMxcImage.Ready
            onTriggered: thumbnail.show = false
        }

        HMxcImage {
            id: full
            anchors.fill: parent
            clientUserId: viewer.clientUserId
            thumbnail: false
            showPauseButton: false
            pause: viewer.imagesPaused
            speed: viewer.imagesSpeed
            rotation: viewer.imagesRotation
            fillMode: parent.fillMode
            title: viewer.fullTitle
            mxc: viewer.fullMxc
            cryptDict: viewer.fullCryptDict
            // Image never loads at 0 opacity or with visible: false
            opacity: status === HMxcImage.Ready ? 1 : 0.01

            Behavior on opacity { HNumberAnimation {} }
        }

        Item {
            anchors.centerIn: parent
            width: viewer.paintedWidth
            height: viewer.paintedHeight

            TapHandler {
                acceptedPointerTypes: PointerDevice.GenericPointer
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: {
                    thumbnail.scale === 1 ?
                    viewer.alternateScaling = ! viewer.alternateScaling :
                    resetScaleAnimation.start()
                }
                onDoubleTapped: viewer.toggleFullScreen()
            }

            TapHandler {
                acceptedPointerTypes: PointerDevice.Finger | PointerDevice.Pen
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: viewer.autoHideTimer.restart()
            }
        }
    }
}
