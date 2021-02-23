// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ".."
import "../.."
import "../../Base"
import "../../Base/Buttons"

HFlickableColumnPopup {
    id: root

    property string userId
    // A rule item from ModelStore.get(userId, "pushrules")
    property var rule
    property bool ruleExists: true

    readonly property bool generalChecked:
        overrideRadio.checked || underrideRadio.checked

    readonly property string checkedKind:
        overrideRadio.checked ? "override" :
        contentRadio.checked ? "content" :
        roomRadio.checked ? "room" :
        senderRadio.checked ? "sender" :
        "underride"

    function save() {
        const details = swipeView.currentItem
        const isBefore = positionCombo.currentIndex === 0
        const position =
            positionCombo.visible && ! positionCombo.isCurrent ?
            positionCombo.model[positionCombo.currentIndex].rule_id :
            undefined

        const args = [
            checkedKind,
            details.idField.text,
            rule.kind,
            rule.rule_id,
            isBefore && position ? position : undefined,
            ! isBefore && position ? position : undefined,
            enableCheck.checked,
            generalChecked ? details.matrixConditions : undefined,
            contentRadio.checked ? details.idField.text : undefined,
        ]

        py.callClientCoro(userId, "edit_pushrule", args, root.close)
    }

    function remove() {
        const args = [rule.kind, rule.rule_id]
        py.callClientCoro(userId, "remove_pushrule", args, root.close)
    }

    page.implicitWidth: Math.min(maximumPreferredWidth, 550 * theme.uiScale)

    page.footer: AutoDirectionLayout {
        ApplyButton {
            text: qsTr("Save changes")
            enabled: true  // TODO
            onClicked: root.save()
        }

        CancelButton {
            text: qsTr("Cancel changes")
            onClicked: root.close()
        }

        NegativeButton {
            icon.name: "pushrule-remove"
            text: qsTr("Remove rule")
            enabled: ! root.rule.default
            onClicked: root.remove()
        }
    }

    CustomLabel {
        visible: root.rule.default
        text: qsTr("Some settings cannot be changed for default server rules")
        color: theme.colors.warningText
    }

    HColumnLayout {
        enabled: ! root.rule.default
        spacing: theme.spacing / 2

        CustomLabel {
            text: qsTr("Rule type:")
        }

        HRadioButton {
            id: overrideRadio
            text: "High priority general rule"
            subtitle.text: qsTr(
                "Control notifications for messages matching certain " +
                "conditions"
            )
            defaultChecked: root.rule.kind === "override"
            Layout.fillWidth: true
        }

        HRadioButton {
            id: contentRadio
            text: "Message content rule"
            subtitle.text: qsTr(
                "Control notifications for text messages containing a " +
                "certain word"
            )
            defaultChecked: root.rule.kind === "content"
            Layout.fillWidth: true
        }

        HRadioButton {
            id: roomRadio
            text: "Room rule"
            subtitle.text: qsTr(
                "Control notifications for all messages received in a " +
                "certain room"
            )
            defaultChecked: root.rule.kind === "room"
            Layout.fillWidth: true
        }

        HRadioButton {
            id: senderRadio
            text: "Sender rule"
            subtitle.text: qsTr(
                "Control notifications for all messages sent by a " +
                "certain user"
            )
            defaultChecked: root.rule.kind === "sender"
            Layout.fillWidth: true
        }

        HRadioButton {
            id: underrideRadio
            text: "Low priority general rule"
            subtitle.text: qsTr(
                "A general rule tested only after every other rule types"
            )
            defaultChecked: root.rule.kind === "underride"
            Layout.fillWidth: true
        }
    }

    SwipeView {
        id: swipeView
        enabled: ! root.rule.default
        clip: true
        interactive: false
        currentIndex:
            overrideRadio.checked ? 0 :
            contentRadio.checked ? 1 :
            roomRadio.checked ? 2 :
            senderRadio.checked ? 3 :
            4

        Layout.fillWidth: true

        Behavior on implicitHeight { HNumberAnimation {} }

        GeneralRule { enabled: SwipeView.isCurrentItem }
        ContentRule { enabled: SwipeView.isCurrentItem }
        RoomRule { enabled: SwipeView.isCurrentItem }
        SenderRule { enabled: SwipeView.isCurrentItem }
        GeneralRule { enabled: SwipeView.isCurrentItem }
    }

    HLabeledItem {
        visible: ! rule.default && positionCombo.model.length > 1
        label.text: qsTr("Position:")
        Layout.fillWidth: true

        HComboBox {
            id: positionCombo

            property int currentPosition: 0

            readonly property string name:
                ! model.length ?  "" : utils.stripHtmlTags(
                    utils.formatPushRuleName(root.userId, model[currentIndex])
                )

            readonly property bool isCurrent:
                root.ruleExists &&
                model.length &&
                currentIndex === currentPosition &&
                root.rule.kind === root.checkedKind

            width: parent.width
            currentIndex: currentPosition
            displayText:
                ! model.length ? "" :
                isCurrent ?  qsTr("Current") :
                currentIndex === 0 ? qsTr('Before "%1"').arg(name) :
                qsTr('After "%1"').arg(name)

            model: {
                currentPosition = 0

                const choices = []
                const rules   = ModelStore.get(userId, "pushrules")

                for (let i = 0; i < rules.count; i++) {
                    const item = rules.get(i)
                    const isCurrent =
                        item.kind === root.checkedKind &&
                        item.rule_id === root.rule.rule_id

                    if (isCurrent && choices.length)
                        currentPosition = choices.length - 1

                    if (item.kind === root.checkedKind && ! item.default) {
                        if (! choices.length) choices.push(item)
                        if (! isCurrent) choices.push(item)
                    }
                }

                return choices
            }

            delegate: HMenuItem {
                readonly property string name:
                    utils.formatPushRuleName(root.userId, modelData)

                label.textFormat: HLabel.StyledText
                text:
                    root.ruleExists &&
                    model.index === positionCombo.currentPosition &&
                    root.rule.kind === root.checkedKind ?
                    qsTr("Current") :

                    model.index === 0 ?
                    qsTr('Before "%1"').arg(name) :

                    qsTr('After "%1"').arg(name)

                onTriggered: positionCombo.currentIndex = model.index
            }
        }
    }

    HCheckBox {
        id: enableCheck
        text: qsTr("Enable this rule")
        defaultChecked: root.rule.enabled
        Layout.fillWidth: true
    }
}
