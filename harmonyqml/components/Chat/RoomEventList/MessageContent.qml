import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../../Base"

Row {
    id: messageContent
    spacing: standardSpacing / 2
    layoutDirection: isOwn ? Qt.RightToLeft : Qt.LeftToRight

    HAvatar {
        id: avatar
        hidden: combine
        name: displayName
    }

    Rectangle {
        color: HStyle.chat.message.background

        //width: nameLabel.implicitWidth
        width: Math.min(
            roomEventListView.width - avatar.width - messageContent.spacing,
            HStyle.fontSize.normal * 0.5 * 75,  // 600 with 16px font
            Math.max(
                nameLabel.visible ? nameLabel.implicitWidth : 0,
                contentLabel.implicitWidth
            )
        )
        height: nameLabel.height + contentLabel.implicitHeight

        Column {
            spacing: 0
            anchors.fill: parent

            HLabel {
                height: combine ? 0 : implicitHeight
                width: parent.width
                visible: height > 0

                id: nameLabel
                text: displayName.value || dict.sender
                color: Qt.hsla(Backend.hueFromString(text),
                               HStyle.displayName.saturation,
                               HStyle.displayName.lightness,
                               1)
                elide: Text.ElideRight
                maximumLineCount: 1
                horizontalAlignment: isOwn ? Text.AlignRight : Text.AlignLeft

                leftPadding: horizontalPadding
                rightPadding: horizontalPadding
                topPadding: verticalPadding
            }

            HRichLabel {
                width: parent.width

                id: contentLabel
                text: (dict.formatted_body ?
                       Backend.htmlFilter.filter(dict.formatted_body) :
                       dict.body) +
                      "&nbsp;&nbsp;<font size=" + HStyle.fontSize.small +
                      "px color=" + HStyle.chat.message.date + ">" +
                      Qt.formatDateTime(dateTime, "hh:mm:ss") +
                      "</font>" +
                      (isLocalEcho ?
                       "&nbsp;<font size=" + HStyle.fontSize.small +
                       "px>⏳</font>" : "")
                textFormat: Text.RichText
                color: HStyle.chat.message.body
                wrapMode: Text.Wrap

                leftPadding: horizontalPadding
                rightPadding: horizontalPadding
                topPadding: nameLabel.visible ? 0 : verticalPadding
                bottomPadding: verticalPadding
            }
        }
    }
}
