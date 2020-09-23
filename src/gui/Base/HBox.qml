// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12

HColumnPage {
    implicitWidth: Math.min(parent.width, theme.controls.box.defaultWidth)
    padding: theme.spacing

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
