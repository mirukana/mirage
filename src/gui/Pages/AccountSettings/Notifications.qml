// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../.."
import "../../Base"
import "../../Base/Buttons"
import "../../PythonBridge"
import "../../ShortcutBundles"

HListView {
    id: root

    property string userId

    property bool enableFlickShortcuts:
        SwipeView ? SwipeView.isCurrentItem : true

    function takeFocus() {
        // deviceList.headerItem.exportButton.forceActiveFocus()
    }


    clip: true
    model: ModelStore.get(userId, "pushrules")
    bottomMargin: theme.spacing
    implicitHeight: Math.min(window.height, contentHeight + bottomMargin)

    section.property: "kind"
    section.delegate: HLabel {
        width: root.width
        topPadding: padding * (section === "Override" ? 1 : 1.5)
        padding: theme.spacing
        font.pixelSize: theme.fontSize.big
        text:
            section === "Override" ? qsTr("High-priority general rules") :
            section === "Content" ? qsTr("Message text rules") :
            section === "Room" ? qsTr("Room rules") :
            section === "Sender" ? qsTr("Sender rules") :
            qsTr("General rules")
    }

    delegate: NotificationRuleDelegate {
        userId: root.userId
        width: root.width
    }

    Layout.fillWidth: true
    Layout.fillHeight: true

    FlickShortcuts {
        flickable: root
        active: ! mainUI.debugConsole.visible && root.enableFlickShortcuts
    }
}
