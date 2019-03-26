import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.minimumHeight: 36
    Layout.maximumHeight: Layout.minimumHeight
    color: "#BBB"

    RowLayout {
        id: "row"
        spacing: 12
        anchors.fill: parent

        Avatar {
            id: "avatar"
            Layout.alignment: Qt.AlignTop
            dimmension: root.Layout.minimumHeight
            username: chatPage.room.display_name
        }

        PlainLabel {
            id: "roomName"
            text: chatPage.room.display_name
            font.pixelSize: bigSize
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.maximumWidth: row.width - row.spacing * (row.children.length - 1) - avatar.width
        }

        PlainLabel {
            id: "roomSubtitle"
            text: chatPage.room.subtitle
            font.pixelSize: smallSize
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.maximumWidth: row.width - row.spacing * (row.children.length - 1) - avatar.width - roomName.width
        }

        Item { Layout.fillWidth: true }
    }
}
