// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../Base"

HLabel {
    property QtObject indicatorTheme
    property int unreads: 0
    property int highlights: 0
    property bool localUnreads: false
    property bool localHighlights: false

    text:
        unreads >= 1000000 ? Math.floor(unreads / 1000000) + "M" :
        unreads >= 1000 ? Math.floor(unreads / 1000) + "K" :
        unreads ? unreads :
        localUnreads ? "!"  :
        ""

    font.pixelSize: theme.fontSize.small
    font.bold: text === "!"
    verticalAlignment: Qt.AlignVCenter
    leftPadding: theme.spacing / 4
    rightPadding: leftPadding

    scale: text ? 1 : 0
    visible: text !== ""

    background: Rectangle {
        color:
            highlights || (! unreads && localUnreads && localHighlights) ?
            indicatorTheme.mentionBackground :
            indicatorTheme.background

        radius: theme.radius / 4

        Behavior on color { HColorAnimation {} }
    }

    Behavior on scale { HNumberAnimation {} }
}
