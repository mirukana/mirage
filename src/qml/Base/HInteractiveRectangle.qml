// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12

HRectangle {
    property bool checkable: false  // TODO
    property bool checked: false

    readonly property QtObject _ir: theme.controls.interactiveRectangle
    color: _ir.background

    HRectangle {
        anchors.fill: parent
        visible: opacity > 0

        color: checked ? _ir.checkedOverlay : _ir.hoveredOverlay

        opacity: checked ?       _ir.checkedOpacity :
                 hover.hovered ? _ir.hoveredOpacity :
                 0

        Behavior on opacity { HNumberAnimation { factor: 0.66 } }
    }

    HoverHandler { id: hover }
    TapHandler { id: tap }
}
