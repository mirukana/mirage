import QtQuick 2.12
import QtGraphicalEffects 1.12

Image {
    id: image
    asynchronous: true
    cache: true
    fillMode: Image.PreserveAspectFit

    property color colorize: "transparent"

    layer.enabled: ! Qt.colorEqual(colorize, "transparent")
    layer.effect: ColorOverlay {
        color: image.colorize
        cached: image.cache
    }
}
