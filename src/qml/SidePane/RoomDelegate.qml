import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../Base"
import "utils.js" as SidePaneJS

MouseArea {
    id: roomDelegate
    width: roomList.width
    height: childrenRect.height

    onClicked: pageStack.showRoom(roomList.userId, roomList.category, roomId)

    HRowLayout {
        width: parent.width
        spacing: sidePane.normalSpacing

        HAvatar {
            id: roomAvatar
            name: stripRoomName(displayName) || qsTr("Empty room")
        }

        HColumnLayout {
            Layout.fillWidth: true
            Layout.maximumWidth:
                parent.width - parent.totalSpacing - roomAvatar.width

            HLabel {
                id: roomLabel
                text: displayName ? displayName : "<i>Empty room</i>"
                textFormat: Text.StyledText
                elide: Text.ElideRight
                maximumLineCount: 1
                verticalAlignment: Qt.AlignVCenter

                Layout.maximumWidth: parent.width
            }

            //HLabel {
                //function getText() {
                    //return SidePaneJS.getLastRoomEventText(
                        //roomId, roomList.userId
                    //)
                //}

                //property var lastEvTime: lastEventDateTime
                //onLastEvTimeChanged: subtitleLabel.text = getText()

                //id: subtitleLabel
                //visible: text !== ""
                //text: getText()
                //textFormat: Text.StyledText

                //font.pixelSize: HStyle.fontSize.small
                //elide: Text.ElideRight
                //maximumLineCount: 1

                //Layout.maximumWidth: parent.width
            //}
        }
    }
}
