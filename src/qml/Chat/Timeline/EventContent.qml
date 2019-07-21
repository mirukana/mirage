// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

Row {
    id: eventContent
    spacing: theme.spacing / 2
    // layoutDirection: onRight ? Qt.RightToLeft : Qt.LeftToRight

    Item {
        width: hideAvatar ? 0 : 48
        height: hideAvatar ? 0 : collapseAvatar ? 1 : smallAvatar ? 28 : 48
        opacity: hideAvatar || collapseAvatar ? 0 : 1
        visible: width > 0

        HUserAvatar {
            id: avatar
            userId: model.senderId
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
            spacing: 0
            anchors.fill: parent

            HLabel {
                id: nameLabel
                width: parent.width
                visible: ! hideNameLine

                text: senderInfo.displayName || model.senderId
                color: Utils.nameColor(avatar.name)
                elide: Text.ElideRight
                horizontalAlignment: onRight ? Text.AlignRight : Text.AlignLeft

                leftPadding: theme.spacing
                rightPadding: leftPadding
                topPadding: theme.spacing / 2
            }

            HRichLabel {
                id: contentLabel
                width: parent.width

                Component.onCompleted: print(text, "\n")
                text: theme.chat.message.styleInclude +
                      Utils.processedEventText(model) +
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

                leftPadding: theme.spacing
                rightPadding: leftPadding
                topPadding: nameLabel.visible ? 0 : bottomPadding
                bottomPadding: theme.spacing / 2
            }
        }
    }
}
