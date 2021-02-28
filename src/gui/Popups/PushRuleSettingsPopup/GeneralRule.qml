// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../Base/Buttons"

HColumnLayout {
    id: root

    readonly property alias idField: idField

    readonly property var matrixConditions: {
        const results = []

        for (let i = 0; i < conditionRepeater.count; i++)
            results.push(conditionRepeater.itemAt(i).control.matrixObject)

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
        }
    }

    HRowLayout {
        Layout.topMargin: theme.spacing / 2

        CustomLabel {
            text: qsTr("Conditions for messages to trigger this rule:")
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
                    onTriggered: conditionRepeater.model.append({
                        kind: "room_member_count",
                        is: "2",
                    })
                }
                HMenuItem {
                    text: qsTr("Message property matches value")
                    onTriggered: conditionRepeater.model.append({
                        kind: "event_match",
                        key: "content.body",
                        pattern: "",
                    })
                }
                HMenuItem {
                    text: qsTr("Message contains my display name")
                    onTriggered: conditionRepeater.model.append({
                        kind: "contains_display_name",
                    })
                }
                HMenuItem {
                    text: qsTr(
                        "Sender has permission to trigger special notification"
                    )
                    onTriggered: conditionRepeater.model.append({
                        kind: "sender_notification_permission",
                        key: "room",
                    })
                }
                HMenuItem {
                    text: qsTr("Custom JSON condition")
                    onTriggered: conditionRepeater.model.append({
                        condition: ({kind: "example"}),
                    })
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
        model: ListModel {}

        Component.onCompleted: {
            // Dummy item to setup all the possible roles for this model
            model.append({
                kind: "", key: "", pattern: "", condition: {}, is: ""
            })
            for (const c of JSON.parse(rule.conditions)) model.append(c)
            model.remove(0)
        }

        HRowLayout {
            readonly property Item control: loader.item

            spacing: theme.spacing

            HLoader {
                id: loader

                readonly property var condition: model
                readonly property string filename:
                    model.kind === "event_match" ?
                    "PushEventMatch" :
                    model.kind === "contains_display_name" ?
                    "PushContainsDisplayName" :
                    model.kind === "room_member_count" ?
                    "PushRoomMemberCount" :
                    model.kind === "sender_notification_permission" ?
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
                onClicked: conditionRepeater.model.remove(model.index)
            }
        }
    }
}
