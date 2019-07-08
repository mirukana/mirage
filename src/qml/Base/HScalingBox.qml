// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.7

HRectangle {
    property real widthForHeight: 0.75
    property int baseHeight: 300
    property int startScalingUpAboveHeight: 1080

    readonly property int baseWidth: baseHeight * widthForHeight
    readonly property int margins: baseHeight * 0.03

    color: theme.box.background
    height: Math.min(parent.height, baseHeight)
    width: Math.min(parent.width, baseWidth)
    scale: Math.max(1, parent.height / startScalingUpAboveHeight)
}
