// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../Base"

HLabel {
    id: root

    property QtObject indicatorTheme
    property int unreads: 0
    property int highlights: 0
    property bool localUnreads: false


    text:
        unreads >= 1000000 ? Math.floor(unreads / 1000000) + "M" :
        unreads >= 1000 ? Math.floor(unreads / 1000) + "K" :
        unreads ? unreads :
        localUnreads ? "!"  :
        ""

    color:
        highlights ?
        indicatorTheme.highlightText :
        indicatorTheme.text

    font.pixelSize: theme.fontSize.small
    font.bold:
        highlights ?
        indicatorTheme.highlightBold :
        indicatorTheme.bold

    verticalAlignment: Qt.AlignVCenter
    leftPadding: theme.spacing / 3
    rightPadding: leftPadding

    scale: text ? 1 : 0
    visible: text !== ""

    background: Rectangle {
        radius:
            highlights ?
            indicatorTheme.highlightRadius :
            indicatorTheme.radius

        color:
            highlights ?
            indicatorTheme.highlightBackground :
            indicatorTheme.background

        border.width:
            highlights ?
            indicatorTheme.highlightBorderWidth :
            indicatorTheme.borderWidth

        border.color:
            highlights ?
            indicatorTheme.highlightBorder :
            indicatorTheme.border

        Behavior on radius { HColorAnimation {} }
        Behavior on color { HColorAnimation {} }
        Behavior on border.color { HColorAnimation {} }
    }

    Behavior on scale { HNumberAnimation {} }
    Behavior on color { HColorAnimation {} }
}
