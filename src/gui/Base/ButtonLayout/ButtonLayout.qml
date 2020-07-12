// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import ".."

HGridLayout {
    readonly property real summedImplicitWidth: {
        let sum = 0

        for (let i = 0; i < visibleChildren.length; i++) {
            const item = visibleChildren[i]
            if (item) sum += item.width > 0 ? item.implicitWidth : 0
        }

        return sum
    }

    flow:
        width >= summedImplicitWidth ?
        HGridLayout.LeftToRight :
        HGridLayout.TopToBottom
}
