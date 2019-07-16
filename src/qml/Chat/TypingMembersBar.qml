// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HRectangle {
    id: typingMembersBar

    property alias label: typingLabel

    color: theme.chat.typingMembers.background
    implicitHeight: typingLabel.text ? typingLabel.height : 0

    Behavior on implicitHeight { HNumberAnimation {} }

    HRowLayout {
        spacing: 8
        anchors.fill: parent
        Layout.leftMargin: spacing
        Layout.rightMargin: spacing
        Layout.topMargin: 2
        Layout.bottomMargin: 2

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

            Layout.fillWidth: true
        }
    }
}
