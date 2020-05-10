// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

Rectangle {
    implicitHeight: theme.baseElementsHeight
    color: theme.chat.roomHeader.background


    readonly property bool showPaneButtons: mainUI.mainPane.collapse

    readonly property bool center:
        showPaneButtons || window.settings.alwaysCenterRoomHeader


    HRowLayout {
        id: row
        anchors.fill: parent
        visible: opacity > 0

        // The layout overflows somehow when focusing the room pane and
        // is visible behind it (with a transparent theme)
        opacity: showPaneButtons && chat.roomPane.visible ? 0 : 1

        Behavior on opacity { HNumberAnimation {} }

        HButton {
            id: goToMainPaneButton
            padded: false
            visible: Layout.preferredWidth > 0
            backgroundColor: "transparent"
            icon.name: "go-back-to-main-pane"
            toolTip.text: qsTr("Go back to main pane")

            onClicked: mainUI.mainPane.filterRoomsField.toggleFocus()

            Layout.preferredWidth: showPaneButtons ? avatar.width : 0
            Layout.fillHeight: true

            Behavior on Layout.preferredWidth { HNumberAnimation {} }
        }

        HSpacer {
            visible: center
        }

        HRoomAvatar {
            id: avatar
            roomId: chat.roomId
            displayName: chat.roomInfo.display_name
            mxc: chat.roomInfo.avatar_url
            radius: 0

            Layout.alignment: Qt.AlignTop
        }

        HLabel {
            id: nameLabel
            text: chat.roomInfo.display_name || qsTr("Empty room")
            color: theme.chat.roomHeader.name

            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            leftPadding: theme.spacing
            rightPadding: leftPadding

            Layout.preferredWidth: Math.min(
                implicitWidth,
                row.width -
                row.spacing * (showPaneButtons ? 3 : 1) -
                goToMainPaneButton.width -
                avatar.width -
                goToRoomPaneButton.width
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

            Layout.preferredWidth: Math.min(
                implicitWidth,
                row.width -
                row.spacing * (showPaneButtons ? 3 : 1) -
                goToMainPaneButton.width -
                avatar.width -
                nameLabel.width -
                goToRoomPaneButton.width
            )
            Layout.fillWidth: ! center
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

        HSpacer {
            visible: center
        }

        HButton {
            id: goToRoomPaneButton
            padded: false
            visible: goToMainPaneButton.visible
            backgroundColor: "transparent"
            icon.name: "go-to-room-pane"
            toolTip.text: qsTr("Go to room pane")

            onClicked: chat.roomPane.toggleFocus()

            Layout.preferredWidth: goToMainPaneButton.Layout.preferredWidth
            Layout.fillHeight: true
        }
    }
}
