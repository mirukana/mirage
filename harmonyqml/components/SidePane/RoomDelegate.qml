import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.4
import "../Base"
import "utils.js" as SidePaneJS

MouseArea {
    id: roomDelegate
    width: roomList.width
    height: roomList.childrenHeight

    onClicked: pageStack.showRoom(roomList.userId, roomId)

    HRowLayout {
        anchors.fill: parent
        id: row
        spacing: 1

        HAvatar {
            id: roomAvatar
            name: displayName
            dimension: roomDelegate.height
        }

        HColumnLayout {
            HLabel {
                id: roomLabel
                text: displayName ? displayName : "<i>Empty room</i>"
                textFormat: Text.StyledText
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.maximumWidth:
                    row.width - row.totalSpacing - roomAvatar.width
                verticalAlignment: Qt.AlignVCenter

                topPadding: -2
                bottomPadding: subtitleLabel.visible ? 0 : topPadding
                leftPadding: 5
                rightPadding: leftPadding
            }

            HLabel {
                function getText() {
                    return SidePaneJS.getLastRoomEventText(
                        roomId, roomList.userId
                    )
                }

                Connections {
                    target: Backend.models.roomEvents.get(roomId)
                    onChanged: subtitleLabel.text = subtitleLabel.getText()
                }

                id: subtitleLabel
                visible: text !== ""
                text: getText()
                textFormat: Text.StyledText

                font.pixelSize: HStyle.fontSize.small
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
