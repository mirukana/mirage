// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../utils.js" as Utils

HInteractiveRectangle {
    id: roomDelegate
    width: roomList.width
    height: childrenRect.height
    color: theme.sidePane.room.background

    TapHandler {
        onTapped: pageStack.showRoom(
            roomList.userId, roomList.category, model.roomId
        )
    }

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
                userId: model.userId
                roomId: model.roomId
            }

            HColumnLayout {
                Layout.fillWidth: true

                HLabel {
                    id: roomLabel
                    color: theme.sidePane.room.name
                    text: model.displayName || "<i>Empty room</i>"
                    textFormat:
                        model.displayName? Text.PlainText : Text.StyledText
                    elide: Text.ElideRight
                    verticalAlignment: Qt.AlignVCenter

                    Layout.fillWidth: true
                }

                HRichLabel {
                    function getText(ev) {
                        if (! ev) { return "" }

                        if (ev.eventType == "RoomMessageEmote" ||
                            ! ev.eventType.startsWith("RoomMessage"))
                        {
                            return Utils.processedEventText(ev)
                        }

                        return Utils.coloredNameHtml(
                            users.find(ev.senderId).displayName,
                            ev.senderId
                        ) + ": " + py.callSync("inlinify", [ev.content])
                    }

                    // Have to do it like this to avoid binding loop
                    property var lastEv: timelines.lastEventOf(model.roomId)
                    onLastEvChanged: text = getText(lastEv)

                    id: subtitleLabel
                    color: theme.sidePane.room.subtitle
                    visible: Boolean(text)
                    textFormat: Text.StyledText

                    font.pixelSize: theme.fontSize.small
                    elide: Text.ElideRight

                    Layout.fillWidth: true
                }
            }
        }
    }
}
