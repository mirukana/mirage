// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../.."
import "../../Base"
import "../../Base/HTile"
import "../../MainPane"

HTile {
    id: root

    property Item page

    readonly property QtObject matchingRoom:
        model.kind === "room" ?
        ModelStore.get(page.userId, "rooms").find(model.rule_id) :
        null


    contentOpacity: model.enabled ? 1 : theme.disabledElementsOpacity
    hoverEnabled: false
    leftPadding: theme.spacing / 4
    rightPadding: leftPadding

    contentItem: HColumnLayout {
        spacing: root.spacing / 2

        TitleLabel {
            opacity: model.enabled ? 1 : theme.disabledElementsOpacity
            elide: Text.ElideNone
            wrapMode: HLabel.Wrap

            textFormat:
                model.rule_id === ".m.rule.contains_user_name" ||
                model.rule_id === ".m.rule.roomnotif" ||
                model.kind === "sender" ?
                HLabel.StyledText :
                HLabel.PlainText

            text:
                model.rule_id === ".m.rule.master" ?
                qsTr("Any message") :

                model.rule_id === ".m.rule.suppress_notices" ?
                qsTr("Messages sent by bots") :

                model.rule_id === ".m.rule.invite_for_me" ?
                qsTr("Received room invites") :

                model.rule_id === ".m.rule.member_event" ?
                qsTr("Membership, name & avatar changes") :

                model.rule_id === ".m.rule.contains_display_name" ?
                qsTr("Messages containing my display name") :

                model.rule_id === ".m.rule.tombstone" ?
                qsTr("Room migration alerts") :

                model.rule_id === ".m.rule.reaction" ?
                qsTr("Emoji reactions") :

                model.rule_id === ".m.rule.roomnotif" ?
                qsTr("Messages containing %1").arg(
                    utils.htmlColorize("@room", theme.colors.accentText),
                ) :

                model.rule_id === ".m.rule.contains_user_name" ?
                qsTr("Contains %1").arg(utils.coloredNameHtml(
                    "", page.userId, page.userId.split(":")[0].substring(1),
                )):

                model.rule_id === ".m.rule.call" ?
                qsTr("Incoming audio calls") :

                model.rule_id === ".m.rule.encrypted_room_one_to_one" ?
                qsTr("Encrypted 1-to-1 messages") :

                model.rule_id === ".m.rule.room_one_to_one" ?
                qsTr("Unencrypted 1-to-1 messages") :

                model.rule_id === ".m.rule.message" ?
                qsTr("Unencrypted group messages") :

                model.rule_id === ".m.rule.encrypted" ?
                qsTr("Encrypted group messages") :

                model.kind === "content" ?
                qsTr('Contains "%1"').arg(model.pattern) :

                model.kind === "sender" ?
                utils.coloredNameHtml("", model.rule_id) :

                matchingRoom && matchingRoom.display_name ?
                matchingRoom.display_name :

                model.rule_id

            Layout.fillWidth: true
            Layout.leftMargin: theme.spacing
            Layout.rightMargin: Layout.leftMargin
        }

        HRowLayout {
            NotificationRuleButton {
                id: notifyButton
                toggles: "notify"

                contentItem: MessageIndicator {
                    indicatorTheme:
                        theme.mainPane.listView.room.unreadIndicator
                    unreads: 1
                    text: "+1"
                    font.pixelSize: theme.fontSize.normal
                    topPadding: leftPadding / 3
                    bottomPadding: topPadding
                }
            }

            NotificationRuleButton {
                requiresOn: notifyButton
                toggles: "highlight"

                contentItem: MessageIndicator {
                    indicatorTheme:
                        theme.mainPane.listView.room.unreadIndicator

                    unreads: 1
                    highlights: 1
                    text: "+1"
                    font.pixelSize: theme.fontSize.normal
                    topPadding: leftPadding / 3
                    bottomPadding: topPadding
                }
            }

            NotificationRuleButton {
                requiresOn: notifyButton
                icon.name: "pushrule-action-bubble"
                toggles: "bubble"
            }

            NotificationRuleButton {
                requiresOn: notifyButton
                icon.name: "pushrule-action-sound"
                toggles: "sound"
                nextValue:
                    on ? "" :
                    model[toggles] ? model[toggles] :
                    model.rule_id === ".m.rule.call" ? "ring" :
                    "default"
            }

            NotificationRuleButton {
                requiresOn: notifyButton
                icon.name: "pushrule-action-urgency-hint"
                toggles: "urgency_hint"
            }

            HSpacer {}

            NotificationRuleButton {
                icon.name: "pushrule-edit"
            }
        }
    }
}
