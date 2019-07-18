// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12

HRectangle {
    property bool checkable: false  // TODO
    property bool checked: false

    readonly property QtObject _ir: theme.controls.interactiveRectangle

    property color normalColor: _ir.background
    property color hoveredColor: _ir.hoveredBackground
    property color pressedColor: _ir.pressedBackground
    property color checkedColor: _ir.checkedBackground

    color: checked ? checkedColor :
           // tap.pressed ? pressedColor :
           hover.hovered ? hoveredColor :
           normalColor

    Behavior on color { HColorAnimation { factor: 0.66 } }

    HoverHandler { id: hover }
    TapHandler { id: tap }
}
