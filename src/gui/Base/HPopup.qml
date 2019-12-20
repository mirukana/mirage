// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

Popup {
    id: popup
    anchors.centerIn: Overlay.overlay
    modal: true
    focus: true
    padding: 0
    margins: theme.spacing

    enter: Transition {
        HNumberAnimation { property: "scale"; from: 0; to: 1; overshoot: 4 }
    }

    exit: Transition {
        HNumberAnimation { property: "scale"; to: 0 }
    }

    background: Rectangle {
        color: theme.controls.popup.background
    }

    onAboutToShow: previouslyFocused = window.activeFocusItem
    onClosed: if (focusOnClosed) focusOnClosed.forceActiveFocus()


    property var previouslyFocused: null
    property Item focusOnClosed: previouslyFocused

    readonly property int maximumPreferredWidth:
        window.width - leftMargin - rightMargin - leftInset - rightInset

    readonly property int maximumPreferredHeight:
        window.height - topMargin - bottomMargin - topInset - bottomInset
}
