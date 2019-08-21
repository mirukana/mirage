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


    Behavior on opacity { HNumberAnimation {} }


    readonly property bool invited:
        model.data.inviter_id && ! model.data.left

    readonly property var eventDate:
        model.data.last_event ? model.data.last_event.date : null


    onActivated: pageLoader.showRoom(model.user_id, model.data.room_id)


    image: HRoomAvatar {
        displayName: model.data.display_name
        avatarUrl: model.data.avatar_url
    }

    title.color: theme.sidePane.room.name
    title.text: model.data.display_name || "<i>Empty room</i>"
    title.textFormat: model.data.display_name? Text.PlainText : Text.StyledText

    additionalInfo.children: HIcon {
        svgName: "invite-received"

        visible: Layout.maximumWidth > 0
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

        if (ev.event_type === "RoomMessageEmote" ||
            ! ev.event_type.startsWith("RoomMessage")) {
            return Utils.processedEventText(ev)
        }

        return Utils.coloredNameHtml(
            ev.sender_name, ev.sender_id
        ) + ": " + ev.inline_content
    }

    contextMenu: HMenu {
        HMenuItem {
            icon.name: invited ? "invite-decline" : "room-leave"
            text: invited ? qsTr("Decline invite") : qsTr("Leave")
            onTriggered: py.callClientCoro(
                model.user_id, "room_leave", [model.data.room_id]
            )
        }
    }
}
