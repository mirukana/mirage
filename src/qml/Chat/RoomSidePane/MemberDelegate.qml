import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

HInteractiveRectangle {
    id: memberDelegate
    width: memberList.width
    height: rowLayout.height

    HRowLayout {
        id: rowLayout
        x: roomSidePane.currentSpacing
        width: parent.width - roomSidePane.currentSpacing * 1.5
        height: avatar.height + roomSidePane.currentSpacing / 1.5
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
