import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.4

Item {
    property bool invisible: false
    property var name: null  // null, string or PyQtFuture
    property var imageSource: null
    property int dimmension: 48

    readonly property string resolved_name:
        ! name ? "?" :
        typeof(name) == "string" ? name :
        (name.value ? name.value : "?")

    id: "root"
    width: dimmension
    height: invisible ? 1 : dimmension

    Rectangle {
        id: "letterRectangle"
        anchors.fill: parent
        visible: ! invisible && imageSource === null
        color: resolved_name === "?" ?
               Qt.hsla(0, 0, 0.22, 1) :
               Qt.hsla(Backend.hueFromString(resolved_name), 0.22, 0.5, 1)

        HLabel {
            anchors.centerIn: parent
            text: resolved_name.charAt(0)
            color: "white"
            font.pixelSize: letterRectangle.height / 1.4
        }
    }

    Image {
        id: "avatarImage"
        anchors.fill: parent
        visible: ! invisible && imageSource !== null

        Component.onCompleted: if (imageSource) {source = imageSource}
        asynchronous: true
        mipmap: true
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: root.dimmension
    }
}
