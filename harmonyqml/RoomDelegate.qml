import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.4

Item {
    id: "root"
    width: roomListView.width
    height: Math.max(roomLabel.height + subtitleLabel.height, avatar.height)

    RowLayout {
        anchors.fill: parent
        id: row
        spacing: 1

        Avatar { id: avatar; username: display_name; dimmension: 32 }

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

    HMouseArea {
        anchors.fill: parent
        onClicked: pageStack.show_room(roomListView.model.get(index))
    }
}
