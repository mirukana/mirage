// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12

Timer {
    // Sometimes and randomly, a HListView/HGridView delegate's add/populate
    // Transition will stop too early, leaving a stuck invisible or tiny item.
    // This is a workaround for this Qt bug happening despite the neccessary
    // Transition precautions from the docs being applied.

    property Item delegate: parent

    readonly property HNumberAnimation opacityFixer: HNumberAnimation {
        target: delegate
        property: "opacity"
        from: delegate.opacity
        to: 1
    }

    readonly property HNumberAnimation scaleFixer: HNumberAnimation {
        target: delegate
        property: "scale"
        from: delegate.scale
        to: 1
    }

    interval: theme.animationDuration * 2
    running: true
    onTriggered: {
        // if (delegate.opacity < 1 || delegate.scale < 1) print(delegate)
        if (delegate.opacity < 1) opacityFixer.start()
        if (delegate.scale < 1) scaleFixer.start()
    }
}
