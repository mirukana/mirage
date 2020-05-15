// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

// Mouse area model to fix scroll on trackpad
MouseArea {
    id: mouseArea
    propagateComposedEvents: true
    z: flickable.z + 1

    onWheel: {
        wheel.accepted = false // Disable wheel to avoid too much scroll

        var pos = getNewPosition(flickable, wheel)
        flickable.flick(0, 0)
        flickable.contentY = pos
        cancelFlickTimer.start() // Stop the flick
    }

    // Required assignment for flickable scroll to work.
    // It must be specified when using this class.
    property Flickable flickable

    function getNewPosition(flickable, wheel) {
        // wheel.pixelDelta will be available on high resolution trackpads.
        // Otherwise use wheel.angleDelta, which is available from mouses and
        // low resolution trackpads.
        // When higher pixelDelta, more scroll will be applied
        var pixelDelta = wheel.pixelDelta.y || (wheel.angleDelta.y / 8)

        // Return current position if there was not any movement
        if (flickable.contentHeight < flickable.height || !pixelDelta)
            return flickable.contentY

        var maxScroll = (
            flickable.contentHeight +
            flickable.originY       +
            flickable.bottomMargin
        ) - flickable.height
        var minScroll = flickable.topMargin + flickable.originY

        // Avoid overscrolling
        return Math.max(
            minScroll,
            Math.min(maxScroll, flickable.contentY - pixelDelta)
        )
    }

    Timer {
        id: cancelFlickTimer
        interval: 100 // Flick duration in ms
        onTriggered: {
            flickable.cancelFlick()
            // print("aaa")
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "red"
        border.width: 5
    }
}
