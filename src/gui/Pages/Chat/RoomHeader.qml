// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

Rectangle {
    id: root

    readonly property bool center:
        goToMainPaneButton.show || window.settings.Chat.always_center_header

    readonly property HListView eventList: chatPage.eventList.eventList
    readonly property int selected:
        eventList.selectedCount === 1 && eventList.selectedText ?
        0 :
        eventList.selectedCount

    implicitHeight: theme.baseElementsHeight
    color: theme.chat.roomHeader.background

    HRowLayout {
        id: row
        anchors.fill: parent

        RoomHeaderButton {
            id: goToMainPaneButton
            show: mainUI.mainPane.normalOrForceCollapse
            padded: false
            backgroundColor: "transparent"
            icon.name: "go-back-to-main-pane"
            toolTip.text: qsTr("Back to main pane")
            onClicked: mainUI.mainPane.toggleFocus()

            Layout.preferredWidth: show ? avatar.width : 0
        }

        HSpacer {
            visible: root.center
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
            id: mainLabel

            text:
                root.selected === 0 ?
                chat.roomInfo.display_name || qsTr("Empty room") :
                root.selected === 1 ?
                qsTr("%1 selected message").arg(root.selected) :
                qsTr("%1 selected messages").arg(root.selected)

            color: theme.chat.roomHeader.name
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            leftPadding: theme.spacing
            rightPadding: leftPadding

            // FIXME: these dirty manual calculations
            Layout.preferredWidth: Math.min(
                implicitWidth,
                row.width -
                goToMainPaneButton.width -
                avatar.width -
                encryptionStatusButton.width -
                copyButton.width -
                removeButton.width -
                deselectButton.width -
                goToRoomPaneButton.width
            )
            Layout.fillWidth: ! topicLabel.text
            Layout.fillHeight: true

            HoverHandler { id: nameHover }
        }

        HLabel {
            id: topicLabel
            text: root.selected ? "" : chat.roomInfo.topic
            textFormat: Text.StyledText
            font.pixelSize: theme.fontSize.small
            color: theme.chat.roomHeader.topic

            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            rightPadding: mainLabel.rightPadding

            Layout.preferredWidth: ! text ? 0 : Math.min(
                implicitWidth,
                row.width -
                goToMainPaneButton.width -
                avatar.width -
                mainLabel.width -
                encryptionStatusButton.width -
                copyButton.width -
                removeButton.width -
                deselectButton.width -
                goToRoomPaneButton.width
            )

            Layout.fillWidth: text && ! root.center
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
                mainLabel.truncated ?
                (`<b>${chat.roomInfo.display_name}</b>`) : ""

            readonly property string topic:
                topicLabel.truncated ?  chat.roomInfo.topic : ""

            visible: text && (nameHover.hovered || topicHover.hovered)
            label.textFormat: Text.StyledText
            text: name && topic ? (`${name}<br>${topic}`) : (name || topic)
        }

        RoomHeaderButton {
            id: encryptionStatusButton
            show: chat.roomInfo.encrypted && ! root.selected
            padded: false
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

            Layout.preferredWidth: show ? avatar.width : 0
            Layout.fillHeight: true
        }

        RoomHeaderButton {
            id: copyButton
            show: root.selected
            icon.name: "room-header-copy"
            toolTip.text: qsTr("Copy messages")
            toolTip.onClosed: toolTip.text = qsTr("Copy messages")

            onClicked: {
                root.eventList.copySelectedDelegates()
                toolTip.text = qsTr("Copied messages")
                toolTip.instantShow(2000)
            }
        }

        RoomHeaderButton {
            id: removeButton

            readonly property var events:
                root.eventList.redactableCheckedEvents

            show: root.selected
            enabled: events.length > 0
            icon.name: "room-header-remove"
            toolTip.text: qsTr("Remove messages")

            onClicked: utils.makePopup(
                "Popups/RedactPopup.qml",
                window,
                {
                    preferUserId: chat.userId,
                    roomId: chat.roomId,
                    eventSenderAndIds: events.map(ev => [ev.sender_id, ev.id]),
                    onlyOwnMessageWarning:
                        ! chat.roomInfo.can_redact_all &&
                        events.length < root.selected
                },
            )
        }

        RoomHeaderButton {
            id: deselectButton
            show: root.selected
            icon.name: "room-header-deselect"
            toolTip.text: qsTr("Deselect messages")
            onClicked: root.eventList.checked = []
        }

        HSpacer {
            visible: root.center
        }

        RoomHeaderButton {
            id: goToRoomPaneButton
            show: chat.roomPane && chat.roomPane.normalOrForceCollapse

            padded: false
            backgroundColor: "transparent"
            icon.name: "go-to-room-pane"
            toolTip.text: qsTr("Go to room pane")
            onClicked: chat.roomPane.toggleFocus()

            Layout.preferredWidth: show ? avatar.width : 0
        }
    }
}
