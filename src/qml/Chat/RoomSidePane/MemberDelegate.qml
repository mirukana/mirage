import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

HInteractiveRectangle {
    id: memberDelegate
    width: memberList.width
    height: childrenRect.height

    Row {
        width: parent.width - leftPadding * 2
        padding: roomSidePane.currentSpacing / 2
        leftPadding: roomSidePane.currentSpacing
        rightPadding: 0

        HRowLayout {
            width: parent.width
            spacing: roomSidePane.currentSpacing

            HUserAvatar {
                id: avatar
                userId: model.user_id
                displayName: model.display_name
                avatarUrl: model.avatar_url
            }

            HColumnLayout {
                Layout.fillWidth: true

                HLabel {
                    id: memberName
                    text: model.display_name || model.user_id
                    elide: Text.ElideRight
                    verticalAlignment: Qt.AlignVCenter

                    Layout.fillWidth: true
                }
            }
        }
    }
}
