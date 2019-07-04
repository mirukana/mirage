import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../Base"
import "../utils.js" as Utils

MouseArea {
    id: roomDelegate
    width: roomList.width
    height: childrenRect.height

    onClicked:
        pageStack.showRoom(roomList.userId, roomList.category, model.roomId)

    HRowLayout {
        width: parent.width
        spacing: sidePane.normalSpacing

        HAvatar {
            id: roomAvatar
            name: Utils.stripRoomName(model.displayName)
        }

        HColumnLayout {
            Layout.fillWidth: true
            Layout.maximumWidth:
                parent.width - parent.totalSpacing - roomAvatar.width

            HLabel {
                id: roomLabel
                text: model.displayName || "<i>Empty room</i>"
                textFormat: model.displayName? Text.PlainText : Text.StyledText
                elide: Text.ElideRight
                maximumLineCount: 1
                verticalAlignment: Qt.AlignVCenter

                Layout.maximumWidth: parent.width
            }

            HLabel {
                id: subtitleLabel
                visible: Boolean(text)
                //text: models.timelines.getWhere({"roomId": model.roomId}, 1)[0].content
                textFormat: Text.StyledText

                font.pixelSize: HStyle.fontSize.small
                elide: Text.ElideRight
                maximumLineCount: 1

                Layout.maximumWidth: parent.width
            }
        }
    }
}
