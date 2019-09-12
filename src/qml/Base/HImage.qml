import QtQuick 2.12
import QtGraphicalEffects 1.12

Image {
    id: image
    autoTransform: true
    asynchronous: true
    fillMode: Image.PreserveAspectFit

    cache: ! (animate && animated) &&
           (sourceSize.width + sourceSize.height) <= 512


    property bool animate: true
    property color colorize: "transparent"

    readonly property bool animated:
        image.source.toString()
        .split("/").splice(-1)[0].split("?")[0].toLowerCase()
        .endsWith(".gif")


    layer.enabled: ! Qt.colorEqual(colorize, "transparent")
    layer.effect: ColorOverlay {
        color: image.colorize
        cached: image.cache
    }


    Component {
        id: animatedImage

        AnimatedImage {
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

            property bool userPaused: false

            TapHandler {
                onTapped: parent.userPaused = ! parent.userPaused
            }
        }
    }

    HLoader {
        id: loader
        anchors.fill: parent
        sourceComponent: animate && animated ? animatedImage : null
    }
}
