import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.4

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

        Avatar {
            id: "avatar"
            username: Backend.getUser(chatPage.room.account_id).display_name
            dimmension: root.Layout.minimumHeight
            visible: textArea.text === ""
        }

        ScrollView {
            Layout.fillHeight: true
            Layout.fillWidth: true
            id: sendBoxScrollView
            clip: true

            TextArea {
                id: textArea
                placeholderText: qsTr("Type a message...")
                wrapMode: TextEdit.Wrap
                selectByMouse: true
                font.family: "Roboto"
                font.pixelSize: 16
                focus: true

                Keys.onReturnPressed: {
                    event.accepted = true

                    if (event.modifiers & Qt.ShiftModifier ||
                        event.modifiers & Qt.ControlModifier ||
                        event.modifiers & Qt.AltModifier) {
                        textArea.insert(textArea.cursorPosition, "\n")
                        return
                    }

                    Backend.sendMessage(chatPage.room.account_id,
                                        chatPage.room.room_id,
                                        textArea.text)
                    textArea.clear()
                }
                Keys.onEnterPressed: Keys.onReturnPressed(event)  // numpad enter
            }
        }
    }
}
