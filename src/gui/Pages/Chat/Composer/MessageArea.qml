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

    property string userSetAsTyping: ""
    property bool textChangedSinceLostFocus: false

    readonly property var usableAliases: {
        const obj     = {}
        const aliases = window.settings.writeAliases

        // Get accounts that are members of this room with permission to talk
        for (const [id, alias] of Object.entries(aliases)) {
            const room = ModelStore.get(id, "rooms").find(chat.roomId)

            room && ! room.inviter_id && ! room.left && room.can_send_messages?
            obj[id] = alias.trim().split(/\s/)[0] :
            null
        }

        return obj
    }

    readonly property var candidateAliases: {
        if (! text) return []

        const candidates = []
        const words      = text.split(" ")

        for (const [userId, alias] of Object.entries(usableAliases))
            if ((words.length === 1 && alias.startsWith(words[0])) ||
                (words.length > 1 && words[0] == alias))

                candidates.push({id: userId, text: alias})

        return candidates
    }

    readonly property var usingAlias:
        candidateAliases.length === 1 && text.includes(" ") ?
        candidateAliases[0] :
        null

    readonly property string writerId: usingAlias ? usingAlias.id : chat.userId

    readonly property string toSend:
        usingAlias ? text.replace(usingAlias.text + " ", "") : text

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

    signal autoCompletePrevious()
    signal autoCompleteNext()
    signal acceptAutoCompletion()
    signal cancelAutoCompletion()

    function setTyping(typing) {
        if (! area.enabled) return

        if (typing && userSetAsTyping && userSetAsTyping !== writerId)
            py.callClientCoro(
                userSetAsTyping, "room_typing", [chat.roomId, false],
            )

        const userId = typing ? writerId : userSetAsTyping

        userSetAsTyping = typing ? writerId : ""

        if (! userId) return  // ! typing && ! userSetAsTyping

        py.callClientCoro(userId, "room_typing", [chat.roomId, typing])
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
        if (! toSend && ! chat.replyToEventId) return

        // Need to copy usersCompleted because the completion UI closing will
        // clear it before it reaches Python.
        const mentions = Object.assign({}, usersCompleted)
        const args     = [chat.roomId, toSend, mentions, chat.replyToEventId]
        py.callClientCoro(writerId, "send_text", args)

        area.clear()
        clearReplyTo()
    }


    saveName: "composer"
    saveId: [chat.roomId, chat.userId]

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

    onTextChanged: if (! text) setTyping(false)

    onToSendChanged: {
        textChangedSinceLostFocus = true

        if (toSend && (usingAlias || ! candidateAliases.length)) {
            setTyping(true)
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
            replyToEventId: chat.replyToEventId,
        },
        popup => popup.replied.connect(chat.clearReplyTo),
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

    Connections {
        target: pageLoader
        onRecycled: {
            area.reset()
            area.loadState()
        }
    }
}
