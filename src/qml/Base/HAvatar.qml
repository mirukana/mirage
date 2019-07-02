import QtQuick 2.7
import "../Base"

Rectangle {
    property var name: null
    property var imageUrl: null
    property int dimension: HStyle.avatar.size
    property bool hidden: false

    function stripUserId(user_id) {
        return user_id.substring(1)  // Remove leading @
    }
    function stripRoomName(name) {
        return name[0] == "#" ? name.substring(1) : name
    }

    function hueFromName(name) {
        var hue = 0
        for (var i = 0; i < name.length; i++) {
            hue += name.charCodeAt(i) * 99
        }
        return hue % 360 / 360
    }

    width: dimension
    height: hidden ? 1 : dimension
    implicitWidth: dimension
    implicitHeight: hidden ? 1 : dimension

    opacity: hidden ? 0 : 1

    color: name ?
           Qt.hsla(
               hueFromName(name),
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
