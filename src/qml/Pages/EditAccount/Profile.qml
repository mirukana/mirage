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

        if (avatar.changed) {
            saveButton.avatarChangeRunning = true
            var path = Qt.resolvedUrl(avatar.imageUrl).replace(/^file:/, "")

            py.callClientCoro(
                userId, "set_avatar_from_file", [path], response => {
                    saveButton.avatarChangeRunning = false
                    if (response != true) { print(response) }
                }
            )
        }
    }

    columns: 2
    flow: wide ? GridLayout.LeftToRight : GridLayout.TopToBottom
    rowSpacing: currentSpacing

    Component.onCompleted: nameField.field.forceActiveFocus()

    HUserAvatar {
        property bool changed: avatar.imageUrl != avatar.defaultImageUrl

        id: avatar
        userId: editAccount.userId
        imageUrl: fileDialog.selectedFile || defaultImageUrl
        toolTipImageUrl: null

        Layout.alignment: Qt.AlignHCenter

        Layout.preferredWidth: Math.min(flickable.height, avatarPreferredSize)
        Layout.preferredHeight: Layout.preferredWidth

        HRectangle {
            z: 10
            visible: opacity > 0
            opacity: ! avatar.imageUrl || avatar.hovered ? 1 : 0
            Behavior on opacity { HNumberAnimation {} }

            anchors.fill: parent
            color: Qt.hsla(0, 0, 0, avatar.imageUrl ? 0.7 : 1)

            HColumnLayout {
                anchors.centerIn: parent
                spacing: currentSpacing

                HIcon {
                    svgName: "upload_avatar"
                    dimension: 64
                    Layout.alignment: Qt.AlignCenter
                }

                Item { Layout.preferredHeight: 8 }

                HLabel {
                    text: qsTr("Upload profile picture")
                    color: Qt.hsla(0, 0, 0.9, 1)
                    font.pixelSize: theme.fontSize.big
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignCenter
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
        spacing: normalSpacing

        HColumnLayout {
            spacing: normalSpacing
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
        }

        HSpacer {}

        HRowLayout {
            Layout.alignment: Qt.AlignBottom

            HUIButton {
                property bool nameChangeRunning: false
                property bool avatarChangeRunning: false

                id: saveButton
                iconName: "save"
                text: qsTr("Save")
                centerText: false
                loading: nameChangeRunning || avatarChangeRunning
                enabled: nameField.changed || avatar.changed

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBottom

                onClicked: applyChanges()
            }

            HUIButton {
                iconName: "cancel"
                text: qsTr("Cancel")
                centerText: false

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBottom
                enabled: saveButton.enabled && ! saveButton.loading

                onClicked: {
                    nameField.field.text = userInfo.displayName
                }
            }
        }
    }
}
