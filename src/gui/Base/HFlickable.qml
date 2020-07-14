// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

Flickable {
    maximumFlickVelocity: window.settings.kineticScrollingMaxSpeed
    flickDeceleration: window.settings.kineticScrollingDeceleration

    ScrollBar.vertical: HScrollBar {
        visible: parent.interactive
    }
}
