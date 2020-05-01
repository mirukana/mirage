// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import ".."

HTile {
    id: tile
    topPadding:
        padded ? spacing / (firstInSection ? 1 : 2) / (compact ? 2 : 1) : 0
    bottomPadding:
        padded ? spacing / (lastInSection ? 1 : 2) / (compact ? 2 : 1) : 0

    onLeftClicked: {
        view.highlightRangeMode    = ListView.NoHighlightRange
        view.highlightMoveDuration = 0
        activated()
        view.highlightRangeMode    = ListView.ApplyRange
        view.highlightMoveDuration = theme.animationDuration
    }


    signal activated()

    property HListView view: ListView.view

    readonly property bool firstInSection:
        ListView.previousSection !== ListView.section
    readonly property bool lastInSection:
        ListView.nextSection !== ListView.section
}
