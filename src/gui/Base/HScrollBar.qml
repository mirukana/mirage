// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

ScrollBar {
    id: scrollBar
    minimumSize: (Math.min(height / 1.5, 48) * theme.uiScale) / height
    opacity: size < 1 && (active || hovered) ? 1 : 0
    padding: 0

    background: Rectangle {
        color: theme.controls.scrollBar.track
    }

    contentItem: Item {
        implicitWidth: theme.controls.scrollBar.width

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: theme.controls.scrollBar.sliderPadding
            anchors.rightMargin: anchors.leftMargin

            radius: theme.controls.scrollBar.sliderRadius
            color:
                scrollBar.pressed ? theme.controls.scrollBar.pressedSlider :
                sliderHover.hovered ? theme.controls.scrollBar.hoveredSlider :
                theme.controls.scrollBar.slider

            Behavior on color { HColorAnimation {} }

            HoverHandler { id: sliderHover }
        }
    }

    Behavior on opacity { HNumberAnimation {} }
}
