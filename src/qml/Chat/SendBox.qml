// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../Base"

HRectangle {
    function setFocus() { textArea.forceActiveFocus() }

    id: sendBox
    Layout.fillWidth: true
    Layout.minimumHeight: theme.bottomElementsHeight
    Layout.preferredHeight: textArea.implicitHeight
    // parent.height / 2 causes binding loop?
    Layout.maximumHeight: pageStack.height / 2
    color: theme.chat.sendBox.background

    HRowLayout {
        anchors.fill: parent

        HUserAvatar {
            id: avatar
            userId: chatPage.userId
            dimension: sendBox.Layout.minimumHeight
        }

        HScrollableTextArea {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.topMargin: Math.max(0, sendBox.Layout.minimumHeight - 34)

            id: textArea
            placeholderText: qsTr("Type a message...")
            backgroundColor: "transparent"
            area.focus: true

            property bool textChangedSinceLostFocus: false

            function setTyping(typing) {
                py.callClientCoro(
                    chatPage.userId,
                    "room_typing",
                    [chatPage.roomId, typing, 5000]
                )
            }

            onTextChanged: {
                setTyping(Boolean(text))
                textChangedSinceLostFocus = true
            }
            area.onEditingFinished: {  // when lost focus
                if (text && textChangedSinceLostFocus) {
                    setTyping(false)
                    textChangedSinceLostFocus = false
                }
            }

            Component.onCompleted: {
                area.Keys.onReturnPressed.connect(function (event) {
                    event.accepted = true

                    if (event.modifiers & Qt.ShiftModifier ||
                        event.modifiers & Qt.ControlModifier ||
                        event.modifiers & Qt.AltModifier) {
                        textArea.insert(textArea.cursorPosition, "\n")
                        return
                    }

                    if (textArea.text === "") { return }

                    var args = [chatPage.roomId, textArea.text]
                    py.callClientCoro(chatPage.userId, "send_markdown", args)
                    area.clear()
                })

                area.Keys.onEnterPressed.connect(area.Keys.onReturnPressed)
            }
        }
    }
}
