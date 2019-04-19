import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4
import "../base" as Base

Rectangle {
    function setFocus() { textArea.forceActiveFocus() }

    id: "root"
    Layout.fillWidth: true
    Layout.minimumHeight: 32
    Layout.preferredHeight: textArea.implicitHeight
    // parent.height / 2 causes binding loop?
    Layout.maximumHeight: pageStack.height / 2
    color: "#BBB"

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Base.Avatar {
            id: "avatar"
            name: Backend.getUserDisplayName(chatPage.user_id)
            dimmension: root.Layout.minimumHeight
            //visible: textArea.text === ""
            visible: textArea.height <= root.Layout.minimumHeight
        }

        ScrollView {
            Layout.fillHeight: true
            Layout.fillWidth: true
            id: sendBoxScrollView
            clip: true

            TextArea {
                property string typedText: text

                id: textArea
                placeholderText: qsTr("Type a message...")
                wrapMode: TextEdit.Wrap
                selectByMouse: true
                font.family: "Roboto"
                font.pixelSize: 16
                focus: true

                function set_typing(typing) {
                    Backend.clientManager.clients[chatPage.user_id]
                           .setTypingState(chatPage.room.room_id, typing)
                }

                onTypedTextChanged: set_typing(Boolean(text))
                onEditingFinished: set_typing(false)  // when lost focus

                Keys.onReturnPressed: {
                    event.accepted = true

                    if (event.modifiers & Qt.ShiftModifier ||
                        event.modifiers & Qt.ControlModifier ||
                        event.modifiers & Qt.AltModifier) {
                        textArea.insert(textArea.cursorPosition, "\n")
                        return
                    }

                    if (textArea.text === "") { return }
                    Backend.clientManager.clients[chatPage.user_id]
                           .sendMarkdown(chatPage.room.room_id, textArea.text)
                    textArea.clear()
                }

                Keys.onEnterPressed: Keys.onReturnPressed(event)  // numpad enter
            }
        }
    }
}
