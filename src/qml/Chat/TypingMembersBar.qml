// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HRectangle {
    id: typingMembersBar

    property alias label: typingLabel

    color: theme.chat.typingMembers.background
    implicitWidth: childrenRect.width
    implicitHeight: typingLabel.text ? childrenRect.height : 0

    Behavior on implicitHeight { HNumberAnimation {} }

    Row {
        spacing: 8
        leftPadding: spacing
        rightPadding: spacing
        topPadding: 2
        bottomPadding: 2

        HIcon {
            id: icon
            svgName: "typing"  // TODO: animate
            height: typingLabel.height
        }

        HLabel {
            id: typingLabel
            text: chatPage.roomInfo.typingText
            textFormat: Text.StyledText
            elide: Text.ElideRight
            maximumLineCount: 1
            width: typingMembersBar.width - icon.width -
                   parent.spacing - parent.leftPadding - parent.rightPadding
        }
    }
}
