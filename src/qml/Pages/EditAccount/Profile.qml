// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

HGridLayout {
    function applyChanges() {
        if (nameField.changed) {
            saveButton.nameChangeRunning = true

            py.callClientCoro(
                userId, "set_displayname", [nameField.field.text], () => {
                    saveButton.nameChangeRunning = false
                }
            )
        }

        if (aliasField.changed) {
            window.settings.writeAliases[userId] = aliasField.field.text
            window.settingsChanged()
        }

        if (avatar.changed) {
            saveButton.avatarChangeRunning = true
            let path = Qt.resolvedUrl(avatar.imageUrl).replace(/^file:/, "")

            py.callClientCoro(
                userId, "set_avatar_from_file", [path], response => {
                    saveButton.avatarChangeRunning = false
                    if (response != true) { print(response) }
                }
            )
        }
    }

    function cancelChanges() {
        nameField.field.text    = userInfo.displayName
        aliasField.field.text   = aliasField.currentAlias
        fileDialog.selectedFile = ""
        fileDialog.file         = ""
    }

    columns: 2
    flow: pageStack.isWide ? GridLayout.LeftToRight : GridLayout.TopToBottom
    rowSpacing: currentSpacing

    Component.onCompleted: nameField.field.forceActiveFocus()

    HUserAvatar {
        property bool changed: avatar.imageUrl != avatar.defaultImageUrl

        id: avatar
        userId: editAccount.userId
        imageUrl: fileDialog.selectedFile || fileDialog.file || defaultImageUrl
        toolTipImageUrl: ""

        Layout.alignment: Qt.AlignHCenter

        Layout.preferredWidth: Math.min(flickable.height, avatarPreferredSize)
        Layout.preferredHeight: Layout.preferredWidth

        HRectangle {
            z: 10
            visible: opacity > 0
            opacity: ! fileDialog.dialog.visible &&
                     (! avatar.imageUrl || avatar.hovered) ? 1 : 0
            Behavior on opacity { HNumberAnimation {} }

            anchors.fill: parent
            color: Utils.hsla(0, 0, 0, avatar.imageUrl ? 0.7 : 1)

            HColumnLayout {
                anchors.centerIn: parent
                spacing: currentSpacing
                width: parent.width

                HIcon {
                    svgName: "upload-avatar"
                    dimension: 64
                    Layout.alignment: Qt.AlignCenter
                }

                Item { Layout.preferredHeight: theme.spacing }

                HLabel {
                    text: qsTr("Upload profile picture")
                    color: Utils.hsla(0, 0, 90, 1)
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
                              .arg(userInfo.displayName)
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
                      .arg(Utils.coloredNameHtml(userId, userId, userId))
                textFormat: Text.StyledText
                wrapMode: Text.Wrap

                Layout.fillWidth: true
            }

            HLabeledTextField {
                property bool changed: field.text != userInfo.displayName

                id: nameField
                label.text: qsTr("Display name:")
                field.text: userInfo.displayName
                field.onAccepted: applyChanges()

                Layout.fillWidth: true
                Layout.maximumWidth: 480
            }

            HLabeledTextField {
                property string currentAlias:
                    window.settings.writeAliases[userId] || ""

                property bool changed: field.text != currentAlias

                id: aliasField
                label.text: qsTr("Write alias:")
                field.text: currentAlias
                field.onAccepted: applyChanges()

                Layout.fillWidth: true
                Layout.maximumWidth: 480
            }
        }

        HSpacer {}

        HRowLayout {
            Layout.alignment: Qt.AlignBottom

            HUIButton {
                property bool nameChangeRunning: false
                property bool avatarChangeRunning: false

                id: saveButton
                iconName: "apply"
                text: qsTr("Apply")
                loading: nameChangeRunning || avatarChangeRunning
                enabled:
                    nameField.changed || aliasField.changed || avatar.changed

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBottom

                onClicked: applyChanges()
            }

            HUIButton {
                iconName: "cancel"
                text: qsTr("Cancel")
                enabled: saveButton.enabled && ! saveButton.loading

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBottom

                onClicked: cancelChanges()
            }
        }
    }
}
