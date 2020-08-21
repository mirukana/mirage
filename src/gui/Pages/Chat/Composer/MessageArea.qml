// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import Clipboard 0.1
import "../../.."
import "../../../Base"

HTextArea {
    id: area

    property HListView eventList

    property bool autoCompletionOpen: false
    property var usersCompleted: ({})

    property string indent: "    "

    property string toSend: ""
    property bool textChangedSinceLostFocus: false
    property string writingUserId: chat.userId

    readonly property QtObject writingUserInfo:
        ModelStore.get("accounts").find(writingUserId)

    readonly property int cursorY:
        text.substring(0, cursorPosition).split("\n").length - 1

    readonly property int cursorX:
        cursorPosition - lines.slice(0, cursorY).join("").length - cursorY

    readonly property var lines: text.split("\n")
    readonly property string lineText: lines[cursorY] || ""

    readonly property string lineTextUntilCursor:
        lineText.substring(0, cursorX)

    // readonly property int deleteCharsOnBackspace:
    //     lineTextUntilCursor.match(/^ +$/) ?
    //     lineTextUntilCursor.match(/ {1,4}/g).slice(-1)[0].length :
    //     1

    readonly property var usableAliases: {
        const obj = {}

        // Get accounts that are members of this room with permission to talk
        for (const [id, alia] of Object.entries(window.settings.writeAliases)){
            const room = ModelStore.get(id, "rooms").find(chat.roomId)
            if (room &&
                    ! room.inviter_id && ! room.left && room.can_send_messages)
                obj[id] = alia
        }

        return obj
    }

    signal autoCompletePrevious()
    signal autoCompleteNext()
    signal acceptAutoCompletion()
    signal cancelAutoCompletion()

    function setTyping(typing) {
        if (! area.enabled) return

        py.callClientCoro(
            writingUserId, "room_typing", [chat.roomId, typing, 5000],
        )
    }

    function clearReplyTo() {
        if (! chat.replyToEventId) return

        chat.replyToEventId     = ""
        chat.replyToUserId      = ""
        chat.replyToDisplayName = ""
    }

    function addNewLine() {
        let indents = 0
        const parts = lineText.split(indent)

        for (const [i, part] of parts.entries()) {
            if (i === parts.length - 1 || part) { break }
            indents += 1
        }

        const add = indent.repeat(indents)
        area.insertAtCursor("\n" + add)
    }

    function sendText() {
        if (! toSend) return

        // Need to copy usersCompleted because the completion UI closing will
        // clear it before it reaches Python.
        const mentions = Object.assign({}, usersCompleted)
        const args     = [chat.roomId, toSend, mentions, chat.replyToEventId]
        py.callClientCoro(writingUserId, "send_text", args)

        area.clear()
        clearReplyTo()
    }


    saveName: "composer"
    saveId: [chat.roomId, writingUserId]

    enabled: chat.roomInfo.can_send_messages
    disabledText: qsTr("You do not have permission to post in this room")
    placeholderText: qsTr("Type a message...")
    enableCustomImagePaste: true
    menuKeySpawnsMenu:
        ! (eventList && (eventList.currentItem || eventList.selectedCount))

    backgroundColor: "transparent"
    focusedBorderColor: "transparent"
    tabStopDistance: 4 * 4  // 4 spaces
    focus: true

    // TODO: make this more declarative
    onTextChanged: {
        if (! text || utils.isEmptyObject(usableAliases)) {
            writingUserId = Qt.binding(() => chat.userId)
            toSend        = text
            setTyping(Boolean(text))
            textChangedSinceLostFocus = true
            return
        }

        let foundAlias = null

        for (const [user, writing_alias] of Object.entries(usableAliases)) {
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

        const vals = Object.values(usableAliases)

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

    onEditingFinished: {  // when focus is lost
        if (text && textChangedSinceLostFocus) {
            setTyping(false)
            textChangedSinceLostFocus = false
        }
    }

    onCustomImagePaste: window.makePopup(
        "Popups/ConfirmClipboardUploadPopup.qml",
        {
            userId: chat.userId,
            roomId: chat.roomId,
            roomName: chat.roomInfo.display_name,
        },
    )

    Keys.onEscapePressed:
        autoCompletionOpen ? cancelAutoCompletion() : clearReplyTo()

    Keys.onReturnPressed: ev => {
        if (autoCompletionOpen) acceptAutoCompletion()
        ev.accepted = true

        ev.modifiers & Qt.ShiftModifier ||
        ev.modifiers & Qt.ControlModifier ||
        ev.modifiers & Qt.AltModifier ?
        addNewLine() :
        sendText()
    }

    Keys.onEnterPressed: ev => Keys.returnPressed(ev)

    Keys.onMenuPressed: ev => {
        if (autoCompletionOpen) acceptAutoCompletion()

        if (eventList && eventList.currentItem)
            eventList.currentItem.openContextMenu()
    }

    Keys.onBacktabPressed: ev => {
        // if previous char isn't a space/tab/newline
        if (text.slice(cursorPosition - 1, cursorPosition).trim()) {
            ev.accepted = true
            autoCompletePrevious()
        }
    }

    Keys.onTabPressed: ev => {
        ev.accepted = true

        if (text.slice(cursorPosition - 1, cursorPosition).trim()) {
            autoCompleteNext()
            return
        }

        area.insertAtCursor(indent)
    }

    Keys.onUpPressed: ev => {
        ev.accepted = autoCompletionOpen
        if (autoCompletionOpen) autoCompletePrevious()
    }

    Keys.onDownPressed: ev => {
        ev.accepted = autoCompletionOpen
        if (autoCompletionOpen) autoCompleteNext()
    }

    Keys.onPressed: ev => {
        if (ev.text && autoCompletionOpen) acceptAutoCompletion()

        if (ev.matches(StandardKey.Copy) &&
            ! area.selectedText &&
            eventList &&
            (eventList.selectedCount || eventList.currentIndex !== -1))
        {
            ev.accepted = true
            eventList.copySelectedDelegates()
            return
        }

        // FIXME: buggy
        // if (ev.modifiers === Qt.NoModifier &&
        //     ev.key === Qt.Key_Backspace &&
        //     ! area.selectedText)
        // {
        //     ev.accepted = true
        //     area.remove(
        //         cursorPosition - deleteCharsOnBackspace,
        //         cursorPosition
        //     )
        // }
    }
}
