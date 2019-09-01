import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

Row {
    id: eventContent
    spacing: theme.spacing / 2

    readonly property string eventText: Utils.processedEventText(model)
    readonly property string eventTime: Utils.formatTime(model.date)
    readonly property int eventTimeSpaces: 2

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

            HSelectableLabel {
                id: nameLabel
                width: parent.width
                visible: ! hideNameLine
                container: selectableLabelContainer
                selectable: ! unselectableNameLine

                // This is +0.1 and content is +0 instead of the opposite,
                // because the eventList is reversed
                index: model.index + 0.1

                text: Utils.coloredNameHtml(model.sender_name, model.sender_id)
                textFormat: Text.RichText
                // elide: Text.ElideRight
                horizontalAlignment: onRight ? Text.AlignRight : Text.AlignLeft

                leftPadding: theme.spacing
                rightPadding: leftPadding
                topPadding: theme.spacing / 2

                function selectAllTextPlus() {
                    contentLabel.selectAllTextPlus()
                }
            }

            HSelectableLabel {
                id: contentLabel
                width: parent.width
                container: selectableLabelContainer
                index: model.index

                text: theme.chat.message.styleInclude +
                      eventContent.eventText +
                      // time
                      "&nbsp;".repeat(eventTimeSpaces) +
                      "<font size=" + theme.fontSize.small +
                      "px color=" + theme.chat.message.date + ">" +
                      eventTime +
                      "</font>" +
                      // local echo icon
                      (model.is_local_echo ?
                       "&nbsp;<font size=" + theme.fontSize.small +
                       "px>⏳</font>" : "")

                color: theme.chat.message.body
                wrapMode: Text.Wrap
                textFormat: Text.RichText

                leftPadding: theme.spacing
                rightPadding: leftPadding
                topPadding: nameLabel.visible ? 0 : bottomPadding
                bottomPadding: theme.spacing / 2


                function selectAllText() {
                    // Select the message body without the date or name
                    container.clearSelection()
                    contentLabel.select(
                        0,
                        contentLabel.length -
                        eventTime.length - eventTimeSpaces,
                    )
                    contentLabel.updateContainerSelectedTexts()
                }

                function selectAllTextPlus() {
                    // select the sender name, body and date
                    container.clearSelection()
                    nameLabel.selectAll()
                    contentLabel.selectAll()
                    contentLabel.updateContainerSelectedTexts()
                }

            }
        }
    }
}
