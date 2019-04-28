import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.4
import "../base" as Base

Item {
    property bool invisible: false
    property var name: null  // null, string or PyQtFuture
    property var imageSource: null
    property int dimmension: 48

    readonly property string resolvedName:
        ! name ? "?" :
        typeof(name) == "string" ? name :
        (name.value ? name.value : "?")

    id: root
    width: dimmension
    height: invisible ? 1 : dimmension

    Rectangle {
        id: letterRectangle
        anchors.fill: parent
        visible: ! invisible && imageSource === null
        color: resolvedName === "?" ?
               Base.HStyle.avatar.background.unknown :
               Qt.hsla(
                   Backend.hueFromString(resolvedName),
                   Base.HStyle.avatar.background.saturation,
                   Base.HStyle.avatar.background.lightness,
                   Base.HStyle.avatar.background.alpha
                )

        HLabel {
            anchors.centerIn: parent
            text: resolvedName.charAt(0)
            color: Base.HStyle.avatar.letter
            font.pixelSize: letterRectangle.height / 1.4
        }
    }

    Image {
        id: avatarImage
        anchors.fill: parent
        visible: ! invisible && imageSource !== null

        Component.onCompleted: if (imageSource) {source = imageSource}
        asynchronous: true
        mipmap: true
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: root.dimmension
    }
}
