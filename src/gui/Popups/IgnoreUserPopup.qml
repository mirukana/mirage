// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../Base/Buttons"

HFlickableColumnPopup {
    id: root

    property string userId
    property string targetUserId
    property string targetDisplayName
    property bool ignore

    function apply() {
        py.callClientCoro(userId, "ignore_user", [targetUserId, ignore])
        root.close()
    }

    page.footer: AutoDirectionLayout {
        ApplyButton {
            id: ignoreButton
            icon.name: root.ignore ? "ignore-user" : "stop-ignore-user"
            text: root.ignore ? qsTr("Ignore") : qsTr("Stop ignoring")
            onClicked: root.apply()
        }

        CancelButton {
            onClicked: root.close()
        }
    }

    onOpened: ignoreButton.forceActiveFocus()

    SummaryLabel {
        readonly property string userText:
            utils.coloredNameHtml(root.targetDisplayName, root.targetUserId)

        textFormat: Text.StyledText
        text:
            root.ignore ?
            qsTr("Ignore %1?").arg(userText) :
            qsTr("Stop ignoring %1?").arg(userText)
    }

    DetailsLabel {
        text:
            root.ignore ? qsTr(
                "You will no longer see their messages and invites.\n\n" +

                "Their name, avatar and online status will also be hidden " +
                "in room member lists."
            ) : qsTr(
                "You will receive their messages and room invites again.\n\n" +

                "Their names, avatar and online status will also become " +
                "visible in room member lists.\n\n" +

                "After restarting %1, any message or room invite they had " +
                "sent while being ignored will become visible."
            ).arg(Qt.application.displayName)
    }
}
