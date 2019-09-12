import QtQuick 2.12

Image {
    id: image
    autoTransform: true
    asynchronous: true
    fillMode: Image.PreserveAspectFit

    cache: ! (animate && animated) &&
           (sourceSize.width + sourceSize.height) <= 512


    property bool animate: true

    readonly property bool animated:
        image.source.toString()
        .split("/").splice(-1)[0].split("?")[0].toLowerCase()
        .endsWith(".gif")


    Component {
        id: animatedImageComponent

        AnimatedImage {
            id: animatedImage
            source: image.source
            autoTransform: image.autoTransform
            asynchronous: image.asynchronous
            fillMode: image.fillMode
            mirror: image.mirror
            mipmap: image.mipmap
            smooth: image.smooth
            horizontalAlignment: image.horizontalAlignment
            verticalAlignment: image.verticalAlignment

            cache: true  // Needed to allow GIFs to loop
            paused: ! visible || window.hidden || userPaused
            property var pr: frameCount
            onPrChanged: print(source, pr)

            property bool userPaused: false

            TapHandler {
                onTapped: parent.userPaused = ! parent.userPaused
            }

            HIcon {
                svgName: "play"
                colorize: "transparent"
                anchors.centerIn: parent
                dimension: Math.min(
                    parent.width - theme.spacing * 2,
                    parent.height - theme.spacing * 2,
                    theme.controls.image.maxPauseIndicatorSize,
                )
                scale: parent.paused ? 1 : 0
                visible: scale > 0

                Behavior on scale { HNumberAnimation { overshoot: 4 } }
            }
        }
    }

    HLoader {
        id: loader
        anchors.fill: parent
        sourceComponent: animate && animated ? animatedImageComponent : null
    }
}
