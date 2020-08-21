// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../.."
import "../../../Base"
import "../../../Base/HTile"

// FIXME: a b -> a @p b → @p doesn't trigger completion
HListView {
    id: root

    property HTextArea textArea
    property bool open: false

    property string originalText: ""
    property bool autoOpenCompleted: false
    property var usersCompleted: ({})  // {displayName: userId}

    readonly property bool autoOpen:
        autoOpenCompleted || textArea.text.match(/.*(^|\W)@[^\s]+$/)

    readonly property string wordToComplete:
        open ?
        (originalText || textArea.text).split(/\s/).slice(-1)[0].replace(
            autoOpen ? /^@/ : "", "",
        ) :
        ""

    function getLastWordStart() {
        const lastWordMatch = /(?:^|\s)[^\s]+$/.exec(textArea.text)
        if (! lastWordMatch) return textArea.length

        if (! (lastWordMatch.index === 0 && ! textArea.text[0].match(/\s/)))
            return lastWordMatch.index + 1

        return lastWordMatch.index
    }

    function replaceLastWord(withText) {
        textArea.remove(getLastWordStart(), textArea.length)
        textArea.insertAtCursor(withText)
    }

    function previous() {
        if (open) {
            decrementCurrentIndex()
            return
        }

        open = true
        const args = [model.modelId, wordToComplete]
        py.callCoro("set_string_filter", args, decrementCurrentIndex)
    }

    function next() {
        if (open) {
            incrementCurrentIndex()
            return
        }

        open = true
        const args = [model.modelId, wordToComplete]
        py.callCoro("set_string_filter", args, incrementCurrentIndex)
    }

    function accept() {
        if (currentIndex !== -1) {
            const member = model.get(currentIndex)
            usersCompleted[member.display_name] = member.id
            usersCompletedChanged()
        }

        open = false
    }

    function cancel() {
        if (originalText)
            replaceLastWord(originalText.split(/\s/).splice(-1)[0])

        currentIndex = -1
        open         = false
    }


    visible: opacity > 0
    opacity: open && count ? 1 : 0
    implicitHeight: open && count ? Math.min(window.height, contentHeight) : 0
    model: ModelStore.get(chat.userId, chat.roomId, "autocompleted_members")

    delegate: HTile {
        width: root.width
        contentItem: HLabel { text: model.display_name + " (" + model.id + ")"}
        onClicked: {
            currentIndex = model.index
            root.open    = false
        }
    }

    onCountChanged: if (! count && open) open = false
    onAutoOpenChanged: open = autoOpen
    onOpenChanged: if (! open) {
        originalText      = ""
        currentIndex      = -1
        autoOpenCompleted = false
        py.callCoro("set_string_filter", [model.modelId, ""])
    }

    onWordToCompleteChanged: {
        if (! open) return
        py.callCoro("set_string_filter", [model.modelId, wordToComplete])
    }

    onCurrentIndexChanged: {
        if (currentIndex === -1) return
        if (! originalText) originalText = textArea.text
        if (autoOpen) autoOpenCompleted = true

        replaceLastWord(model.get(currentIndex).display_name)
    }

    Behavior on opacity { HNumberAnimation {} }
    Behavior on implicitHeight { HNumberAnimation {} }

    Connections {
        target: root.textArea

        function onCursorPositionChanged() {
            if (root.open && root.textArea.cursorPosition < getLastWordStart())
                root.accept()
        }

        function onTextChanged() {
            let changed = false

            for (const displayName of Object.keys(root.usersCompleted)) {
                if (! root.textArea.text.includes(displayName)) {
                    delete root.usersCompleted[displayName]
                    changed = true
                }
            }

            if (changed) root.usersCompletedChanged()
        }
    }
}
