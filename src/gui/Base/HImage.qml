// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtGraphicalEffects 1.12

Image {
    id: image

    property bool circle: radius === circleRadius
    property bool broken: image.status === Image.Error
    property bool animate: true
    property bool animated:
        utils.urlExtension(image.source).toLowerCase() === "gif"

    property int animatedFillMode: AnimatedImage.PreserveAspectFit

    property alias radius: roundMask.radius
    property alias showProgressBar: progressBarLoader.active
    property bool showPauseButton: true
    property bool pause: ! window.settings.media.autoPlayGIF
    property bool forcePause: false
    property real speed: 1

    readonly property int circleRadius:
        Math.ceil(Math.max(image.width, image.height))

    readonly property int animatedPaintedWidth:
        animatedLoader.item ? animatedLoader.item.paintedWidth : 0

    readonly property int animatedPaintedHeight:
        animatedLoader.item ? animatedLoader.item.paintedHeight : 0

    readonly property int animatedImplicitWidth:
        animatedLoader.item ? animatedLoader.item.implicitWidth : 0

    readonly property int animatedImplicitHeight:
        animatedLoader.item ? animatedLoader.item.implicitHeight : 0

    function reload() {
        // Can be reimplemented in components inheriting HImage
        const oldSource = source
        source          = ""
        source          = oldSource
    }


    autoTransform: true
    asynchronous: true
    fillMode: Image.PreserveAspectFit

    cache: ! (animate && animated) &&
           (sourceSize.width + sourceSize.height) <= 512

    layer.enabled: radius !== 0
    layer.effect: OpacityMask { maskSource: roundMask }

    Component {
        id: animatedImageComponent

        AnimatedImage {
            id: animatedImage

            source: image.source
            autoTransform: image.autoTransform
            asynchronous: image.asynchronous
            fillMode: image.animatedFillMode

            mirror: image.mirror
            mipmap: image.mipmap
            smooth: image.smooth
            horizontalAlignment: image.horizontalAlignment
            verticalAlignment: image.verticalAlignment

            // Online GIFs won't be able to loop if cache is set to false,
            // but caching GIFs is expansive.
            cache: ! Qt.resolvedUrl(source).startsWith("file://")
            speed: window.mainUI.debugConsole.baseGIFSpeed * image.speed
            paused:
                ! visible || window.hidden || image.pause || image.forcePause

            layer.enabled: image.radius !== 0
            layer.effect: OpacityMask { maskSource: roundMask }

            // Hack to make the non-animated image behind this one
            // basically invisible
            Binding {
                target: image
                property: "fillMode"
                value: Image.Pad
            }
            Binding {
                target: image
                property: "sourceSize.width"
                value: 1
            }
            Binding {
                target: image
                property: "sourceSize.height"
                value: 1
            }

            HButton {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.leftMargin: theme.spacing / 2
                anchors.bottomMargin: theme.spacing / 2

                enableRadius: true
                icon.name: image.pause ? "player-play" : "player-pause"
                iconItem.small: true
                visible:
                    image.showPauseButton &&
                    parent.width > width * 2 &&
                    parent.height > height * 2

                onClicked: image.pause = ! image.pause
            }
        }
    }

    HLoader {
        id: animatedLoader
        anchors.fill: parent
        sourceComponent: animate && animated ? animatedImageComponent : null
    }

    HLoader {
        id: progressBarLoader

        readonly property alias progress: image.progress
        readonly property Component determinate: HCircleProgressBar {
            progress: image.progress
        }

        anchors.centerIn: parent
        width: Math.min(
            96 * theme.uiScale, Math.min(parent.width, parent.height) * 0.5,
        )
        height: width
        active:
            image.visible &&
            image.opacity > 0.01 &&
            image.status === Image.Loading

        sourceComponent: HBusyIndicator {}

        onProgressChanged:
            if (progress > 0 && progress < 1) sourceComponent = determinate
    }

    HIcon {
        anchors.centerIn: parent
        visible: image.broken
        svgName: "broken-image"
        colorize: theme.colors.negativeBackground
    }

    Rectangle {
        id: roundMask
        anchors.fill: parent
        visible: false
    }

    Timer {
        property int retries: 0

        running: image.broken
        repeat: true
        interval:
            Math.min(60, 0.2 * Math.pow(2, Math.min(1000, retries) - 1)) * 1000

        onTriggered: {
            image.reload()
            retries += 1
        }
    }
}
