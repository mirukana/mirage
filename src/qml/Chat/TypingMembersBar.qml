import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

Rectangle {
    id: typingMembersBar

    property alias label: typingLabel

    color: theme.chat.typingMembers.background
    implicitHeight: typingLabel.text ? rowLayout.height : 0
    opacity: implicitHeight ? 1 : 0

    Behavior on implicitHeight { HNumberAnimation {} }

    HRowLayout {
        id: rowLayout
        spacing: theme.spacing

        HIcon {
            id: icon
            svgName: "typing"  // TODO: animate

            Layout.fillHeight: true
            Layout.leftMargin: rowLayout.spacing / 2
        }

        HLabel {
            id: typingLabel
            textFormat: Text.StyledText
            elide: Text.ElideRight
            text: {
                let tm = chatPage.roomInfo.typing_members

                if (tm.length == 0) return ""
                if (tm.length == 1) return qsTr("%1 is typing...").arg(tm[0])

                return qsTr("%1 and %2 are typing...")
                       .arg(tm.slice(0, -1).join(", ")).arg(tm.slice(-1)[0])
            }

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: rowLayout.spacing / 4
            Layout.bottomMargin: rowLayout.spacing / 4
            Layout.leftMargin: rowLayout.spacing / 2
            Layout.rightMargin: rowLayout.spacing / 2
        }
    }
}
