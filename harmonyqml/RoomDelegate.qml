import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.4

Item {
    width: roomListView.width
    height: avatar.height

    RowLayout {
        anchors.fill: parent
        id: row
        spacing: 1

        Avatar { id: avatar; username: display_name }

        ColumnLayout {
            spacing: 0

            PlainLabel {
                id: roomLabel
                text: display_name
                padding: 5
                bottomPadding: subtitleLabel.visible ? 0 : padding
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.maximumWidth: row.width - row.spacing - avatar.width
                verticalAlignment: Qt.AlignVCenter
            }
            PlainLabel {
                id: subtitleLabel
                visible: text !== ""
                text: subtitle
                padding: roomLabel.padding
                topPadding: 0
                font.pixelSize: smallSize
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.maximumWidth: roomLabel.Layout.maximumWidth
            }
        }

        Item { Layout.fillWidth: true }
    }

    HMouseArea {
        anchors.fill: parent
        onClicked: pageStack.show_room(roomListView.model.get(index))
    }
}
