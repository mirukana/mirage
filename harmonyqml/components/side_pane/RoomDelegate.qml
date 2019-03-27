import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.4
import "../base" as Base

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

        Base.Avatar { id: avatar; name: display_name; dimmension: 36 }

        ColumnLayout {
            spacing: 0

            Base.HLabel {
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
            Base.HLabel {
                function get_text() {
                    var msgs = Backend.messagesModel[room_id]
                    if (msgs.count < 1) { return "" }

                    var msg = msgs.get(-1)
                    var color_ = (msg.sender_id === roomList.user.user_id ?
                                  "darkblue" : "purple")

                    return "<font color=\"" + color_ + "\">" +
                           Backend.getUser(msg.sender_id).display_name +
                           ":</font> " +
                           msg.content
                }

                id: subtitleLabel
                visible: text !== ""
                text: Backend.messagesModel[room_id].reloadThis, get_text()
                textFormat: Text.StyledText

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
