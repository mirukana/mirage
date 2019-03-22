import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.minimumHeight: avatar.height
    Layout.maximumHeight: Layout.minimumHeight
    color: "#BBB"

    Row {
        id: "row"
        spacing: 8

        Avatar { id: "avatar"; username: chatPage.room.display_name }

        Column {
            PlainLabel {
                height: subtitleLabel.visible ? implicitHeight : row.height
                id: "roomName"
                text: chatPage.room.display_name
                font.pixelSize: bigSize
                elide: Text.ElideRight
                maximumLineCount: 1
                width: root.width - avatar.width - row.spacing * 2
                verticalAlignment: Qt.AlignVCenter
            }
            PlainLabel {
                id: subtitleLabel
                text: chatPage.room.subtitle
                visible: text !== ""
                font.pixelSize: smallSize
                elide: Text.ElideRight
                maximumLineCount: 1
                width: roomName.width
            }
        }
    }
}
