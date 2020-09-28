// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12
import Clipboard 0.1
import "Base"
import "ShortcutBundles"

HDrawer {
    id: debugConsole

    property Item previouslyFocused: null

    property QtObject target: null
    property alias t: debugConsole.target

    property var history: window.history.console
    property int historyEntry: -1
    property int maxHistoryLength: 4096
    property var textBeforeHistoryNavigation: null  // null or string

    property int selectedOutputDelegateIndex: -1
    property string selectedOutputText: ""

    property string pythonDebugKeybind:
        window.settings.keys.startPythonDebugger[0]

    property string help: qsTr(
        `Interact with the QML code using JavaScript ES6 syntax.

        Useful variables:
            t     Target item to debug for which this console was opened
            this  The console itself
            py    Python interpreter (${pythonDebugKeybind} to start debugger)

            window, mainUI, theme, settings, utils, mainPane, pageLoader

        Special commands:
            .j OBJECT, .json OBJECT  Print OBJECT as human-readable JSON

            .t, .top     Attach console to the parent window's top
            .b, .bottom  Attach console to the parent window's bottom
            .l, .left    Attach console to the parent window's left
            .r, .right   Attach console to the parent window's right
            .h, .help    Show this help`.replace(/^ {8}/gm, "")
    )

    property bool doUselessThing: false
    property real baseGIFSpeed: 1.0

    readonly property alias outputList: outputList

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

        outputList.model.insert(0, { input, output, error })
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
        outputList.model.insert(0, {
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
            id: outputList
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

            delegate: HSelectableLabel {
                id: delegate
                width: outputList.width -
                       outputList.leftMargin - outputList.rightMargin

                readonly property color inputColor:
                    model.error ? theme.colors.errorText :
                    model.output ? theme.colors.accentText :
                    theme.colors.positiveText

                text:
                    `<div style="white-space: pre-wrap">` +
                    `<font color="${inputColor}">` +
                    utils.plain2Html(model.input) +
                    "</font>" +
                    (model.input && model.output ? "<br>" : "") +
                    (model.output ? utils.plain2Html(model.output) : "") +
                    "</div>"

                leftPadding: theme.spacing
                textFormat: HSelectableLabel.RichText
                wrapMode: HLabel.Wrap
                font.family: theme.fontFamily.mono
                color:
                    model.error ?
                    Qt.darker(inputColor, 1.4) :
                    theme.colors.halfDimText

                Layout.fillWidth: true

                onSelectedTextChanged: if (selectedText) {
                    selectedOutputDelegateIndex = model.index
                    selectedOutputText          = selectedText
                } else if (selectedOutputDelegateIndex === model.index) {
                    selectedOutputDelegateIndex = -1
                    selectedOutputText          = ""
                }

                Connections {
                    target: debugConsole
                    onSelectedOutputDelegateIndexChanged: {
                        if (selectedOutputDelegateIndex !== model.index)
                            delegate.deselect()
                    }
                }

                TapHandler {
                    acceptedButtons: Qt.RightButton
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    acceptedPointerTypes:
                        PointerDevice.GenericPointer | PointerDevice.Pen

                    onTapped: menu.popup()
                }

                TapHandler {
                    acceptedPointerTypes:
                        PointerDevice.Finger | PointerDevice.Pen

                    onLongPressed: menu.popup()
                }

                HMenu {
                    id: menu
                    implicitWidth: Math.min(window.width, 150)
                    z: 10000

                    HMenuItem {
                        icon.name: "copy-text"
                        text: qsTr("Copy")
                        onTriggered: {
                            if (delegate.selectedText) {
                                delegate.copy()
                                return
                            }
                            delegate.selectAll()
                            delegate.copy()
                            delegate.deselect()
                        }
                    }
                }

                Rectangle {
                    width: 1
                    height: parent.height
                    color:
                        model.error ?
                        theme.colors.negativeBackground :
                        model.output ?
                        theme.colors.accentElement :
                        theme.colors.positiveBackground
                }
            }

            FlickShortcuts {
                active: debugConsole.visible
                flickable: outputList
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
            placeholderText: qsTr("QML/JavaScript debug console - Type .help")
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

            Keys.onPressed: ev => {
                if (
                    ev.matches(StandardKey.Copy) &&
                    ! inputArea.selectedText &&
                    selectedOutputText
                ) {
                    ev.accepted = true
                    Clipboard.text = selectedOutputText
                }
            }

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
