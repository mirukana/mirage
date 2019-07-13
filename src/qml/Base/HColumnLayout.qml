// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

ColumnLayout {
    id: columnLayout
    spacing: 0

    property int totalSpacing:
        spacing * Math.max(0, (columnLayout.visibleChildren.length - 1))
}
