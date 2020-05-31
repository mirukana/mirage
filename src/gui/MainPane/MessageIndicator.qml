// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../Base"

HLabel {
    text:
        unreads >= 1000000 ? Math.floor(unreads / 1000000) + "M" :
        unreads >= 1000 ? Math.floor(unreads / 1000) + "K" :
        unreads

    font.pixelSize: theme.fontSize.small
    verticalAlignment: Qt.AlignVCenter
    leftPadding: theme.spacing / 4
    rightPadding: leftPadding

    scale: unreads === 0 ? 0 : 1
    visible: unreads !== 0

    background: Rectangle {
        color:
            highlights ?
            indicatorTheme.mentionBackground :
            indicatorTheme.background

        radius: theme.radius / 4

        Behavior on color { HColorAnimation {} }
    }


    property QtObject indicatorTheme
    property int unreads: 0
    property int highlights: 0


    Behavior on scale { HNumberAnimation {} }
}
