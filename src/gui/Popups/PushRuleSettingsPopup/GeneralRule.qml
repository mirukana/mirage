// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../Base/Buttons"

HColumnLayout {
    readonly property alias idField: idField

    readonly property var matrixConditions: {
        const results = []

        for (let i = 0; i < conditionRepeater.count; i++) {
            results.push(conditionRepeater.itemAt(i).control.matrixObject)
        }

        return results
    }

    spacing: theme.spacing / 2

    HLabeledItem {
        label.text: rule.default ? qsTr("Rule ID:") : qsTr("Rule name:")
        Layout.fillWidth: true

        HTextField {
            id: idField
            width: parent.width
            defaultText: rule.rule_id
            // TODO: minimum length, check no dupe
        }
    }

    HRowLayout {
        Layout.topMargin: theme.spacing / 2

        CustomLabel {
            text: qsTr("Conditions for a message to trigger this rule:")
        }

        PositiveButton {
            icon.name: "pushrule-condition-add"
            iconItem.small: true
            Layout.fillHeight: true
            Layout.fillWidth: false
            onClicked: addConditionMenu.open()

            HMenu {
                id: addConditionMenu
                x: -width + parent.width
                y: parent.height

                HMenuItem {
                    text: qsTr("Room has a certain number of members")
                }
                HMenuItem {
                    text: qsTr("Message property matches value")
                }
                HMenuItem {
                    text: qsTr("Message contains my display name")
                }
                HMenuItem {
                    text: qsTr(
                        "Sender has permission to trigger special notification"
                    )
                }
                HMenuItem {
                    text: qsTr("Custom JSON condition")
                }
            }
        }
    }

    CustomLabel {
        text: qsTr("No conditions added, all messages will match")
        color: theme.colors.dimText
        visible: Layout.preferredHeight > 0
        Layout.preferredHeight: conditionRepeater.count ? 0 : implicitHeight

        Behavior on Layout.preferredHeight { HNumberAnimation {} }
    }

    Repeater {
        id: conditionRepeater
        model: JSON.parse(rule.conditions)

        HRowLayout {
            readonly property Item control: loader.item

            spacing: theme.spacing

            HLoader {
                id: loader

                readonly property var condition: modelData
                readonly property string filename:
                    modelData.kind === "event_match" ?
                    "PushEventMatch" :
                    modelData.kind === "contains_display_name" ?
                    "PushContainsDisplayName" :
                    modelData.kind === "room_member_count" ?
                    "PushRoomMemberCount" :
                    modelData.kind === "sender_notification_permission" ?
                    "PushSenderNotificationPermission" :
                    "PushUnknownCondition"

                asynchronous: false
                source: "PushConditions/" + filename + ".qml"
                Layout.fillWidth: true
            }

            NegativeButton {
                icon.name: "pushrule-condition-remove"
                iconItem.small: true
                Layout.fillHeight: true
                Layout.fillWidth: false
            }
        }
    }
}
