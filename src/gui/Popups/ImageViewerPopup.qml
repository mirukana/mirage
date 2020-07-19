// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12
import "../Base"

HPopup {
    id: popup

    property alias thumbnailTitle: thumbnail.title
    property alias thumbnailMxc: thumbnail.mxc
    property alias thumbnailPath: thumbnail.cachedPath
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


    margins: 0
    background: null

    onAboutToHide: if (activedFullScreen) window.showNormal()

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
            // Use only the cachedPath, don't waste time refetching thumb
            canUpdate: false

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
                    onDoubleTapped: {
                        if (window.visibility === Window.FullScreen) {
                            window.showNormal()
                            popup.activedFullScreen = false
                            popup.alternateScaling  = false
                        } else {
                            window.showFullScreen()
                            popup.activedFullScreen = true
                            popup.alternateScaling  = true
                        }
                    }
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
