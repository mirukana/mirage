// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../.."
import "../../Base"
import "../../Base/Buttons"
import "../../ShortcutBundles"

HListView {
    id: root

    property string userId

    property bool enableFlickShortcuts:
        SwipeView ? SwipeView.isCurrentItem : true

    // {model.id: {notify, highlight, bubble, sound, urgency_hint}}
    property var pendingEdits: ({})
    property string saveFutureId: ""

    function takeFocus() {
        // deviceList.headerItem.exportButton.forceActiveFocus() TODO
    }

    function save() {
        const args = []

        for (const [modelId, kwargs] of Object.entries(pendingEdits)) {
            if (! model.find(modelId)) continue  // pushrule was deleted

            const [kind, rule_id] = JSON.parse(modelId)
            args.push(Object.assign({}, {kind, rule_id}, kwargs))
        }

        saveFutureId = py.callClientCoro(
            userId,
            "mass_tweak_pushrules_actions",
            args,
            () => {
                if (! root) return
                saveFutureId = ""
                pendingEdits = {}
            }
        )
    }


    clip: true
    model: ModelStore.get(userId, "pushrules")
    implicitHeight: Math.min(window.height, contentHeight + bottomMargin)

    header: HColumnLayout {
        width: root.width

        HLoader {
            source: "../../Base/HBusyIndicator.qml"
            active: root.model.count === 0
            opacity: active ? 1 : 0
            visible: opacity > 0

            Behavior on opacity { HNumberAnimation {} }

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: theme.spacing
        }
    }

    section.property: "kind"
    section.delegate: HRowLayout {
        width: root.width

        HLabel {
            padding: theme.spacing
            font.pixelSize: theme.fontSize.big
            text:
                section === "override" ? qsTr("High priority general rules") :
                section === "content" ? qsTr("Message content rules") :
                section === "room" ? qsTr("Room rules") :
                section === "sender" ? qsTr("Sender rules") :
                qsTr("Low priority general rules")

            Layout.fillWidth: true
        }

        PositiveButton {
            readonly property var newRule: ({
                id: '[section, ""]',
                kind: section,
                rule_id: "",
                order: 0,
                default: false,
                enabled: true,
                conditions: "[]",
                pattern: "",
                actions: "[]",
                notify: false,
                highlight: false,
                bubble: false,
                sound: false,
                urgency_hint: false,
            })

            backgroundColor: "transparent"
            icon.name: "pushrule-add"
            iconItem.small: true
            Layout.fillHeight: true
            Layout.fillWidth: false
            onClicked: window.makePopup(
                "Popups/PushRuleSettingsPopup/PushRuleSettingsPopup.qml",
                {userId: root.userId, rule: newRule, ruleExists: false},
            )
        }
    }

    delegate: NotificationRuleDelegate {
        page: root
        width: root.width
    }

    onPendingEditsChanged:
        utils.isEmptyObject(pendingEdits) ?
        autoSaveTimer.stop() :
        autoSaveTimer.restart()

    Component.onDestruction: ! utils.isEmptyObject(pendingEdits) && save()

    Timer {
        id: autoSaveTimer
        interval: 10000
        onTriggered: root.save()
    }

    FlickShortcuts {
        flickable: root
        active: ! mainUI.debugConsole.visible && root.enableFlickShortcuts
    }
}
