import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.4

MouseArea {
    id: "root"
    width: roomList.width
    height: Math.max(roomLabel.height + subtitleLabel.height, avatar.height)

    onClicked: pageStack.show_room(
        roomList.user,
        roomList.model.get(index)
    )

    RowLayout {
        anchors.fill: parent
        id: row
        spacing: 1

        Avatar { id: avatar; username: display_name; dimmension: 36 }

        ColumnLayout {
            spacing: 0

            PlainLabel {
                id: roomLabel
                text: display_name
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.maximumWidth: row.width - row.spacing - avatar.width
                verticalAlignment: Qt.AlignVCenter

                topPadding: -2
                bottomPadding: subtitleLabel.visible ? 0 : topPadding
                leftPadding: 5
                rightPadding: leftPadding
            }
            PlainLabel {
                id: subtitleLabel
                visible: text !== ""
                text: subtitle
                font.pixelSize: smallSize
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.maximumWidth: roomLabel.Layout.maximumWidth

                topPadding: -2
                bottomPadding: topPadding
                leftPadding: 5
                rightPadding: leftPadding
            }
        }

        Item { Layout.fillWidth: true }
    }
}
