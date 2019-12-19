// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

Menu {
    id: menu
    padding: theme.controls.menu.borderWidth

    implicitWidth: {
        let result = 0

        for (let i = 0; i < count; ++i) {
            let item = itemAt(i)
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

    onAboutToShow: previouslyFocused = window.activeFocusItem
    onClosed: if (previouslyFocused) previouslyFocused.forceActiveFocus()


    property var previouslyFocused: null
}
