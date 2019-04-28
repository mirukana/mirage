pragma Singleton
import QtQuick 2.7

QtObject {
    readonly property QtObject fontSize: QtObject {
        property int smallest: 6
        property int smaller: 8
        property int small: 12
        property int normal: 16
        property int big: 24
        property int bigger: 32
        property int biggest: 48
    }

    readonly property QtObject fontFamily: QtObject {
        property string sans: "SFNS Display"
        property string serif: "Roboto Slab"
        property string mono: "Hack"
    }

    readonly property QtObject colors: QtObject {
        property color background0: Qt.hsla(1, 1, 1, 0.4)
    }

    readonly property QtObject sidePane: QtObject {
        property color background: colors.background0
    }

    readonly property QtObject boxes: QtObject {
        property color background: colors.background0
        property int radius: 5
    }

    readonly property QtObject avatars: QtObject {
        property int radius: 5
    }
}
