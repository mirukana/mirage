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


    function runJS(input) {
        let error = false

        try {
            var output = input.startsWith("j ") ?
                         JSON.stringify(eval(input.substring(2)), null, 4) :
                         String(eval(input))
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
            rightMargin: rightMargin
            clip: true
            verticalLayoutDirection: ListView.BottomToTop

            Layout.fillWidth: true
            Layout.fillHeight: true

            model: ListModel {}

            delegate: HColumnLayout {
                width: commandsView.width

                HLabel {
                    text: "> " + model.input
                    wrapMode: Text.Wrap
                    color: theme.chat.message.quote
                    visible: model.input

                    Layout.fillWidth: true
                }

                HLabel {
                    text: "" + model.output
                    wrapMode: Text.Wrap
                    color: model.error ?
                           theme.colors.errorText : theme.colors.text
                    visible: model.output

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
            focus: true
            onAccepted: if (text) runJS(text)
            backgroundColor: Qt.hsla(0, 0, 0, 0.85)
            bordered: false
            placeholderText: qsTr("Type some JavaScript...")

            Layout.fillWidth: true

        }
    }
}
