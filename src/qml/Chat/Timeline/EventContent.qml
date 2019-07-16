// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

Row {
    id: messageContent
    spacing: standardSpacing / 2
    layoutDirection: isOwn ? Qt.RightToLeft : Qt.LeftToRight

    HUserAvatar {
        id: avatar
        userId: model.senderId
        width: model.showNameLine ? 48 : 28
        height: combine ? 1 : model.showNameLine ? 48 : 28
        opacity: combine ? 0 : 1
        visible: ! isOwn
    }

    Rectangle {
        color: isOwn?
               theme.chat.message.ownBackground :
               theme.chat.message.background

        //width: nameLabel.implicitWidth
        width: Math.min(
            eventList.width - avatar.width - messageContent.spacing,
            theme.fontSize.normal * 0.5 * 75,  // 600 with 16px font
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
                height: model.showNameLine && ! isOwn && ! combine ?
                        implicitHeight : 0
                visible: height > 0

                id: nameLabel
                text: senderInfo.displayName || model.senderId
                color: Utils.nameColor(avatar.name)
                elide: Text.ElideRight
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
                      "&nbsp;&nbsp;<font size=" + theme.fontSize.small +
                      "px color=" + theme.chat.message.date + ">" +
                      Qt.formatDateTime(model.date, "hh:mm:ss") +
                      "</font>" +
                      // local echo icon
                      (model.isLocalEcho ?
                       "&nbsp;<font size=" + theme.fontSize.small +
                       "px>⏳</font>" : "")

                color: theme.chat.message.body
                wrapMode: Text.Wrap

                leftPadding: horizontalPadding
                rightPadding: horizontalPadding
                topPadding: nameLabel.visible ? 0 : verticalPadding
                bottomPadding: verticalPadding
            }
        }
    }
}
