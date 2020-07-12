// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12

NumberAnimation {
    property real factor: 1.0
    property real overshoot: 1.0


    duration: theme.animationDuration * Math.max(overshoot / 1.7, 1.0) * factor
    easing.type: overshoot > 1 ? Easing.OutBack : Easing.Linear
    easing.overshoot: overshoot
}
