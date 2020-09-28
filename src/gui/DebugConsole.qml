// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12
import "Base"
import "ShortcutBundles"

HDrawer {
    id: debugConsole

    property Item previouslyFocused: null

    property QtObject target: null
    property alias t: debugConsole.target

    property var history: window.history.console
    property alias his: debugConsole.history
    property int historyEntry: -1
    property int maxHistoryLength: 4096
    property var textBeforeHistoryNavigation: null  // null or string

    property string help: qsTr(
        `Javascript debugging console

        Useful variables:
            window, theme, settings, utils, mainPane, mainUI, pageLoader
            py    Python interpreter
            this  The console itself
            t     Target item to debug for which this console was opened
            his   History, list of commands entered

        Special commands:
            .j OBJECT, .json OBJECT  Print OBJECT as human-readable JSON

            .t, .top     Attach the console to the parent window's top
            .b, .bottom  Attach the console to the parent window's bottom
            .l, .left    Attach the console to the parent window's left
            .r, .right   Attach the console to the parent window's right
            .h, .help    Show this help`.replace(/^ {8}/gm, "")
    )

    property bool doUselessThing: false
    property real baseGIFSpeed: 1.0

    readonly property alias commandsView: commandsView

    function toggle(targetItem=null, js="", addToHistory=false) {
        if (debugConsole.visible) {
            debugConsole.visible = false
            return
        }

        debugConsole.visible = true
        debugConsole.target  =
            ! targetItem && ! debugConsole.target ? mainUI :
            targetItem ? targetItem :
            debugConsole.target

        if (js) debugConsole.runJS(js, addToHistory)
    }

    function runJS(input, addToHistory=true) {
        if (addToHistory && history.slice(-1)[0] !== input) {
            history.push(input)
            while (history.length > maxHistoryLength) history.shift()
            window.historyChanged()
        }

        let output = ""
        let error  = false

        try {
            if ([".h", ".help"].includes(input)) {
                output = debugConsole.help

            } else if ([".t", ".top"].includes(input)) {
                debugConsole.edge = Qt.TopEdge

            } else if ([".b", ".bottom"].includes(input)) {
                debugConsole.edge = Qt.BottomEdge

            } else if ([".l", ".left"].includes(input)) {
                debugConsole.edge = Qt.LeftEdge

            } else if ([".r", ".right"].includes(input)) {
                debugConsole.edge = Qt.RightEdge

            } else if (input.startsWith(".j ") || input.startsWith(".json ")) {
                output = JSON.stringify(eval(input.substring(2)), null, 4)

            } else {
                let result = eval(input)
                output     = result instanceof Array ?
                             "[" + String(result) + "]" : String(result)
            }

        } catch (err) {
            error  = true
            output = err.toString()
        }

        commandsView.model.insert(0, { input, output, error })
    }


    objectName: "debugConsole"
    edge: Qt.TopEdge
    x: horizontal ? 0 : referenceSizeParent.width / 2 - width / 2
    y: vertical ? 0 : referenceSizeParent.height / 2 - height / 2
    width: horizontal ? calculatedSize : Math.min(window.width, 720)
    height: vertical ? calculatedSize : Math.min(window.height, 720)
    defaultSize: 400
    z: 9999
    position: 0

    onTargetChanged: {
        commandsView.model.insert(0, {
            input: "t = " + String(target),
            output: "",
            error: false,
        })
    }

    onVisibleChanged: {
        if (visible) {
            previouslyFocused = window.activeFocusItem
            forceActiveFocus()
        } else if (previouslyFocused) {
            previouslyFocused.forceActiveFocus()
        }
    }

    onHistoryEntryChanged: {
        if (historyEntry === -1) {
            inputArea.clear()
            inputArea.append(textBeforeHistoryNavigation)
            textBeforeHistoryNavigation = null
            return
        }

        if (textBeforeHistoryNavigation === null)
            textBeforeHistoryNavigation = inputArea.text

        inputArea.clear()
        inputArea.append(history.slice(-historyEntry - 1)[0])
    }

    HShortcut {
        sequences: settings.keys.toggleDebugConsole
        onActivated: debugConsole.toggle()
    }

    HColumnLayout {
        anchors.fill: parent
        // Fixes inputArea cursor invisible when at cursorPosition 0
        anchors.leftMargin: 1

        HListView {
            id: commandsView
            spacing: theme.spacing
            topMargin: theme.spacing
            bottomMargin: topMargin
            leftMargin: theme.spacing
            rightMargin: leftMargin
            clip: true
            verticalLayoutDirection: ListView.BottomToTop

            Layout.fillWidth: true
            Layout.fillHeight: true

            model: ListModel {}

            delegate: HColumnLayout {
                width: commandsView.width -
                       commandsView.leftMargin - commandsView.rightMargin

                HLabel {
                    text: "> " + model.input.replace(/\n/g, "\n> ")
                    wrapMode: HLabel.Wrap
                    color: theme.chat.message.quote
                    font.family: theme.fontFamily.mono
                    visible: Boolean(model.input)

                    Layout.fillWidth: true
                }

                HLabel {
                    text: model.output
                    wrapMode: HLabel.Wrap
                    color: model.error ?
                           theme.colors.errorText : theme.colors.text
                    font.family: theme.fontFamily.mono
                    visible: Boolean(model.output)

                    Layout.fillWidth: true
                }
            }

            FlickShortcuts {
                active: debugConsole.visible
                flickable: commandsView
            }

            Rectangle {
                z: -10
                anchors.fill: parent
                color: theme.colors.weakBackground
            }
        }

        HTextArea {
            id: inputArea

            readonly property int cursorY:
                text.substring(0, cursorPosition).split("\n").length - 1

            function accept() {
                if (! text) return
                runJS(text)
                clear()
                historyEntry = -1
            }

            focus: true
            backgroundColor: Qt.hsla(0, 0, 0, 0.85)
            bordered: false
            placeholderText: qsTr("JavaScript debug console - Try .help")
            font.family: theme.fontFamily.mono

            Keys.onUpPressed: ev => {
                ev.accepted =
                    cursorY === 0 && historyEntry + 1 < history.length

                if (ev.accepted) {
                    historyEntry   += 1
                    cursorPosition  = length
                }
            }

            Keys.onDownPressed: ev => {
                ev.accepted =
                    cursorY === lineCount - 1 && historyEntry - 1 >= -1

                if (ev.accepted) historyEntry -= 1
            }

            Keys.onTabPressed: inputArea.insertAtCursor("    ")

            Keys.onReturnPressed: ev => {
                ev.modifiers & Qt.ShiftModifier ||
                ev.modifiers & Qt.ControlModifier ||
                ev.modifiers & Qt.AltModifier ?
                inputArea.insertAtCursor("\n") :
                accept()
            }

            Keys.onEnterPressed: ev => Keys.returnPressed(ev)

            Keys.onEscapePressed: debugConsole.close()

            Layout.fillWidth: true

        }
    }

    NumberAnimation {
        running: doUselessThing
        target: mainUI.mainPane.roomList
        property: "rotation"
        duration: 250
        from: 360
        to: 0
        loops: Animation.Infinite
        onStopped: target.rotation = 0
    }
}
