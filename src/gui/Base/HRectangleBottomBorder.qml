import QtQuick 2.12

Item {
    id: root

    property Rectangle rectangle: parent
    property alias borderHeight: clipArea.height
    property alias color: borderRectangle.color

    implicitWidth: rectangle.width
    implicitHeight: rectangle.height

    Item {
        id: clipArea
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        clip: true

        Rectangle {
            id: borderRectangle
            anchors.bottom: parent.bottom
            width: parent.width
            height: root.height
            radius: rectangle.radius
        }
    }
}
