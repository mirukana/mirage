// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

Rectangle {
    implicitHeight: theme.baseElementsHeight
    color: theme.chat.roomHeader.background

    HRowLayout {
        id: row
        anchors.fill: parent

        HRoomAvatar {
            id: avatar
            roomId: chat.roomId
            displayName: chat.roomInfo.display_name
            mxc: chat.roomInfo.avatar_url
            Layout.alignment: Qt.AlignTop
        }

        HLabel {
            id: nameLabel
            text: chat.roomInfo.display_name || qsTr("Empty room")
            font.pixelSize: theme.fontSize.big
            color: theme.chat.roomHeader.name

            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            leftPadding: theme.spacing
            rightPadding: leftPadding

            Layout.preferredWidth: Math.min(
                implicitWidth, row.width - row.spacing - avatar.width
            )
            Layout.fillHeight: true

            HoverHandler { id: nameHover }
        }

        HRichLabel {
            id: topicLabel
            text: chat.roomInfo.topic
            textFormat: Text.StyledText
            font.pixelSize: theme.fontSize.small
            color: theme.chat.roomHeader.topic

            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            rightPadding: nameLabel.rightPadding

            Layout.fillWidth: true
            Layout.fillHeight: true

            HoverHandler { id: topicHover }
        }

        HToolTip {
            visible: text && (nameHover.hovered || topicHover.hovered)
            label.textFormat: Text.StyledText
            text: name && topic ? (`${name}<br>${topic}`) : (name || topic)

            readonly property string name:
                nameLabel.truncated ?
                (`<b>${chat.roomInfo.display_name}</b>`) : ""

            readonly property string topic:
                topicLabel.truncated ?  chat.roomInfo.topic : ""
        }
    }
}
