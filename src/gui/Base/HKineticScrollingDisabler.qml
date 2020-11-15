// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12

MouseArea {
    id: mouseArea

    property Flickable flickable: parent

    function getNewPosition(flickable, wheel) {
        // wheel.pixelDelta will be available on high resolution trackpads.
        // Otherwise use wheel.angleDelta, which is available from mouses and
        // low resolution trackpads.
        // When higher pixelDelta, more scroll will be applied

        const speedMultiply =
            Qt.styleHints.wheelScrollLines *
            window.settings.Scrolling.non_kinetic_speed

        const pixelDelta = {
            x: wheel.pixelDelta.x || wheel.angleDelta.x / 8 * speedMultiply,
            y: wheel.pixelDelta.y || wheel.angleDelta.y / 8 * speedMultiply,
        }

        // Return current position if there was not any movement
        if (
            flickable.contentHeight < flickable.height ||
            (! pixelDelta.x && ! pixelDelta.y)
        )
            return {x: flickable.contentX, y: flickable.contentY}

        // Rotate the direction if shift is pressed
        if (wheel.modifiers === Qt.ShiftModifier)
            [pixelDelta.x, pixelDelta.y] = [pixelDelta.y, pixelDelta.x]

        const maxScroll = {
            x: flickable.contentWidth +
               flickable.originX      - // Why subtract?
               flickable.rightMargin  -
               flickable.width,
            y: flickable.contentHeight +
               flickable.originY       +
               flickable.bottomMargin  -
               flickable.height,
        }

        const minScroll = {
            x: flickable.originX - flickable.leftMargin,
            y: flickable.originY - flickable.topMargin,
        }

        // Avoid overscrolling
        return {
            x: Math.max(
                minScroll.x,
                Math.min(maxScroll.x, flickable.contentX - pixelDelta.x)
            ),
            y: Math.max(
                minScroll.y,
                Math.min(maxScroll.y, flickable.contentY - pixelDelta.y)
            ),
        }
    }

    enabled: ! window.settings.Scrolling.kinetic
    propagateComposedEvents: true
    acceptedButtons: Qt.NoButton

    onWheel: {
        // Make components below the stack notice the wheel event
        wheel.accepted = false

        if (wheel.modifiers === Qt.ControlModifier)
            return

        const pos = getNewPosition(flickable, wheel)
        flickable.flick(0, 0)
        flickable.contentX = pos.x
        flickable.contentY = pos.y
    }

    Binding {
        target: flickable
        property: "maximumFlickVelocity"
        value:
            mouseArea.enabled ? 0 : window.settings.Scrolling.kinetic_max_speed
    }

    Binding {
        target: flickable
        property: "flickDeceleration"
        value:
            mouseArea.enabled ?
            0 :
            window.settings.Scrolling.kinetic_deceleration
    }
}
