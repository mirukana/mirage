// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import ".."

HTile {
    id: tile
    topPadding: padded ? spacing / (compact ? 4 : 2) : 0
    bottomPadding: topPadding

    // onLeftClicked: {
    //     view.highlightRangeMode    = ListView.NoHighlightRange
    //     view.highlightMoveDuration = 0
    //     activated()
    //     view.highlightRangeMode    = ListView.ApplyRange
    //     view.highlightMoveDuration = theme.animationDuration
    // }


    signal activated()

    property HListView view: ListView.view
}
