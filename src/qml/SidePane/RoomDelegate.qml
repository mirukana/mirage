import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../utils.js" as Utils

HTileDelegate {
    id: roomDelegate
    spacing: sidePane.currentSpacing
    backgroundColor: theme.sidePane.room.background
    opacity: model.data.left ? theme.sidePane.room.leftRoomOpacity : 1

    shouldBeCurrent:
        window.uiState.page == "Chat/Chat.qml" &&
        window.uiState.pageProperties.userId == model.user_id &&
        window.uiState.pageProperties.roomId == model.data.room_id

    setCurrentTimer.running:
        ! sidePaneList.activateLimiter.running && ! sidePane.hasFocus


    Behavior on opacity { HNumberAnimation {} }


    readonly property bool invited: model.data.inviter_id && ! model.data.left
    readonly property var lastEvent: model.data.last_event


    onActivated: pageLoader.showRoom(model.user_id, model.data.room_id)


    image: HRoomAvatar {
        displayName: model.data.display_name
        mxc: model.data.avatar_url
    }

    title.color: theme.sidePane.room.name
    title.text: model.data.display_name || qsTr("Empty room")

    additionalInfo.children: HIcon {
        svgName: "invite-received"
        colorize: theme.colors.alertBackground

        visible: invited
        Layout.maximumWidth: invited ? implicitWidth : 0

        Behavior on Layout.maximumWidth { HNumberAnimation {} }
    }

    rightInfo.color: theme.sidePane.room.lastEventDate
    rightInfo.text: {
        ! lastEvent || ! lastEvent.date ?
        "" :

        Utils.dateIsToday(lastEvent.date) ?
        Utils.formatTime(lastEvent.date, false) :  // no seconds

        lastEvent.date.getFullYear() == new Date().getFullYear() ?
        Qt.formatDate(lastEvent.date, "d MMM") : // e.g. "5 Dec"

        lastEvent.date.getFullYear()
    }

    subtitle.color: theme.sidePane.room.subtitle
    subtitle.font.italic:
        Boolean(lastEvent && lastEvent.event_type === "RoomMessageEmote")
    subtitle.textFormat: Text.StyledText
    subtitle.text: {
        if (! lastEvent) return ""

        // If it's an emote or non-message/media event
        if (lastEvent.event_type === "RoomMessageEmote" ||
            (! lastEvent.event_type.startsWith("RoomMessage") &&
            ! lastEvent.event_type.startsWith("RoomEncrypted")))
        {
            return Utils.processedEventText(lastEvent)
        }

        let text = Utils.coloredNameHtml(
            lastEvent.sender_name, lastEvent.sender_id
        ) + ": " + lastEvent.inline_content

        return text.replace(
            /< *span +class=['"]?quote['"]? *>(.+?)<\/ *span *>/g,
            `<font color="${theme.sidePane.room.subtitleQuote}">$1</font>`,
        )
    }

    contextMenu: HMenu {
        HMenuItem {
            visible: invited
            icon.name: "invite-accept"
            icon.color: theme.colors.positiveBackground
            text: qsTr("Accept %1's invite").arg(Utils.coloredNameHtml(
                model.data.inviter_name, model.data.inviter_id
            ))
            label.textFormat: Text.StyledText

            onTriggered: py.callClientCoro(
                model.user_id, "join", [model.data.room_id]
            )
        }

        HMenuItem {
            visible: ! model.data.left
            icon.name: invited ? "invite-decline" : "room-leave"
            icon.color: theme.colors.negativeBackground
            text: invited ? qsTr("Decline invite") : qsTr("Leave")

            onTriggered: Utils.makePopup(
                "Popups/LeaveRoomPopup.qml",
                sidePane,
                {
                    userId: model.user_id,
                    roomId: model.data.room_id,
                    roomName: model.data.display_name,
                }
            )
        }

        HMenuItem {
            icon.name: "room-forget"
            icon.color: theme.colors.negativeBackground
            text: qsTr("Forget")

            onTriggered: Utils.makePopup(
                "Popups/ForgetRoomPopup.qml",
                sidePane,
                {
                    userId: model.user_id,
                    roomId: model.data.room_id,
                    roomName: model.data.display_name,
                },
                null,
                false,
            )
        }
    }
}
