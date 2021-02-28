// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../.."
import "../../Base"
import "../../Base/HTile"
import "../../Base/Buttons"
import "../../MainPane"
import "../../Popups"

HTile {
    id: root

    property Item page

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
            textFormat: HLabel.StyledText
            text: utils.formatPushRuleName(page.userId, model)

            Layout.fillWidth: true
            Layout.leftMargin: theme.spacing
            Layout.rightMargin: Layout.leftMargin
        }

        HRowLayout {
            PushRuleButton {
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

            PushRuleButton {
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

            PushRuleButton {
                requiresOn: notifyButton
                icon.name: "pushrule-action-bubble"
                toggles: "bubble"
            }

            PushRuleButton {
                requiresOn: notifyButton
                icon.name: "pushrule-action-sound"
                toggles: "sound"
                nextValue:
                    on ? "" :
                    model[toggles] ? model[toggles] :
                    model.rule_id === ".m.rule.call" ? "ring" :
                    "default"
            }

            PushRuleButton {
                requiresOn: notifyButton
                icon.name: "pushrule-action-urgency-hint"
                toggles: "urgency_hint"
            }

            HSpacer {}

            PushRuleButton {
                icon.name: "pushrule-edit"
                onClicked: root.clicked()
            }
        }
    }

    onClicked: window.makePopup(
        "Popups/PushRuleSettingsPopup/PushRuleSettingsPopup.qml",
        {userId: page.userId, rule: model},
    )
}
