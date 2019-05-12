import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../../Base"

MouseArea {
    id: memberDelegate
    width: memberList.width
    height: childrenRect.height

    property var member: Backend.users.get(modelData)

    HRowLayout {
        width: parent.width
        spacing: memberList.spacing

        HAvatar {
            id: memberAvatar
            name: member.displayName.value
        }

        HColumnLayout {
            Layout.fillWidth: true
            Layout.maximumWidth:
                parent.width - parent.totalSpacing - memberAvatar.width

            HLabel {
                id: memberName
                text: member.displayName.value
                elide: Text.ElideRight
                maximumLineCount: 1
                verticalAlignment: Qt.AlignVCenter

                Layout.maximumWidth: parent.width
            }
        }
    }
}
