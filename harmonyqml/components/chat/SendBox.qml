import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "../base" as Base

Base.HGlassRectangle {
    function setFocus() { textArea.forceActiveFocus() }

    id: root
    Layout.fillWidth: true
    Layout.minimumHeight: 32
    Layout.preferredHeight: textArea.implicitHeight
    // parent.height / 2 causes binding loop?
    Layout.maximumHeight: pageStack.height / 2
    color: Base.HStyle.chat.sendBox.background

    Base.HRowLayout {
        anchors.fill: parent
        spacing: 0

        Base.HAvatar {
            id: avatar
            name: Backend.getUserDisplayName(chatPage.userId)
            dimension: root.Layout.minimumHeight
        }

        Base.HScrollableTextArea {
            Layout.fillHeight: true
            Layout.fillWidth: true

            id: textArea
            placeholderText: qsTr("Type a message...")
            area.focus: true

            function setTyping(typing) {
                Backend.clientManager.clients[chatPage.userId]
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
                Backend.clientManager.clients[chatPage.userId]
                       .sendMarkdown(chatPage.roomId, textArea.text)
                textArea.clear()
            }

            Keys.onEnterPressed: Keys.onReturnPressed(event)  // numpad enter
        }
    }
}
