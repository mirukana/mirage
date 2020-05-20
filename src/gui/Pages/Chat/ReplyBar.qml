// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

InfoBar {
    color: theme.chat.replyBar.background
    icon.svgName: "reply-to"
    label.textFormat: Text.StyledText
    label.text:
        replyToUserId ?
        utils.coloredNameHtml(replyToDisplayName, replyToUserId) :
        ""


    signal cancel()


    property string replyToUserId: ""
    property string replyToDisplayName: ""


    HButton {
        backgroundColor: "transparent"
        icon.name: "reply-cancel"
        icon.color: theme.colors.negativeBackground
        // iconItem.small: true
        // topPadding: 0
        // bottomPadding: topPadding
        onClicked: cancel()

        Layout.fillHeight: true
    }
}
