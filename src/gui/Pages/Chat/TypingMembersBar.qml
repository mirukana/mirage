// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

InfoBar {
    color: theme.chat.typingMembers.background
    icon.svgName: "typing"  // TODO: animate
    label.textFormat: Text.StyledText
    label.text: {
        const tm = typingMembers

        if (tm.length === 0) return ""
        if (tm.length === 1) return qsTr("%1 is typing...").arg(tm[0])

        return qsTr("%1 and %2 are typing...")
               .arg(tm.slice(0, -1).join(", ")).arg(tm.slice(-1)[0])
    }


    property var typingMembers: []
}
