// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12

NumberAnimation {
    property real factor: 1.0
    property real overshoot: 0.0

    duration:
        theme.animationDuration *
        Math.max((1 + Math.abs(overshoot)) / 1.7, 1.0) * factor

    easing.type:
        overshoot > 0 ? Easing.OutBack :
        overshoot < 0 ? Easing.InBack :
        Easing.Linear

    easing.overshoot: overshoot
}
