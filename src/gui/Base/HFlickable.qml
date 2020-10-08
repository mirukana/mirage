// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

Flickable {
    id: flickable
    maximumFlickVelocity: window.settings.Scrolling.kinetic_max_speed
    flickDeceleration: window.settings.Scrolling.kinetic_deceleration

    ScrollBar.vertical: HScrollBar {
        visible: parent.interactive
        z: 999
        flickableMoving: flickable.moving
    }

    Component.onCompleted: {
        kineticScrollingDisabler = Qt.createComponent(
            "HKineticScrollingDisabler.qml"
        ).createObject(flickable, {flickable})

        kineticScrollingDisabler.width = Qt.binding(() =>
            kineticScrollingDisabler.enabled ? flickable.width : 0
        )
        kineticScrollingDisabler.height = Qt.binding(() =>
            kineticScrollingDisabler.enabled ? flickable.height : 0
        )
    }

    property var kineticScrollingDisabler
}
