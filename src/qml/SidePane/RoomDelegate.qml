import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../utils.js" as Utils

HInteractiveRectangle {
    id: roomDelegate
    width: roomList.width
    height: rowLayout.height
    color: theme.sidePane.room.background

    opacity: model.left ? theme.sidePane.room.leftRoomOpacity : 1
    Behavior on opacity { HNumberAnimation {} }

    TapHandler { onTapped: pageStack.showRoom(userId, model.room_id) }

    HRowLayout {
        id: rowLayout
        x: sidePane.currentSpacing
        width: parent.width - sidePane.currentSpacing * 1.5
        height: roomName.height + subtitle.height +
                sidePane.currentSpacing
        spacing: sidePane.currentSpacing

        HRoomAvatar {
            id: roomAvatar
            displayName: model.display_name
            avatarUrl: model.avatar_url
        }

        HColumnLayout {
            Layout.fillWidth: true

            HRowLayout {
                spacing: theme.spacing / 2

                HLabel {
                    id: roomName
                    color: theme.sidePane.room.name
                    text: model.display_name || "<i>Empty room</i>"
                    textFormat:
                        model.display_name? Text.PlainText : Text.StyledText
                    elide: Text.ElideRight
                    verticalAlignment: Qt.AlignVCenter

                    Layout.fillWidth: true
                }

                HIcon {
                    svgName: "invite-received"

                    visible: Layout.maximumWidth > 0
                    Layout.maximumWidth:
                        model.inviter_id && ! model.left ? implicitWidth : 0
                    Behavior on Layout.maximumWidth { HNumberAnimation {} }
                }

                HLabel {
                    readonly property var evDate:
                        model.last_event ? model.last_event.date : null

                    id: lastEventDate
                    font.pixelSize: theme.fontSize.small
                    color: theme.sidePane.room.lastEventDate

                    text: ! evDate ?  "" :

                          Utils.dateIsToday(evDate) ?
                          Utils.formatTime(evDate, false) :  // no seconds

                          Utils.dateIsYesterday(evDate) ? qsTr("Yesterday") :

                          evDate.getFullYear() == new Date().getFullYear() ?
                          Qt.formatDate(evDate, "dd MMM") : // e.g. "24 Nov"

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
                    if (! model.last_event) { return "" }

                    let ev = model.last_event

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
