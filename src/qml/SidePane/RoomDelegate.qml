// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Layouts 1.3
import "../Base"
import "../utils.js" as Utils

HHighlightRectangle {
    id: roomDelegate
    width: roomList.width
    height: childrenRect.height

    TapHandler {
        onTapped: pageStack.showRoom(
            roomList.userId, roomList.category, model.roomId
        )
    }

    Row {
        width: parent.width - sidePane.currentSpacing * 2
        padding: sidePane.currentSpacing / 2
        leftPadding: sidePane.currentSpacing
        rightPadding: 0

        HRowLayout {
            width: parent.width
            spacing: sidePane.currentSpacing

            HRoomAvatar {
                id: roomAvatar
                roomId: model.roomId
            }

            HColumnLayout {
                Layout.fillWidth: true
                Layout.maximumWidth:
                    parent.width - parent.totalSpacing - roomAvatar.width

                HLabel {
                    id: roomLabel
                    text: model.displayName || "<i>Empty room</i>"
                    textFormat:
                        model.displayName? Text.PlainText : Text.StyledText
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    verticalAlignment: Qt.AlignVCenter

                    Layout.maximumWidth: parent.width
                }

                HRichLabel {
                    function getText(ev) {
                        if (! ev) { return "" }

                        if (! Utils.eventIsMessage(ev)) {
                            return Utils.translatedEventContent(ev)
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
                    visible: Boolean(text)
                    textFormat: Text.StyledText

                    font.pixelSize: theme.fontSize.small
                    elide: Text.ElideRight
                    maximumLineCount: 1

                    Layout.maximumWidth: parent.width
                }
            }
        }
    }
}
