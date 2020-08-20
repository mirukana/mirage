// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../.."
import "../../../Base"
import "../../../Base/HTile"

HListView {
    id: listView

    property HTextArea textArea
    property bool open: false

    property string originalText: ""
    property bool autoOpenCompleted: false

    readonly property bool autoOpen:
        autoOpenCompleted || textArea.text.match(/.*(^|\W)@[^\s]+$/)

    readonly property string wordToComplete:
        open ?
        (originalText || textArea.text).split(/\s/).slice(-1)[0].replace(
            autoOpen ? /^@/ : "", "",
        ) :
        ""

    function replaceLastWord(withText) {
        const lastWordStart = /(?:^|\s)[^\s]+$/.exec(textArea.text).index
        const isTextStart   =
            lastWordStart === 0 && ! textArea.text[0].match(/\s/)

        textArea.remove(lastWordStart + (isTextStart ? 0 : 1), textArea.length)
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

    function cancel() {
        if (originalText)
            replaceLastWord(originalText.split(/\s/).splice(-1)[0])

        open = false
    }


    visible: opacity > 0
    opacity: open && count ? 1 : 0
    implicitHeight: open && count ? Math.min(window.height, contentHeight) : 0
    model: ModelStore.get(chat.userId, chat.roomId, "autocompleted_members")

    delegate: HTile {
        width: listView.width
        contentItem: HLabel { text: model.display_name + " (" + model.id + ")"}
        onClicked: {
            currentIndex  = model.index
            listView.open = false
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
}
