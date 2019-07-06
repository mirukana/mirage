import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../Base"

HRectangle {
    property alias label: typingLabel

    implicitWidth: childrenRect.width
    implicitHeight: typingLabel.text ? childrenRect.height : 0
    color: HStyle.chat.typingMembers.background

    Row {
        spacing: 8
        leftPadding: spacing
        rightPadding: spacing
        topPadding: 2
        bottomPadding: 2

        HIcon {
            svgName: "typing"  // TODO: animate
            height: typingLabel.height
        }

        HLabel {
            id: typingLabel
            text: chatPage.roomInfo.typingText
            textFormat: Text.StyledText
            elide: Text.ElideMiddle
            maximumLineCount: 1
        }
    }
}
