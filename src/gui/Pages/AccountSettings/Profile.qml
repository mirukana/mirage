// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../Dialogs"

HGridLayout {
    function applyChanges() {
        if (nameField.changed) {
            saveButton.nameChangeRunning = true

            py.callClientCoro(
                userId, "set_displayname", [nameField.item.text], () => {
                    py.callClientCoro(userId, "update_own_profile", [], () => {
                        saveButton.nameChangeRunning = false
                        accountSettings.headerName =
                            Qt.binding(() => accountInfo.display_name)
                    })
                }
            )
        }

        if (aliasField.changed) {
            window.settings.writeAliases[userId] = aliasField.item.text
            window.settingsChanged()
        }

        if (avatar.changed) {
            saveButton.avatarChangeRunning = true

            const path =
                Qt.resolvedUrl(avatar.sourceOverride).replace(/^file:/, "")

            py.callClientCoro(userId, "set_avatar_from_file", [path], () => {
                py.callClientCoro(userId, "update_own_profile", [], () => {
                    saveButton.avatarChangeRunning = false
                })
            }, (errType, [httpCode]) => {
                console.error("Avatar upload failed:", httpCode, errType)
                saveButton.avatarChangeRunning = false
            })
        }
    }

    function cancelChanges() {
        nameField.item.text     = accountInfo.display_name
        aliasField.item.text    = aliasField.currentAlias
        fileDialog.selectedFile = ""
        fileDialog.file         = ""

        accountSettings.headerName = Qt.binding(() => accountInfo.display_name)
    }

    columns: 2
    flow: pageLoader.isWide ? GridLayout.LeftToRight : GridLayout.TopToBottom
    rowSpacing: currentSpacing

    Component.onCompleted: nameField.item.forceActiveFocus()

    HUserAvatar {
        property bool changed: Boolean(sourceOverride)

        id: avatar
        userId: accountSettings.userId
        displayName: nameField.item.text
        mxc: accountInfo.avatar_url
        toolTipMxc: ""
        sourceOverride: fileDialog.selectedFile || fileDialog.file

        Layout.alignment: Qt.AlignHCenter

        Layout.preferredWidth: Math.min(flickable.height, avatarPreferredSize)
        Layout.preferredHeight: Layout.preferredWidth

        Rectangle {
            z: 10
            visible: opacity > 0
            opacity: ! fileDialog.dialog.visible &&
                     ((! avatar.mxc && ! avatar.changed) || avatar.hovered) ?
                     1 : 0

            anchors.fill: parent
            color: utils.hsluv(0, 0, 0,
                (! avatar.mxc && overlayHover.hovered) ? 0.8 : 0.7
            )

            Behavior on opacity { HNumberAnimation {} }
            Behavior on color { HColorAnimation {} }

            HoverHandler { id: overlayHover }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                cursorShape:
                    overlayHover.hovered ?
                    Qt.PointingHandCursor : Qt.ArrowCursor
            }

            HColumnLayout {
                anchors.centerIn: parent
                spacing: currentSpacing
                width: parent.width

                HIcon {
                    svgName: "upload-avatar"
                    colorize: (! avatar.mxc && overlayHover.hovered) ?
                              theme.colors.accentText : theme.icons.colorize
                    dimension: avatar.width / 3

                    Layout.alignment: Qt.AlignCenter
                }

                Item { Layout.preferredHeight: theme.spacing }

                HLabel {
                    text: avatar.mxc ?
                          qsTr("Change profile picture") :
                          qsTr("Upload profile picture")

                    color: (! avatar.mxc && overlayHover.hovered) ?
                           theme.colors.accentText : theme.colors.brightText
                    Behavior on color { HColorAnimation {} }

                    font.pixelSize: theme.fontSize.big *
                                    avatar.height / avatarPreferredSize
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Qt.AlignHCenter

                    Layout.fillWidth: true
                }
            }
        }

        HFileDialogOpener {
            id: fileDialog
            fileType: HFileDialogOpener.FileType.Images
            dialog.title: qsTr("Select profile picture for %1")
                              .arg(accountInfo.display_name)
        }
    }

    HColumnLayout {
        id: profileInfo
        spacing: theme.spacing

        HColumnLayout {
            spacing: theme.spacing
            Layout.margins: currentSpacing

            HLabel {
                text: qsTr("User ID:<br>%1")
                      .arg(utils.coloredNameHtml(userId, userId, userId))
                textFormat: Text.StyledText
                wrapMode: Text.Wrap

                Layout.fillWidth: true
            }

            HLabeledItem {
                property bool changed: item.text !== accountInfo.display_name

                id: nameField
                label.text: qsTr("Display name:")

                Layout.fillWidth: true
                Layout.maximumWidth: 480

                HTextField {
                    width: parent.width
                    maximumLength: 255

                    onAccepted: applyChanges()
                    onTextChanged: accountSettings.headerName = text
                    Component.onCompleted: text = accountInfo.display_name

                    Keys.onEscapePressed: cancelChanges()
                }
            }

            HLabeledItem {
                property string currentAlias: aliases[userId] || ""
                property bool changed: item.text !== currentAlias

                readonly property var aliases: window.settings.writeAliases

                readonly property string alreadyTakenBy: {
                    if (! item.text) return ""

                    for (const [id, idAlias] of Object.entries(aliases))
                        if (id !== userId && idAlias === item.text) return id

                    return ""
                }


                id: aliasField

                label.text: qsTr("Composer alias:")

                errorLabel.text:
                    alreadyTakenBy ?
                    qsTr("Taken by %1").arg(alreadyTakenBy) :
                    ""

                toolTip.text: qsTr(
                    "From any chat, start a message with specified alias " +
                    "followed by a space to type and send as this " +
                    "account.\n" +
                    "The account must have permission to talk in the room.\n"+
                    "To ignore the alias when typing, prepend it with a space."
                )

                Layout.fillWidth: true
                Layout.maximumWidth: 480

                HTextField {
                    width: parent.width
                    error: aliasField.alreadyTakenBy !== ""
                    onAccepted: applyChanges()
                    placeholderText: qsTr("e.g. %1").arg((
                        nameField.item.text ||
                        accountInfo.display_name ||
                        userId.substring(1)
                    )[0])

                    Component.onCompleted: text = aliasField.currentAlias

                    Keys.onEscapePressed: cancelChanges()
                }
            }
        }

        HRowLayout {
            Layout.alignment: Qt.AlignBottom

            HButton {
                property bool nameChangeRunning: false
                property bool avatarChangeRunning: false

                id: saveButton
                icon.name: "apply"
                icon.color: theme.colors.positiveBackground
                text: qsTr("Save")
                loading: nameChangeRunning || avatarChangeRunning
                enabled:
                    avatar.changed ||
                    nameField.changed ||
                    (aliasField.changed && ! aliasField.alreadyTakenBy)

                onClicked: applyChanges()

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBottom
            }

            HButton {
                icon.name: "cancel"
                icon.color: theme.colors.negativeBackground
                text: qsTr("Cancel")
                enabled: saveButton.enabled && ! saveButton.loading
                onClicked: cancelChanges()

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBottom
            }
        }
    }
}
