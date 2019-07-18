// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12

HRectangle {
    property bool checkable: false  // TODO
    property bool checked: false

    property color normalColor: theme.controls.listEntry.background
    property color hoveredColor: theme.controls.listEntry.hoveredBackground
    property color pressedColor: theme.controls.listEntry.pressedBackground
    property color checkedColor: theme.controls.listEntry.checkedBackground

    color: checked ? checkedColor :
           // tap.pressed ? pressedColor :
           hover.hovered ? hoveredColor :
           normalColor

    Behavior on color { HColorAnimation { factor: 0.66 } }

    HoverHandler { id: hover }
    TapHandler { id: tap }
}
