// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import CppUtils 0.1

Popup {
    id: popup
    modal: true
    focus: true
    padding: 0
    margins: theme.spacing

    // FIXME: Qt 5.15: `anchors.centerIn: Overlay.overlay` + transition broken
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2

    enter: Transition {
        HNumberAnimation { property: "scale"; from: 0; to: 1; overshoot: 4 }
    }

    exit: Transition {
        HNumberAnimation { property: "scale"; to: 0 }
    }

    background: Rectangle {
        color: theme.controls.popup.background
    }

    Overlay.modal: Rectangle {
        color: "transparent"

        HColorAnimation on color { to: theme.controls.popup.windowOverlay }
    }

    onAboutToShow: previouslyFocused = window.activeFocusItem
    onOpened: {
        window.visiblePopups[uuid] = this
        window.visibleMenusChanged()
    }
    onClosed: {
        if (focusOnClosed) focusOnClosed.forceActiveFocus()
        delete window.visiblePopups[uuid]
        window.visibleMenusChanged()
    }


    property var previouslyFocused: null
    property Item focusOnClosed: previouslyFocused

    readonly property int maximumPreferredWidth:
        window.width - leftMargin - rightMargin - leftInset - rightInset

    readonly property int maximumPreferredHeight:
        window.height - topMargin - bottomMargin - topInset - bottomInset

    readonly property string uuid: CppUtils.uuid()
}
