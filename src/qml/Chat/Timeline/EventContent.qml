import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../../Base"
import "../../utils.js" as Utils

Row {
    id: messageContent
    spacing: standardSpacing / 2
    layoutDirection: isOwn ? Qt.RightToLeft : Qt.LeftToRight

    HAvatar {
        id: avatar
        hidden: combine
        name: senderInfo.displayName || Utils.stripUserId(model.senderId)
        dimension: model.showNameLine ? 48 : 28
    }

    Rectangle {
        color: Utils.eventIsMessage(model) ?
               HStyle.chat.message.background : HStyle.chat.event.background

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
                width: parent.width
                height: model.showNameLine && ! combine ? implicitHeight : 0
                visible: height > 0

                id: nameLabel
                text: senderInfo.displayName || model.senderId
                color: Utils.nameHue(avatar.name)
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
                text: Utils.translatedEventContent(model) +
                      // time
                      "&nbsp;&nbsp;<font size=" + HStyle.fontSize.small +
                      "px color=" + HStyle.chat.message.date + ">" +
                      Qt.formatDateTime(model.date, "hh:mm:ss") +
                      "</font>" +
                      // local echo icon
                      (model.isLocalEcho ?
                       "&nbsp;<font size=" + HStyle.fontSize.small +
                       "px>⏳</font>" : "")

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
