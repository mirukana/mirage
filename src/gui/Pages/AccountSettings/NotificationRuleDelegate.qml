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
        model.kind === "Room" ?
        ModelStore.get(page.userId, "rooms").find(model.id) :
        null


    contentOpacity: model.enabled ? 1 : theme.disabledElementsOpacity
    hoverEnabled: false

    contentItem: HColumnLayout {
        spacing: root.spacing / 2

        TitleLabel {
            opacity: model.enabled ? 1 : theme.disabledElementsOpacity
            elide: Text.ElideNone
            wrapMode: HLabel.Wrap

            textFormat:
                model.id === ".m.rule.contains_user_name" ||
                model.id === ".m.rule.roomnotif" ||
                model.kind === "Sender" ?
                HLabel.StyledText :
                HLabel.PlainText

            text:
                model.id === ".m.rule.master" ?
                qsTr("Any message") :

                model.id === ".m.rule.suppress_notices" ?
                qsTr("Messages sent by bots") :

                model.id === ".m.rule.invite_for_me" ?
                qsTr("Received room invites") :

                model.id === ".m.rule.member_event" ?
                qsTr("Membership, name & avatar changes") :

                model.id === ".m.rule.contains_display_name" ?
                qsTr("Messages containing my display name") :

                model.id === ".m.rule.tombstone" ?
                qsTr("Room migration alerts") :

                model.id === ".m.rule.reaction" ?
                qsTr("Emoji reactions") :

                model.id === ".m.rule.roomnotif" ?
                qsTr("Messages containing %1").arg(
                    utils.htmlColorize("@room", theme.colors.accentText),
                ) :

                model.id === ".m.rule.contains_user_name" ?
                qsTr("Contains %1").arg(utils.coloredNameHtml(
                    "", page.userId, page.userId.split(":")[0].substring(1),
                )):

                model.id === ".m.rule.call" ?
                qsTr("Incoming audio calls") :

                model.id === ".m.rule.encrypted_room_one_to_one" ?
                qsTr("Encrypted 1-to-1 messages") :

                model.id === ".m.rule.room_one_to_one" ?
                qsTr("Unencrypted 1-to-1 messages") :

                model.id === ".m.rule.message" ?
                qsTr("Unencrypted group messages") :

                model.id === ".m.rule.encrypted" ?
                qsTr("Encrypted group messages") :

                model.kind === "Content" ?
                qsTr('Contains "%1"').arg(model.pattern) :

                model.kind === "Sender" ?
                utils.coloredNameHtml("", model.id) :

                matchingRoom && matchingRoom.display_name ?
                matchingRoom.display_name :

                model.id

            Layout.fillWidth: true
        }

        HRowLayout {
            NotificationRuleButton {
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
                icon.name: "pushrule-action-bubble"
                toggles: "bubble"
            }

            NotificationRuleButton {
                icon.name: "pushrule-action-sound"
                toggles: "sound"
            }

            NotificationRuleButton {
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
