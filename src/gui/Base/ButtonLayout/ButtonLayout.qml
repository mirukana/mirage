// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import ".."

HGridLayout {
    readonly property int summedImplicitWidth: {
        const widths = []

        for (let i = 0; i < visibleChildren.length; i++) {
            const item = visibleChildren[i]
            if (item) widths.push(item.width > 0 ? item.implicitWidth : 0)
        }

        return utils.sum(widths)
    }

    flow:
        width >= summedImplicitWidth ?
        GridLayout.LeftToRight :
        GridLayout.TopToBottom
}
