// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12

DragHandler {
    id: root

    property HDrawer drawer
    property bool swiped: false
    property real minimumSwipeDistance:
        Math.min(drawer.implicitWidth / 2, 100) * theme.uiScale

    readonly property HNumberAnimation hide: HNumberAnimation {
        target: drawer
        property: "position"
        to: 0
        onStopped: root.closeRequest()
    }

    readonly property HNumberAnimation cancel: HNumberAnimation {
        target: drawer
        property: "position"
        to: 1
    }

    signal closeRequest()

    target: null

    enabled:
        (drawer.collapse || drawer.forceCollapse) &&
        drawer.visible

    onTranslationChanged: {
        if (hide.running || cancel.running) return

        drawer.position =
            drawer.edge === Qt.LeftEdge ? 1 + translation.x / implicitWidth :
            drawer.edge === Qt.RightEdge ? 1 - translation.x / implicitWidth :
            drawer.edge === Qt.TopEdge ? 1 - translation.y / implicitHeight :
            1 + translation.y / implicitHeight

        const distance = Math.abs(translation[drawer.horizontal ? "x" : "y"])

        if (distance > minimumSwipeDistance) swiped = true
    }

    onSwipedChanged: if (swiped) hide.start()

    onActiveChanged: if (! active) {
        if (! swiped) cancel.start()
        swiped = false
    }
}
