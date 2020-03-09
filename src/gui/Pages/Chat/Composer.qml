// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import Clipboard 0.1
import CppUtils 0.1
import "../.."
import "../../Base"
import "../../Dialogs"

Rectangle {
    id: composer
    color: theme.chat.composer.background

    Layout.fillWidth: true
    Layout.minimumHeight: theme.baseElementsHeight
    Layout.preferredHeight: areaScrollView.implicitHeight
    Layout.maximumHeight: pageLoader.height / 2


    property string indent: "    "

    property var aliases: window.settings.writeAliases
    property string toSend: ""

    property string writingUserId: chat.userId
    property QtObject writingUserInfo:
        ModelStore.get("accounts").find(writingUserId)

    property bool textChangedSinceLostFocus: false

    property alias textArea: areaScrollView.area

    readonly property int cursorPosition:
        textArea.cursorPosition

    readonly property int cursorY:
        textArea.text.substring(0, cursorPosition).split("\n").length - 1

    readonly property int cursorX:
        cursorPosition - lines.slice(0, cursorY).join("").length - cursorY

    readonly property var lines: textArea.text.split("\n")
    readonly property string lineText: lines[cursorY] || ""

    readonly property string lineTextUntilCursor:
        lineText.substring(0, cursorX)

    // readonly property int deleteCharsOnBackspace:
    //     lineTextUntilCursor.match(/^ +$/) ?
    //     lineTextUntilCursor.match(/ {1,4}/g).slice(-1)[0].length :
    //     1


    function takeFocus() { areaScrollView.forceActiveFocus() }


    HRowLayout {
        anchors.fill: parent

        HUserAvatar {
            id: avatar
            userId: writingUserId
            displayName: writingUserInfo ? writingUserInfo.display_name : ""
            mxc: writingUserInfo ? writingUserInfo.avatar_url : ""
        }

        HScrollableTextArea {
            id: areaScrollView
            saveName: "composer"
            saveId: [chat.roomId, writingUserId]

            enabled: chat.roomInfo.can_send_messages
            disabledText:
                qsTr("You do not have permission to post in this room")
            placeholderText: qsTr("Type a message...")

            backgroundColor: "transparent"
            area.tabStopDistance: 4 * 4  // 4 spaces
            area.focus: true

            Layout.fillHeight: true
            Layout.fillWidth: true


            function setTyping(typing) {
                py.callClientCoro(
                    writingUserId,
                    "room_typing",
                    [chat.roomId, typing, 5000]
                )
            }

            onTextChanged: {
                if (utils.isEmptyObject(aliases)) {
                    writingUserId = Qt.binding(() => chat.userId)
                    toSend        = text
                    setTyping(Boolean(text))
                    textChangedSinceLostFocus = true
                    return
                }

                let foundAlias = null

                for (const [user, writing_alias] of Object.entries(aliases)) {
                    if (text.startsWith(writing_alias + " ")) {
                        writingUserId = user
                        foundAlias = new RegExp("^" + writing_alias + " ")
                        break
                    }
                }

                if (foundAlias) {
                    toSend = text.replace(foundAlias, "")
                    setTyping(Boolean(text))
                    textChangedSinceLostFocus = true
                    return
                }

                writingUserId = Qt.binding(() => chat.userId)
                toSend        = text

                const vals = Object.values(aliases)

                const longestAlias =
                    vals.reduce((a, b) => a.length > b.length ? a: b)

                const textNotStartsWithAnyAlias =
                    ! vals.some(a => a.startsWith(text))

                const textContainsCharNotInAnyAlias =
                    vals.every(a => text.split("").some(c => ! a.includes(c)))

                // Only set typing when it's sure that the user will not use
                // an alias and has written something
                if (toSend &&
                    (text.length > longestAlias.length ||
                     textNotStartsWithAnyAlias ||
                     textContainsCharNotInAnyAlias))
                {
                    setTyping(Boolean(text))
                    textChangedSinceLostFocus = true
                }
            }

            area.onEditingFinished: {  // when lost focus
                if (text && textChangedSinceLostFocus) {
                    setTyping(false)
                    textChangedSinceLostFocus = false
                }
            }

            area.onSelectedTextChanged: if (area.selectedText) {
                eventList.selectableLabelContainer.clearSelection()
            }

            Component.onCompleted: {
                area.Keys.onReturnPressed.connect(ev => {
                    ev.accepted = true

                    if (ev.modifiers & Qt.ShiftModifier ||
                        ev.modifiers & Qt.ControlModifier ||
                        ev.modifiers & Qt.AltModifier)
                    {
                        let indents = 0
                        const parts = lineText.split(indent)

                        for (const [i, part] of parts.entries()) {
                            if (i === parts.length - 1 || part) { break }
                            indents += 1
                        }

                        const add = indent.repeat(indents)
                        textArea.insert(cursorPosition, "\n" + add)
                        return
                    }

                    if (textArea.text === "") { return }

                    const args = [chat.roomId, toSend]
                    py.callClientCoro(writingUserId, "send_text", args)

                    area.clear()
                })

                area.Keys.onEnterPressed.connect(area.Keys.onReturnPressed)

                area.Keys.onTabPressed.connect(ev => {
                    ev.accepted = true
                    textArea.insert(cursorPosition, indent)
                })

                area.Keys.onPressed.connect(ev => {
                    if (ev.matches(StandardKey.Copy) &&
                        eventList.selectableLabelContainer.joinedSelection
                    ) {
                        ev.accepted = true
                        Clipboard.text =
                            eventList.selectableLabelContainer.joinedSelection
                        return
                    }

                    // FIXME: buggy
                    // if (ev.modifiers === Qt.NoModifier &&
                    //     ev.key === Qt.Key_Backspace &&
                    //     ! textArea.selectedText)
                    // {
                    //     ev.accepted = true
                    //     textArea.remove(
                    //         cursorPosition - deleteCharsOnBackspace,
                    //         cursorPosition
                    //     )
                    // }
                })
            }
        }

        HButton {
            enabled: chat.roomInfo.can_send_messages
            icon.name: "upload-file"
            backgroundColor: theme.chat.composer.uploadButton.background
            toolTip.text:
                chat.userInfo.max_upload_size ?
                qsTr("Send files (%1 max)").arg(
                    CppUtils.formattedBytes(chat.userInfo.max_upload_size, 0),
                ) :
                qsTr("Send files")

            onClicked: sendFilePicker.dialog.open()

            Layout.fillHeight: true

            SendFilePicker {
                id: sendFilePicker
                userId: chat.userId
                roomId: chat.roomId
            }
        }
    }
}
