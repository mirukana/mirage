import QtQuick 2.7
import "../Base"

Rectangle {
    property var name: null
    property var imageUrl: null
    property int dimension: 36
    property bool hidden: false

    width: dimension
    height: hidden ? 1 : dimension
    implicitWidth: dimension
    implicitHeight: hidden ? 1 : dimension

    opacity: hidden ? 0 : 1

    color: name ?
           Qt.hsla(
               Backend.hueFromString(name),
               HStyle.avatar.background.saturation,
               HStyle.avatar.background.lightness,
               HStyle.avatar.background.alpha
           ) :
           HStyle.avatar.background.unknown

    HLabel {
        z: 1
        anchors.centerIn: parent
        visible: ! hidden

        text: name ? name.charAt(0) : "?"
        color: HStyle.avatar.letter
        font.pixelSize: parent.height / 1.4
    }

    HImage {
        z: 2
        anchors.fill: parent
        visible: ! hidden && imageUrl

        Component.onCompleted: if (imageUrl) { source = imageUrl }
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: dimension
    }
}
