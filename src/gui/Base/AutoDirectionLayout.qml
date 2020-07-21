// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12

HGridLayout {
    readonly property real summedImplicitWidth:
        utils.sumChildrenImplicitWidths(visibleChildren, columnSpacing)

    readonly property bool vertical: flow === HGridLayout.TopToBottom


    flow:
        width >= summedImplicitWidth ?
        HGridLayout.LeftToRight :
        HGridLayout.TopToBottom
}
