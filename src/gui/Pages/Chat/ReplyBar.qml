// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

InfoBar {
    property string replyToEventId: ""
    property string replyToUserId: ""
    property string replyToDisplayName: ""

    signal cancel()

    color: theme.chat.replyBar.background
    icon.svgName: "reply-to"
    label.textFormat: Text.StyledText
    label.text:
        replyToEventId ?
        utils.coloredNameHtml(replyToDisplayName, replyToUserId) :
        ""

    HButton {
        backgroundColor: "transparent"
        icon.name: "reply-cancel"
        icon.color: theme.colors.negativeBackground
        topPadding: 0
        bottomPadding: 0
        onClicked: cancel()

        Layout.fillHeight: true
    }
}
