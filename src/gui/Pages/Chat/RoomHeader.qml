// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

Rectangle {
    readonly property bool showLeftButton:
        mainUI.mainPane.collapse || mainUI.mainPane.forceCollapse

    readonly property bool showRightButton:
        chat.roomPane &&
        (chat.roomPane.collapse || chat.roomPane.forceCollapse)

    readonly property bool center:
        showLeftButton || window.settings.Chat.always_center_header

    implicitHeight: theme.baseElementsHeight
    color: theme.chat.roomHeader.background

    HRowLayout {
        id: row
        anchors.fill: parent

        HButton {
            id: goToMainPaneButton
            padded: false
            visible: Layout.preferredWidth > 0
            backgroundColor: "transparent"
            icon.name: "go-back-to-main-pane"
            toolTip.text: qsTr("Go back to main pane")

            onClicked: mainUI.mainPane.toggleFocus()

            Layout.preferredWidth: showLeftButton ? avatar.width : 0
            Layout.fillHeight: true

            Behavior on Layout.preferredWidth { HNumberAnimation {} }
        }

        HSpacer {
            visible: center
        }

        HRoomAvatar {
            id: avatar
            clientUserId: chat.userId
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
                row.spacing -
                (showLeftButton ? row.spacing : 0) -
                (showRightButton ? row.spacing : 0) -
                goToMainPaneButton.width -
                avatar.width -
                encryptionStatusButton.width -
                goToRoomPaneButton.width
            )
            Layout.fillHeight: true

            HoverHandler { id: nameHover }
        }

        HLabel {
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
                row.spacing -
                (showLeftButton ? row.spacing : 0) -
                (showRightButton ? row.spacing : 0) -
                goToMainPaneButton.width -
                avatar.width -
                nameLabel.width -
                encryptionStatusButton.width -
                goToRoomPaneButton.width
            )
            Layout.fillWidth: ! center
            Layout.fillHeight: true

            HoverHandler { id: topicHover }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                cursorShape:
                    parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }

        HToolTip {
            readonly property string name:
                nameLabel.truncated ?
                (`<b>${chat.roomInfo.display_name}</b>`) : ""

            readonly property string topic:
                topicLabel.truncated ?  chat.roomInfo.topic : ""

            visible: text && (nameHover.hovered || topicHover.hovered)
            label.textFormat: Text.StyledText
            text: name && topic ? (`${name}<br>${topic}`) : (name || topic)
        }

        HButton {
            id: encryptionStatusButton
            padded: false
            visible: Layout.preferredWidth > 0
            backgroundColor: "transparent"

            icon.name:
                chat.roomInfo.unverified_devices ?
                "device-unset" :
                "device-verified"

            icon.color:
                chat.roomInfo.unverified_devices ?
                theme.colors.middleBackground :
                theme.colors.positiveBackground

            toolTip.text:
                chat.roomInfo.unverified_devices ?
                qsTr("Some members in this encrypted room have " +
                     "unverified devices") :
                qsTr("All members in this encrypted room are verified")

            onClicked: toolTip.instantToggle()

            Layout.preferredWidth: chat.roomInfo.encrypted ? avatar.width : 0
            Layout.fillHeight: true

            Behavior on Layout.preferredWidth { HNumberAnimation {} }
        }

        HSpacer {
            visible: center
        }

        HButton {
            id: goToRoomPaneButton
            padded: false
            visible: Layout.preferredWidth > 0
            backgroundColor: "transparent"
            icon.name: "go-to-room-pane"
            toolTip.text: qsTr("Go to room pane")

            onClicked: chat.roomPane.toggleFocus()

            Layout.preferredWidth: showRightButton ? avatar.width : 0
            Layout.fillHeight: true
        }
    }
}
