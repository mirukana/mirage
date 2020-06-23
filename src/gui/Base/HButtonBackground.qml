// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

Rectangle {
    property var button
    property QtObject buttonTheme
    property bool useFocusLine: true


    color: buttonTheme.background
    opacity:
        loading ? theme.loadingElementsOpacity :
        enabled ? 1 :
        theme.disabledElementsOpacity


    Behavior on opacity { HNumberAnimation {} }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color:
            button.checked ? buttonTheme.checkedOverlay :

            button.enabled && button.pressed ? buttonTheme.pressedOverlay :

            button.enabled && ! useFocusLine && button.activeFocus ?
            buttonTheme.hoveredOverlay :

            button.enabled && button.hovered ? buttonTheme.hoveredOverlay :

            "transparent"

        Behavior on color { HColorAnimation { factor: 0.5 } }
    }

    HBottomFocusLine {
        show: useFocusLine && button.activeFocus
        borderHeight: useFocusLine ? buttonTheme.focusedBorderWidth : 0
        color: useFocusLine ? button.focusLineColor : "transparent"
    }
}
