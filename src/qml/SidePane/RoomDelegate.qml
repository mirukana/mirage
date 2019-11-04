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


    readonly property bool invited:
        model.data.inviter_id && ! model.data.left

    readonly property var eventDate:
        model.data.last_event ? model.data.last_event.date : null


    onActivated: pageLoader.showRoom(model.user_id, model.data.room_id)


    image: HRoomAvatar {
        clientUserId: model.user_id
        displayName: model.data.display_name
        mxc: model.data.avatar_url
    }

    title.color: theme.sidePane.room.name
    title.text: model.data.display_name || "<i>Empty room</i>"
    title.textFormat: model.data.display_name? Text.PlainText : Text.StyledText

    additionalInfo.children: HIcon {
        svgName: "invite-received"
        colorize: theme.colors.alertBackground

        visible: invited
        Layout.maximumWidth: invited ? implicitWidth : 0

        Behavior on Layout.maximumWidth { HNumberAnimation {} }
    }

    rightInfo.color: theme.sidePane.room.lastEventDate
    rightInfo.text: {
        ! eventDate ?  "" :

        Utils.dateIsToday(eventDate) ?
        Utils.formatTime(eventDate, false) :  // no seconds

        eventDate.getFullYear() == new Date().getFullYear() ?
        Qt.formatDate(eventDate, "d MMM") : // e.g. "5 Dec"

        eventDate.getFullYear()
    }

    subtitle.color: theme.sidePane.room.subtitle
    subtitle.textFormat: Text.StyledText
    subtitle.text: {
        if (! model.data.last_event) { return "" }

        let ev = model.data.last_event

        // If it's an emote or non-message/media event
        if (ev.event_type === "RoomMessageEmote" ||
            (! ev.event_type.startsWith("RoomMessage") &&
             ! ev.event_type.startsWith("RoomEncrypted"))) {
            return Utils.processedEventText(ev)
        }

        let text = Utils.coloredNameHtml(
            ev.sender_name, ev.sender_id
        ) + ": " + ev.inline_content

        return text.replace(
            /< *span +class=['"]?quote['"]? *>(.+?)<\/ *span *>/g,
            '<font color="' +
            theme.sidePane.room.subtitleQuote +
            '">$1</font>',
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
