// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "Base"

Rectangle {
    color: utils.hsluv(0, 0, 0, 0.5)

    HBusyIndicator {
        anchors.centerIn: parent
        width: Math.min(160, parent.width - 16, parent.height - 16)
        height: width
        indeterminateSpan: 0.5

        foregroundColor: utils.hsluv(240, 60 / 1.5 * 2, 0, 0.7)
        progressColor: utils.hsluv(240, 60 * 1.5, 72)
    }
}
