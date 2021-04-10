// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../.."
import "../../Base"
import "../../Base/Buttons"
import "../../Dialogs"

HFlickableColumnPage {
    id: page

    property string userId
    readonly property QtObject account: ModelStore.get("accounts").find(userId)
    readonly property bool ready: account && account.profile_updated >= new Date(1)

    function takeFocus() {
        nameField.item.forceActiveFocus()
    }

    function applyChanges() {
        if (nameField.item.changed) {
            saveButton.nameChangeRunning = true

            py.callClientCoro(
                userId, "set_displayname", [nameField.item.text], () => {
                    py.callClientCoro(userId, "update_own_profile", [], () => {
                        saveButton.nameChangeRunning = false
                    })
                }
            )
        }

        if (aliasFieldItem.changed) {
            window.settings.Chat.Composer.Aliases[userId] =
                aliasFieldItem.text

            window.saveSettings()
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

    function cancel() {
        if (
            ! nameField.item.changed &&
            ! aliasFieldItem.changed &&
            ! fileDialog.selectedFile &&
            ! fileDialog.file
        ) {
            pageLoader.showPrevious() || mainUI.mainPane.toggleFocus()
            return
        }

        nameField.item.reset()
        aliasFieldItem.reset()
        fileDialog.selectedFile = ""
        fileDialog.file         = ""
    }

    footer: AutoDirectionLayout {
        ApplyButton {
            id: saveButton

            property bool nameChangeRunning: false
            property bool avatarChangeRunning: false

            disableWhileLoading: false
            loading: nameChangeRunning || avatarChangeRunning
            enabled:
                avatar.changed ||
                nameField.item.changed ||
                (aliasFieldItem.changed && ! aliasFieldItem.error)

            onClicked: applyChanges()
        }

        CancelButton {
            enabled: ! saveButton.loading
            onClicked: cancel()
        }
    }

    onKeyboardAccept: if (saveButton.enabled) saveButton.clicked()
    onKeyboardCancel: cancel()

    HUserAvatar {
        id: avatar

        property bool changed: Boolean(sourceOverride)

        clientUserId: page.userId
        userId: page.userId
        displayName: nameField.item.text
        mxc: account ? account.avatar_url : ""
        toolTipMxc: ""
        sourceOverride: fileDialog.selectedFile || fileDialog.file

        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        // Layout.preferredWidth: 256 * theme.uiScale
        Layout.preferredHeight: width

        Rectangle {
            anchors.fill: parent
            z: 10
            visible: opacity > 0
            opacity:
                ! fileDialog.dialog.visible &&
                (
                    (! avatar.mxc && ! avatar.changed) ||
                    avatar.hovered ||
                    ! ready ||
                    account.presence === "offline"
                ) ?
                1 :
                0

            color: utils.hsluv(
                0, 0, 0, (! avatar.mxc && overlayHover.hovered) ? 0.8 : 0.7,
            )

            Behavior on opacity { HNumberAnimation {} }
            Behavior on color { HColorAnimation {} }

            HoverHandler { id: overlayHover }

            MouseArea {
                anchors.fill: parent
                enabled: ready && account.presence !== "offline"
                acceptedButtons: Qt.NoButton
                cursorShape:
                    overlayHover.hovered ?
                    Qt.PointingHandCursor : Qt.ArrowCursor
            }

            HLoader {
                anchors.centerIn: parent
                width: avatar.width / 3
                height: width

                source: "../../Base/HBusyIndicator.qml"
                active: ! ready
                opacity: active ? 1 : 0
                visible: opacity > 0

                Behavior on opacity { HNumberAnimation {} }
            }

            HColumnLayout {
                anchors.centerIn: parent
                spacing: currentSpacing
                width: parent.width
                opacity: ready && account.presence !== "offline" ? 1 : 0
                visible: opacity > 0

                Behavior on opacity { HNumberAnimation {} }

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

                    font.pixelSize: Math.max(
                        theme.fontSize.big * avatar.width / 300,
                        theme.fontSize.small,
                    )
                    wrapMode: HLabel.WordWrap
                    horizontalAlignment: Qt.AlignHCenter

                    Layout.fillWidth: true
                }
            }
        }

        HFileDialogOpener {
            id: fileDialog
            enabled: ready
            fileType: HFileDialogOpener.FileType.Images
            dialog.title: qsTr("Select profile picture for %1")
                              .arg(account ? account.display_name : "")
        }
    }

    HLabeledItem {
        label.text: qsTr("User ID:")

        Layout.fillWidth: true

        HRowLayout {
            width: parent.width

            HTextArea {
                id: idArea
                textFormat: HSelectableLabel.RichText
                wrapMode: HLabel.Wrap
                readOnly: true
                radius: 0
                text: utils.coloredNameHtml("", userId, userId)

                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            FieldCopyButton {
                textControl: idArea
            }
        }
    }

    HLabeledItem {
        id: nameField
        loading: ! ready
        label.text: qsTr("Display name:")

        Layout.fillWidth: true

        HTextField {
            width: parent.width
            enabled: ready && account.presence !== "offline"
            defaultText: ready ? account.display_name : ""
            maximumLength: 255

            // TODO: Qt 5.14+: use a Binding enabled when text not empty
            color: utils.nameColor(text)
        }
    }

    HLabeledItem {
        id: aliasField

        readonly property var aliases: window.settings.Chat.Composer.Aliases
        readonly property string currentAlias: aliases[userId] || ""

        readonly property bool hasWhiteSpace: /\s/.test(item.text)

        readonly property string alreadyTakenBy: {
            if (! item.text) return ""

            for (const [id, idAlias] of Object.entries(aliases))
                if (id !== userId && idAlias === item.text) return id

            return ""
        }

        label.text: qsTr("Composer alias:")

        errorLabel.text:
            hasWhiteSpace ? qsTr("Alias cannot include spaces") :
            alreadyTakenBy ? qsTr("Taken by %1").arg(alreadyTakenBy) :
            ""

        Layout.fillWidth: true

        HRowLayout {
            width: parent.width

            HTextField {
                id: aliasFieldItem
                error: aliasField.hasWhiteSpace || aliasField.alreadyTakenBy
                defaultText: aliasField.currentAlias
                placeholderText: qsTr("e.g. %1").arg((
                    nameField.item.text ||
                    (ready && account.display_name) ||
                    userId.substring(1)
                )[0])

                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            FieldHelpButton {
                helpText: qsTr(
                    "From any chat, start a message with specified alias " +
                    "followed by a space to type and send as this account.\n" +
                    "The account must have permission to talk in the room.\n"+
                    "To ignore the alias when typing, prepend it with a space."
                )
            }
        }
    }
}
