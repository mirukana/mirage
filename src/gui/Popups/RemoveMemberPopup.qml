// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../Base/Buttons"

HFlickableColumnPopup {
    id: popup

    property string userId
    property string roomId
    property string targetUserId
    property string targetDisplayName
    property string operation  // "disinvite", "kick" or "ban"

    readonly property string coloredTarget:
        utils.coloredNameHtml(targetDisplayName, targetUserId)


    function remove() {
        py.callClientCoro(
            userId,
            operation === "ban" ?  "room_ban" : "room_kick",
            [roomId, targetUserId, reasonField.item.text || null],
        )

        popup.close()
    }


    page.footer: AutoDirectionLayout {
        ApplyButton {
            text:
                operation === "disinvite" ? qsTr("Disinvite") :
                operation === "kick" ? qsTr("Kick") :
                qsTr("Ban")

            icon.name: operation === "ban" ? "room-ban" : "room-kick"

            onClicked: remove()
        }

        CancelButton {
            onClicked: popup.close()
        }
    }

    onOpened: reasonField.item.forceActiveFocus()
    onKeyboardAccept: popup.remove()

    SummaryLabel {
        textFormat: Text.StyledText
        text:
            operation === "disinvite" ?
            qsTr("Disinvite %1 from the room?").arg(coloredTarget) :

            operation === "kick" ?
            qsTr("Kick %1 out of the room?").arg(coloredTarget) :

            qsTr("Ban %1 from the room?").arg(coloredTarget)
    }

    HLabeledItem {
        id: reasonField
        label.text: qsTr("Optional reason:")

        Layout.fillWidth: true

        HTextField {
            width: parent.width
        }
    }
}
