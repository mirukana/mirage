// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12

HFlickableColumnPage {
    implicitWidth: Math.min(parent.width, theme.controls.box.defaultWidth)

    background: Rectangle {
        color: theme.controls.box.background
        radius: theme.controls.box.radius
    }

    HNumberAnimation on scale {
        running: true
        from: 0
        to: 1
        overshoot: 2
    }

    Behavior on implicitWidth { HNumberAnimation {} }
    Behavior on implicitHeight { HNumberAnimation {} }
}
