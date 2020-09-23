// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick.Controls 2.12
import QtQuick 2.12


Repeater {
    id: repeater

    readonly property var childrenImplicitWidth: {
        const widths = []

        for (let i = 0; i < repeater.count; i++) {
            const item = repeater.itemAt(i)

            if (item)
                widths.push(item.implicitWidth > 0 ? item.implicitWidth : 0)
        }

        return widths
    }

    readonly property var childrenWidth: {
        const widths = []

        for (let i = 0; i < repeater.count; i++) {
            const item = repeater.itemAt(i)
            if (item) widths.push(item.width > 0 ? item.width : 0)
        }

        return widths
    }

    readonly property real summedWidth: utils.sum(childrenWidth)
    readonly property real summedImplicitWidth:utils.sum(childrenImplicitWidth)

    readonly property real thinestChild: Math.min(...childrenWidth)
    readonly property real widestChild: Math.max(...childrenWidth)
}
