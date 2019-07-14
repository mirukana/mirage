// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Layouts 1.12

GridLayout {
    id: gridLayout
    rowSpacing: 0
    columnSpacing: 0

    property int totalSpacing:
        spacing * Math.max(0, (gridLayout.visibleChildren.length - 1))
}
