import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.4
import "../Base" as Base

Rectangle {
    property bool hidden: false
    property var name: null  // null, string or PyQtFuture
    property var imageSource: null
    property int dimension: 48

    readonly property string resolvedName:
        ! name ? "?" :
        typeof(name) == "string" ? name :
        (name.value ? name.value : "?")

    width: dimension
    height: hidden ? 1 : dimension
    opacity: hidden ? 0 : 1

    color: resolvedName === "?" ?
           Base.HStyle.avatar.background.unknown :
           Qt.hsla(
               Backend.hueFromString(resolvedName),
               Base.HStyle.avatar.background.saturation,
               Base.HStyle.avatar.background.lightness,
               Base.HStyle.avatar.background.alpha
            )

    HLabel {
        z: 1
        anchors.centerIn: parent
        visible: ! hidden

        text: resolvedName.charAt(0)
        color: Base.HStyle.avatar.letter
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
