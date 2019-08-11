import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../utils.js" as Utils

HInteractiveRectangle {
    id: roomDelegate
    width: roomList.width
    height: childrenRect.height
    color: theme.sidePane.room.background

    TapHandler { onTapped: pageStack.showRoom(userId, model.room_id) }

    Row {
        width: parent.width - leftPadding * 2
        padding: sidePane.currentSpacing / 2
        leftPadding: sidePane.currentSpacing
        rightPadding: 0

        HRowLayout {
            width: parent.width
            spacing: sidePane.currentSpacing

            HRoomAvatar {
                id: roomAvatar
                displayName: model.display_name
                avatarUrl: model.avatar_url
            }

            HColumnLayout {
                Layout.fillWidth: true

                HLabel {
                    id: roomLabel
                    color: theme.sidePane.room.name
                    text: model.display_name || "<i>Empty room</i>"
                    textFormat:
                        model.display_name? Text.PlainText : Text.StyledText
                    elide: Text.ElideRight
                    verticalAlignment: Qt.AlignVCenter

                    Layout.fillWidth: true
                }

                HRichLabel {
                    id: subtitleLabel
                    color: theme.sidePane.room.subtitle
                    visible: Boolean(text)
                    textFormat: Text.StyledText

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


                    font.pixelSize: theme.fontSize.small
                    elide: Text.ElideRight

                    Layout.fillWidth: true
                }
            }
        }
    }
}
