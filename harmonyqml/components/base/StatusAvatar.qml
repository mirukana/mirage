import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.4

Avatar {
    Image {
        id: status
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        source: "../../icons/status.svg"
        asynchronous: true
        sourceSize.width: 12
    }
}
