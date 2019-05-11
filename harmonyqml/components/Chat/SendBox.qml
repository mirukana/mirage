import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../Base"

HGlassRectangle {
    function setFocus() { textArea.forceActiveFocus() }

    id: root
    Layout.fillWidth: true
    Layout.minimumHeight: 32
    Layout.preferredHeight: textArea.implicitHeight
    // parent.height / 2 causes binding loop?
    Layout.maximumHeight: pageStack.height / 2
    color: HStyle.chat.sendBox.background

    HRowLayout {
        anchors.fill: parent

        HAvatar {
            id: avatar
            name: chatPage.sender.displayName.value
            dimension: root.Layout.minimumHeight
        }

        HScrollableTextArea {
            Layout.fillHeight: true
            Layout.fillWidth: true

            id: textArea
            placeholderText: qsTr("Type a message...")
            backgroundColor: "transparent"
            area.focus: true

            function setTyping(typing) {
                Backend.clients.get(chatPage.userId)
                       .setTypingState(chatPage.roomId, typing)
            }

            onTextChanged: setTyping(Boolean(text))
            area.onEditingFinished: setTyping(false)  // when lost focus

            Keys.onReturnPressed: {
                event.accepted = true

                if (event.modifiers & Qt.ShiftModifier ||
                    event.modifiers & Qt.ControlModifier ||
                    event.modifiers & Qt.AltModifier) {
                    textArea.insert(textArea.cursorPosition, "\n")
                    return
                }

                if (textArea.text === "") { return }
                Backend.clients.get(chatPage.userId)
                       .sendMarkdown(chatPage.roomId, textArea.text)
                area.clear()
            }

            // Numpad enter
            Keys.onEnterPressed: Keys.onReturnPressed(event)
        }
    }
}
