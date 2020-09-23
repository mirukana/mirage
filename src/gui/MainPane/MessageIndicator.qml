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
    property bool localHighlights: false

    readonly property bool useHighlightStyle:
        highlights || (! unreads && localUnreads && localHighlights)


    text:
        unreads >= 1000000 ? Math.floor(unreads / 1000000) + "M" :
        unreads >= 1000 ? Math.floor(unreads / 1000) + "K" :
        unreads ? unreads :
        localUnreads ? "!"  :
        ""

    color:
        useHighlightStyle ?
        indicatorTheme.highlightText :
        indicatorTheme.text

    font.pixelSize: theme.fontSize.small
    font.bold:
        useHighlightStyle ?
        indicatorTheme.highlightBold :
        indicatorTheme.bold

    verticalAlignment: Qt.AlignVCenter
    leftPadding: theme.spacing / 3
    rightPadding: leftPadding

    scale: text ? 1 : 0
    visible: text !== ""

    background: Rectangle {
        radius:
            useHighlightStyle ?
            indicatorTheme.highlightRadius :
            indicatorTheme.radius

        color:
            useHighlightStyle ?
            indicatorTheme.highlightBackground :
            indicatorTheme.background

        border.width:
            useHighlightStyle ?
            indicatorTheme.highlightBorderWidth :
            indicatorTheme.borderWidth

        border.color:
            useHighlightStyle ?
            indicatorTheme.highlightBorder :
            indicatorTheme.border

        Behavior on radius { HColorAnimation {} }
        Behavior on color { HColorAnimation {} }
        Behavior on border.color { HColorAnimation {} }
    }

    Behavior on scale { HNumberAnimation {} }
    Behavior on color { HColorAnimation {} }
}
