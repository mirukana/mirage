// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HUIButton {
    property var expandableItem: null

    id: expandButton
    iconName: "expand"
    iconDimension: 16
    backgroundColor: "transparent"
    onClicked: expandableItem.expanded = ! expandableItem.expanded

    iconTransform: Rotation {
        origin.x: expandButton.iconDimension / 2
        origin.y: expandButton.iconDimension / 2
        angle: expandableItem.expanded ? 90 : 180
        Behavior on angle { HNumberAnimation {} }
    }
}
