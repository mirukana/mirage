// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12
import "../Base"

HPopup {
    id: popup

    property alias thumbnailTitle: thumbnail.title
    property alias thumbnailMxc: thumbnail.mxc
    property alias thumbnailPath: thumbnail.cachedPath  // optional
    property alias thumbnailCryptDict: thumbnail.cryptDict
    property alias fullTitle: full.title
    property alias fullMxc: full.mxc
    property alias fullCryptDict: full.cryptDict
    property size overallSize

    property bool alternateScaling: false
    property bool activedFullScreen: false

    readonly property bool imageLargerThanWindow:
        overallSize.width > window.width || overallSize.height > window.height

    readonly property bool imageEqualToWindow:
        overallSize.width == window.width &&
        overallSize.height == window.height

    readonly property int paintedWidth:
        full.status === Image.Ready ?
        full.animatedPaintedWidth || full.paintedWidth :
        thumbnail.animatedPaintedWidth || thumbnail.paintedWidth

    readonly property int paintedHeight:
        full.status === Image.Ready ?
        full.animatedPaintedHeight || full.paintedHeight :
        thumbnail.animatedPaintedHeight || thumbnail.paintedHeight

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

    HFlickable {
        id: flickable
        pressDelay: 30
        implicitWidth: window.width
        implicitHeight: window.height
        contentWidth:
            Math.max(window.width, popup.paintedWidth * thumbnail.scale)
        contentHeight:
            Math.max(window.height, popup.paintedHeight * thumbnail.scale)

        ScrollBar.vertical: null

        TapHandler {
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onTapped: popup.close()
            gesturePolicy: TapHandler.ReleaseWithinBounds
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

        HMxcImage {
            id: thumbnail
            anchors.centerIn: parent
            width:
                popup.alternateScaling && popup.imageLargerThanWindow ?
                popup.overallSize.width :

                popup.alternateScaling ?
                window.width :

                Math.min(window.width, popup.overallSize.width)

            height:
                popup.alternateScaling && popup.imageLargerThanWindow ?
                popup.overallSize.height :

                popup.alternateScaling ?
                window.height :

                Math.min(window.height, popup.overallSize.height)

            fillMode: HMxcImage.PreserveAspectFit
            // Use only cachedPath if set, don't waste time refetching thumb
            canUpdate: ! cachedPath

            Behavior on width {
                HNumberAnimation { overshoot: popup.alternateScaling? 2 : 3 }
            }

            Behavior on height {
                HNumberAnimation { overshoot: popup.alternateScaling? 2 : 3 }
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
                thumbnail: false
                fillMode: parent.fillMode
                // Image never loads at 0 opacity or with visible: false
                opacity: status === HMxcImage.Ready ? 1 : 0.01

                Behavior on opacity { HNumberAnimation {} }
            }

            Item {
                anchors.centerIn: parent
                width: popup.paintedWidth
                height: popup.paintedHeight

                TapHandler {
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    onTapped: {
                        thumbnail.scale === 1 ?
                        popup.alternateScaling = ! popup.alternateScaling :
                        resetScaleAnimation.start()
                    }
                    onDoubleTapped: popup.toggleFulLScreen()
                }

                TapHandler {
                    acceptedButtons: Qt.MiddleButton
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    onTapped: popup.openExternallyRequested()
                }

                TapHandler {
                    acceptedButtons: Qt.RightButton
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    onTapped: popup.close()
                }
            }
        }
    }
}
