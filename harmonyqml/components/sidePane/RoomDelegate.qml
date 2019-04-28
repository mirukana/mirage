import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.4
import "../base" as Base
import "utils.js" as SidePaneJS

MouseArea {
    id: root
    width: roomList.width
    height: roomList.childrenHeight

    onClicked: pageStack.showRoom(roomList.forUserId, roomId)

    RowLayout {
        anchors.fill: parent
        id: row
        spacing: 1

        Base.HAvatar { id: avatar; name: displayName; dimmension: root.height }

        ColumnLayout {
            spacing: 0

            Base.HLabel {
                id: roomLabel
                text: displayName ? displayName : "<i>Empty room</i>"
                textFormat: Text.StyledText
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
                function getText() {
                    return SidePaneJS.getLastRoomEventText(
                        roomId, roomList.forUserId
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

                font.pixelSize: Base.HStyle.fontSize.small
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
