import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12
import "Base"

Window {
    id: debugConsole
    title: qsTr("Debug console")
    width: 640
    height: 480
    visible: false
    flags: Qt.WA_TranslucentBackground
    color: "transparent"


    property var target: null
    property alias t: debugConsole.target

    property var history: []
    property alias his: debugConsole.history
    property int historyEntry: -1


    Component.onCompleted: {
        mainUI.shortcuts.debugConsole = debugConsole
        commandsView.model.insert(0, {
            input: "target = " + String(target),
            output: "",
            error: false,
        })
        visible = true
    }

    onHistoryEntryChanged:
        inputField.text =
            historyEntry === -1 ? "" : history.slice(-historyEntry - 1)[0]


    function runJS(input) {
        if (history.slice(-1)[0] !== input) history.push(input)

        let error = false

        try {
            if (input.startsWith("j ")) {
                var output = JSON.stringify(eval(input.substring(2)), null, 4)

            } else {
                let result = eval(input)
                var output = result instanceof Array ?
                             "[" + String(result) + "]" : String(result)
            }

        } catch (err) {
            error = true
            var output = err.toString()
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
            placeholderText: qsTr("Type some JavaScript...")
            font.family: theme.fontFamily.mono

            Keys.onUpPressed:
                if (historyEntry + 1 < history.length ) historyEntry += 1
            Keys.onDownPressed:
                if (historyEntry - 1 >= -1) historyEntry -= 1

            Layout.fillWidth: true

        }
    }
}
