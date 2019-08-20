import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../utils.js" as Utils

HInteractiveRectangle {
    id: roomDelegate
    color: theme.sidePane.room.background
    visible: height > 0
    height: rowLayout.height
    opacity: model.data.left ? theme.sidePane.room.leftRoomOpacity : 1


    Behavior on opacity { HNumberAnimation {} }


    readonly property var delegateModel: model

    readonly property bool forceExpand:
        Boolean(accountRoomList.filter)

    readonly property bool isCurrent:
        window.uiState.page == "Chat/Chat.qml" &&
        window.uiState.pageProperties.userId == model.user_id &&
        window.uiState.pageProperties.roomId == model.data.room_id


    onIsCurrentChanged: if (isCurrent) beHighlighted()


    function beHighlighted() {
        accountRoomList.currentIndex = model.index
    }

    function activate() {
        pageLoader.showRoom(model.user_id, model.data.room_id)
    }


    // Component.onCompleted won't work for this
    Timer {
        interval: 100
        repeat: true
        running: accountRoomList.currentIndex == -1
        onTriggered: if (isCurrent) beHighlighted()
    }

    TapHandler {
        onTapped: {
            accountRoomList.highlightRangeMode = ListView.NoHighlightRange
            accountRoomList.highlightMoveDuration = 0
            activate()
            accountRoomList.highlightRangeMode = ListView.ApplyRange
            accountRoomList.highlightMoveDuration = theme.animationDuration
        }
    }

    HRowLayout {
        id: rowLayout
        property var pr: sidePane.currentSpacing
        onPrChanged: print("pr changed:", pr, spacing, x)

        spacing: sidePane.currentSpacing
        x: sidePane.currentSpacing
        width: parent.width - sidePane.currentSpacing * 1.75
        height: roomName.height + subtitle.height + sidePane.currentSpacing

        HRoomAvatar {
            id: roomAvatar
            displayName: model.data.display_name
            avatarUrl: model.data.avatar_url
        }

        HColumnLayout {
            Layout.fillWidth: true

            HRowLayout {
                spacing: rowLayout.spacing

                HLabel {
                    id: roomName
                    color: theme.sidePane.room.name
                    text: model.data.display_name || "<i>Empty room</i>"
                    textFormat:
                        model.data.display_name?
                        Text.PlainText : Text.StyledText
                    elide: Text.ElideRight
                    verticalAlignment: Qt.AlignVCenter

                    Layout.fillWidth: true
                }

                HIcon {
                    svgName: "invite-received"

                    visible: Layout.maximumWidth > 0
                    Layout.maximumWidth:
                        model.data.inviter_id && ! model.data.left ?
                        implicitWidth : 0
                    Behavior on Layout.maximumWidth { HNumberAnimation {} }
                }

                HLabel {
                    readonly property var evDate:
                        model.data.last_event ?
                        model.data.last_event.date : null

                    id: lastEventDate
                    font.pixelSize: theme.fontSize.small
                    color: theme.sidePane.room.lastEventDate

                    text: ! evDate ?  "" :

                          Utils.dateIsToday(evDate) ?
                          Utils.formatTime(evDate, false) :  // no seconds

                          evDate.getFullYear() == new Date().getFullYear() ?
                          Qt.formatDate(evDate, "d MMM") : // e.g. "5 Dec"

                          evDate.getFullYear()

                    visible: Layout.maximumWidth > 0
                    Layout.maximumWidth:
                        text && roomDelegate.width >= 200 ? implicitWidth : 0
                    Behavior on Layout.maximumWidth { HNumberAnimation {} }
                }
            }

            HRichLabel {
                id: subtitle
                color: theme.sidePane.room.subtitle
                visible: Boolean(text)
                textFormat: Text.StyledText
                font.pixelSize: theme.fontSize.small
                elide: Text.ElideRight

                text: {
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

                Layout.fillWidth: true
            }
        }
    }
}
