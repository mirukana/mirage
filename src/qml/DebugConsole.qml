import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12
import "Base"
import "utils.js" as Utils
import "utils.js" as U

HDrawer {
    id: debugConsole
    edge: Qt.TopEdge
    x: horizontal ? 0 : referenceSizeParent.width / 2 - width / 2
    y: vertical ? 0 : referenceSizeParent.height / 2 - height / 2
    width: horizontal ? calculatedSize : Math.min(window.width, 720)
    height: vertical ? calculatedSize : Math.min(window.height, 720)
    normalSize: 400
    z: 9999
    position: 0

    property var previouslyFocusedItem: null

    property var target: null
    property alias t: debugConsole.target

    property var history: window.history.console
    property alias his: debugConsole.history
    property int historyEntry: -1
    property int maxHistoryLength: 5

    property string help: qsTr(
        `Javascript debugging console

        Useful variables:
            window, theme, settings, shortcuts, mainUI, pageLoader
            py    Python interpreter
            U     Utils/utils.js module
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

    readonly property alias commandsView: commandsView


    Component.onCompleted: {
        if (mainUI.shortcuts.debugConsole)
            mainUI.shortcuts.debugConsole.destroy()

        mainUI.shortcuts.debugConsole = debugConsole
        position = 1
        commandsView.model.insert(0, {
            input: "t = " + String(target),
            output: "",
            error: false,
        })
    }

    onVisibleChanged: {
        if (visible) {
            previouslyFocusedItem = window.activeFocusItem
            forceActiveFocus()
        } else if (previouslyFocusedItem) {
            previouslyFocusedItem.forceActiveFocus()
        }
    }

    onHistoryEntryChanged:
        inputField.text =
            historyEntry === -1 ? "" : history.slice(-historyEntry - 1)[0]


    function runJS(input) {
        if (history.slice(-1)[0] !== input) {
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


    HColumnLayout {
        anchors.fill: parent

        Keys.onEscapePressed: debugConsole.visible = false

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
                    text: "> " + model.input
                    wrapMode: Text.Wrap
                    color: theme.chat.message.quote
                    font.family: theme.fontFamily.mono
                    visible: Boolean(model.input)

                    Layout.fillWidth: true
                }

                HLabel {
                    text: "" + model.output
                    wrapMode: Text.Wrap
                    color: model.error ?
                           theme.colors.errorText : theme.colors.text
                    font.family: theme.fontFamily.mono
                    visible: Boolean(model.output)

                    Layout.fillWidth: true
                }
            }

            Rectangle {
                z: -10
                anchors.fill: parent
                color: theme.colors.weakBackground
            }
        }

        HTextField {
            id: inputField
            focus: true
            onAccepted: if (text) { runJS(text); text = ""; historyEntry = -1 }
            backgroundColor: Qt.hsla(0, 0, 0, 0.85)
            bordered: false
            placeholderText: qsTr("Javascript debug console - Try .help")
            font.family: theme.fontFamily.mono

            Keys.onUpPressed:
                if (historyEntry + 1 < history.length ) historyEntry += 1
            Keys.onDownPressed:
                if (historyEntry - 1 >= -1) historyEntry -= 1

            Layout.fillWidth: true

        }
    }
}
