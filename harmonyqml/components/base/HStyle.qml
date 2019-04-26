pragma Singleton
import QtQuick 2.7

QtObject {
    readonly property int foo: 3

    readonly property QtObject fontSize: QtObject {
        readonly property int smallest: 6
        readonly property int smaller: 8
        readonly property int small: 12
        readonly property int normal: 16
        readonly property int big: 24
        readonly property int bigger: 32
        readonly property int biggest: 48
    }

    readonly property QtObject fontFamily: QtObject {
        readonly property string sans: "Roboto"
        readonly property string serif: "Roboto Slab"
        readonly property string mono: "Hack"
    }
}
