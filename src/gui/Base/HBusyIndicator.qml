// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12

HCircleProgressBar {
    progress: 0.5

    label.visible: false
    baseCircle.strokeWidth: 2
    progressCircle.strokeWidth: 2

    HNumberAnimation on rotation {
        from: 0
        to: 360
        loops: Animation.Infinite
        duration: theme ? (theme.animationDuration * 6) : 600
    }
}
