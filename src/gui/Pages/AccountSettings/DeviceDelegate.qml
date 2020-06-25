// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../Base/ButtonLayout"
import "../../Base/HTile"

HTile {
    id: device


    property HListView view

    signal renameDeviceRequest(string name)


    backgroundColor: "transparent"
    compact: false

    leftPadding: theme.spacing * 2
    rightPadding: 0

    contentItem: ContentRow {
        tile: device
        spacing: 0

        HCheckBox {
            id: checkBox
            checked: view.checked[model.id] || false
            onClicked: view.toggleCheck(model.index)
        }

        HColumnLayout {
            Layout.leftMargin: theme.spacing

            HRowLayout {
                spacing: theme.spacing

                TitleLabel {
                    text: model.display_name || qsTr("Unnamed")
                }

                TitleRightInfoLabel {
                    tile: device
                    text: utils.smartFormatDate(model.last_seen_date)
                }
            }

            SubtitleLabel {
                tile: device
                font.family: theme.fontFamily.mono
                text:
                    model.last_seen_ip ?
                    model.id + " " + model.last_seen_ip :
                    model.id
            }
        }

        HButton {
            icon.name: "device-action-menu"
            toolTip.text: qsTr("Rename, verify or sign out")
            backgroundColor: "transparent"
            onClicked: contextMenuLoader.active = true

            Layout.fillHeight: true
        }
    }

    contextMenu: HMenu {
        id: actionMenu
        implicitWidth: Math.min(360 * theme.uiScale, window.width)
        onOpened: nameField.forceActiveFocus()

        HLabeledItem {
            width: parent.width
            label.topPadding: theme.spacing / 2
            label.text: qsTr("Public display name:")
            label.horizontalAlignment: Qt.AlignHCenter

            HRowLayout {
                width: parent.width

                HTextField {
                    id: nameField
                    defaultText: model.display_name
                    maximumLength: 255
                    horizontalAlignment: Qt.AlignHCenter
                    onAccepted: renameDeviceRequest(text)

                    Layout.fillWidth: true
                }

                HButton {
                    icon.name: "apply"
                    icon.color: theme.colors.positiveBackground
                    onClicked: renameDeviceRequest(nameField.text)

                    Layout.fillHeight: true
                }
            }
        }

        HMenuSeparator {}

        HLabel {
            id: noKeysLabel
            visible: model.type === "no_keys"
            width: parent.width
            height: visible ? implicitHeight : 0  // avoid empty space

            wrapMode: HLabel.Wrap
            horizontalAlignment: Qt.AlignHCenter
            textFormat: HLabel.RichText
            color: theme.colors.warningText
            text: qsTr(
                "This session doesn't support encryption or " +
                "failed to upload a verification key"
            )
        }

        HMenuSeparator {
            visible: noKeysLabel.visible
            height: visible ? implicitHeight : 0
        }

        HLabeledItem {
            width: parent.width
            label.text: qsTr("Actions:")
            label.horizontalAlignment: Qt.AlignHCenter

            ButtonLayout {
                width: parent.width

                ApplyButton {
                    enabled: [
                        "unset", "ignored", "blacklisted",
                    ].includes(model.type)

                    text: qsTr("Verify")
                    icon.name: "device-verify"
                }

                CancelButton {
                    text: qsTr("Sign out")
                    icon.name: "device-delete"
                }
            }
        }
    }

    onLeftClicked: checkBox.clicked()
}
