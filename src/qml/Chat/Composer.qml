import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../Dialogs"
import "../utils.js" as Utils

Rectangle {
    function setFocus() { areaScrollView.forceActiveFocus() }

    property string indent: "    "

    property var aliases: window.settings.writeAliases
    property string toSend: ""

    property string writingUserId: chatPage.userId
    readonly property var writingUserInfo:
        Utils.getItem(modelSources["Account"] || [], "user_id", writingUserId)

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

    readonly property int deleteCharsOnBackspace:
        lineTextUntilCursor.match(/^ +$/) ?
        lineTextUntilCursor.match(/ {1,4}/g).slice(-1)[0].length :
        1

    // property var pr: lineTextUntilCursor
    // onPrChanged: print(
    //      "y", cursorY, "x", cursorX,
    //      "ltuc <" + lineTextUntilCursor + ">", "dob",
    //      deleteCharsOnBackspace, "m", lineTextUntilCursor.match(/^ +$/))

    id: composer
    Layout.fillWidth: true
    Layout.minimumHeight: theme.baseElementsHeight
    Layout.preferredHeight: areaScrollView.implicitHeight
    Layout.maximumHeight: pageLoader.height / 2
    color: theme.chat.composer.background

    HRowLayout {
        anchors.fill: parent

        HUserAvatar {
            id: avatar
            userId: writingUserId
            displayName: writingUserInfo.display_name
            avatarUrl: writingUserInfo.avatar_url
        }

        HScrollableTextArea {
            id: areaScrollView
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
                    [chatPage.roomId, typing, 5000]
                )
            }

            onTextChanged: {
                if (Utils.isEmptyObject(aliases)) {
                    writingUserId = Qt.binding(() => chatPage.userId)
                    toSend        = text
                    setTyping(Boolean(text))
                    textChangedSinceLostFocus = true
                    return
                }

                let foundAlias = null

                for (let [user, writing_alias] of Object.entries(aliases)) {
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

                writingUserId = Qt.binding(() => chatPage.userId)
                toSend        = text

                let vals = Object.values(aliases)

                let longestAlias =
                    vals.reduce((a, b) => a.length > b.length ? a: b)

                let textNotStartsWithAnyAlias =
                    ! vals.some(a => a.startsWith(text))

                let textContainsCharNotInAnyAlias =
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
                        let parts   = lineText.split(indent)

                        for (const [i, part] of parts.entries()) {
                            if (i == parts.length - 1 || part) { break }
                            indents += 1
                        }

                        let add = indent.repeat(indents)
                        textArea.insert(cursorPosition, "\n" + add)
                        return
                    }

                    if (textArea.text === "") { return }

                    let args = [chatPage.roomId, toSend]
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

                    if (ev.modifiers == Qt.NoModifier &&
                        ev.key == Qt.Key_Backspace &&
                        ! textArea.selectedText)
                    {
                        ev.accepted = true
                        textArea.remove(
                            cursorPosition - deleteCharsOnBackspace,
                            cursorPosition
                        )
                    }
                })
            }
        }

        HButton {
            icon.name: "upload-file"
            backgroundColor: theme.chat.composer.uploadButton.background
            toolTip.text: qsTr("Upload files")

            Layout.fillHeight: true

            HFileDialogOpener {
                dialog.title: qsTr("Select files to upload")
            }
        }
    }
}
