import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../../Base"

MouseArea {
    id: memberDelegate
    width: memberList.width
    height: childrenRect.height

    property var memberInfo: users.getUser(model.userId)

    HRowLayout {
        width: parent.width
        spacing: memberList.spacing

        HUserAvatar {
            id: avatar
            userId: model.userId
        }

        HColumnLayout {
            Layout.fillWidth: true
            Layout.maximumWidth:
                parent.width - parent.totalSpacing - avatar.width

            HLabel {
                id: memberName
                text: memberInfo.displayName || model.userId
                elide: Text.ElideRight
                maximumLineCount: 1
                verticalAlignment: Qt.AlignVCenter

                Layout.maximumWidth: parent.width
            }
        }
    }
}
