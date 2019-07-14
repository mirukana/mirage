// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

HGridLayout {
    function applyChanges() {
        saveButton.loading = true

        py.callClientCoro(
            userId, "set_displayname", [nameField.field.text],
            () => { saveButton.loading = false }
        )
    }

    columns: 2
    flow: wide ? GridLayout.LeftToRight : GridLayout.TopToBottom
    rowSpacing: currentSpacing

    Component.onCompleted: nameField.field.forceActiveFocus()

    HUserAvatar {
        id: avatar
        userId: editAccount.userId
        toolTipImageUrl: null

        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: wide ? 0 : currentSpacing

        Layout.preferredWidth: thinMaxWidth
        Layout.preferredHeight: Layout.preferredWidth
    }

    HColumnLayout {
        id: profileInfo
        spacing: normalSpacing

        HColumnLayout {
            spacing: normalSpacing
            Layout.margins: currentSpacing

            HLabel {
                text: qsTr("User ID:<br>%1")
                      .arg(Utils.coloredNameHtml(userId, userId))
                textFormat: Text.StyledText
                wrapMode: Text.Wrap

                Layout.fillWidth: true
            }

            HLabeledTextField {
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
                id: saveButton
                iconName: "save"
                text: qsTr("Save")
                centerText: false
                enabled: nameField.field.text != userInfo.displayName

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
