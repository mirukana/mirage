import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

Row {
    id: eventContent
    spacing: theme.spacing / 2

    readonly property string eventText: Utils.processedEventText(model)
    readonly property real lineHeight:
        ! eventText.match(/<img .+\/?>/) && multiline ? 1.25 : 1.0
    readonly property bool multiline:
        (eventText.match(/(\n|<br\/?>)/) || []).length > 0 ||
        contentLabel.contentWidth < (
            contentLabel.implicitWidth -
            contentLabel.leftPadding -
            contentLabel.rightPadding
        )

    Item {
        width: hideAvatar ? 0 : 48
        height: hideAvatar ? 0 : collapseAvatar ? 1 : smallAvatar ? 28 : 48
        opacity: hideAvatar || collapseAvatar ? 0 : 1
        visible: width > 0

        HUserAvatar {
            id: avatar
            userId: model.sender_id
            displayName: model.sender_name
            avatarUrl: model.sender_avatar
            width: hideAvatar ? 0 : 48
            height: hideAvatar ? 0 : collapseAvatar ? 1 : 48
        }
    }

    Rectangle {
        color: isOwn?
               theme.chat.message.ownBackground :
               theme.chat.message.background

        //width: nameLabel.implicitWidth
        width: Math.min(
            eventList.width - avatar.width - eventContent.spacing,
            theme.fontSize.normal * 0.5 * 75,  // 600 with 16px font
            Math.max(
                nameLabel.visible ? nameLabel.implicitWidth : 0,
                contentLabel.implicitWidth
            )
        )
        height: (nameLabel.visible ? nameLabel.height : 0) +
                contentLabel.implicitHeight
        y: parent.height / 2 - height / 2

        Column {
            anchors.fill: parent

            HLabel {
                id: nameLabel
                width: parent.width
                visible: ! hideNameLine

                text: Utils.coloredNameHtml(model.sender_name, model.sender_id)
                textFormat: Text.StyledText
                elide: Text.ElideRight
                horizontalAlignment: onRight ? Text.AlignRight : Text.AlignLeft
                lineHeight: eventContent.lineHeight

                leftPadding: theme.spacing
                rightPadding: leftPadding
                topPadding: theme.spacing / 2 * lineHeight
            }

            HRichLabel {
                id: contentLabel
                width: parent.width

                text: theme.chat.message.styleInclude +
                      eventContent.eventText +
                      // time
                      "&nbsp;&nbsp;<font size=" + theme.fontSize.small +
                      "px color=" + theme.chat.message.date + ">" +
                      Utils.formatTime(model.date) +
                      "</font>" +
                      // local echo icon
                      (model.is_local_echo ?
                       "&nbsp;<font size=" + theme.fontSize.small +
                       "px>⏳</font>" : "")

                lineHeight: eventContent.lineHeight
                color: theme.chat.message.body
                wrapMode: Text.Wrap

                leftPadding: theme.spacing
                rightPadding: leftPadding
                topPadding: nameLabel.visible ? 0 : bottomPadding
                bottomPadding: theme.spacing / 2 * lineHeight
            }
        }
    }
}
