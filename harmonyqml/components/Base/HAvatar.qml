import QtQuick 2.7
import "../Base"

Rectangle {
    property bool hidden: false
    property var name: null  // null, string or PyQtFuture
    property var imageSource: null
    property int dimension: 36


    readonly property string resolvedName:
        ! name ? "?" :
        typeof(name) == "string" ? name :
        (name.value ? name.value : "?")

    width: dimension
    height: hidden ? 1 : dimension
    implicitWidth: dimension
    implicitHeight: hidden ? 1 : dimension

    opacity: hidden ? 0 : 1

    color: resolvedName === "?" ?
           HStyle.avatar.background.unknown :
           Qt.hsla(
               Backend.hueFromString(resolvedName),
               HStyle.avatar.background.saturation,
               HStyle.avatar.background.lightness,
               HStyle.avatar.background.alpha
            )

    HLabel {
        z: 1
        anchors.centerIn: parent
        visible: ! hidden

        text: resolvedName.charAt(0)
        color: HStyle.avatar.letter
        font.pixelSize: parent.height / 1.4
    }

    HImage {
        z: 2
        anchors.fill: parent
        visible: ! hidden && imageSource !== null

        Component.onCompleted: if (imageSource) {source = imageSource}
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: dimension
    }
}
