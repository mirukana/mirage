// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12

// MouseArea component to fix scroll on trackpad
MouseArea {
    id: mouseArea
    enabled: window.settings.useTrackpadFix
    propagateComposedEvents: true
    acceptedButtons: Qt.NoButton


    onWheel: {
        // Make components below the stack notice the wheel event
        wheel.accepted = false

        const pos = getNewPosition(flickable, wheel)
        flickable.flick(0, 0)
        flickable.contentY = pos
    }


    property Flickable flickable: parent
    property int scrollFactor: 5

    // Used to get default flickDeceleration value
    readonly property Flickable dummy: Flickable {}


    function getNewPosition(flickable, wheel) {
        // wheel.pixelDelta will be available on high resolution trackpads.
        // Otherwise use wheel.angleDelta, which is available from mouses and
        // low resolution trackpads.
        // When higher pixelDelta, more scroll will be applied
        const pixelDelta =
            wheel.pixelDelta.y ||
            wheel.angleDelta.y /
                24 *
                Qt.styleHints.wheelScrollLines *
                scrollFactor

        // Return current position if there was not any movement
        if (flickable.contentHeight < flickable.height || !pixelDelta)
            return flickable.contentY

        const maxScroll =
            flickable.contentHeight +
            flickable.originY       +
            flickable.bottomMargin  -
            flickable.height
        const minScroll = flickable.topMargin + flickable.originY

        // Avoid overscrolling
        return Math.max(
            minScroll,
            Math.min(maxScroll, flickable.contentY - pixelDelta)
        )
    }


    Binding {
        target: flickable
        property: "maximumFlickVelocity"
        value: mouseArea.enabled ? scrollFactor : 4000.0
    }

    Binding {
        target: flickable
        property: "flickDeceleration"
        value: mouseArea.enabled ? scrollFactor * 3 : dummy.flickDeceleration
    }
}
