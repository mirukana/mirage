// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

Menu {
    id: menu
    padding: theme.controls.menu.borderWidth

    implicitWidth: {
        let result = 0

        for (let i = 0; i < count; ++i) {
            const item = itemAt(i)
            if (! item.visible) continue

            result = Math.max(item.implicitWidth, result)
        }
        return Math.min(result + menu.padding * 2, window.width)
    }

    background: Rectangle {
        color: theme.controls.menu.background
        border.color: theme.controls.menu.border
        border.width: theme.controls.menu.borderWidth
    }

    onAboutToShow: {
        previouslyFocused = window.activeFocusItem
        focusOnClosed     = Qt.binding(() => previouslyFocused)
    }
    onClosed: if (focusOnClosed) focusOnClosed.forceActiveFocus()


    property var previouslyFocused: null

    // MenuItems that open popups (or other elements taking focus when opened)
    // should set this to null. It will be reset to previouslyFocus when
    // the Menu is closed and opened again.
    property Item focusOnClosed: previouslyFocused
}
