// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import CppUtils 0.1

Menu {
    id: menu

    property var previouslyFocused: null

    // MenuItems that open popups (or other elements taking focus when opened)
    // should set this to null. It will be reset to previouslyFocus when
    // the Menu is closed and opened again.
    property Item focusOnClosed: previouslyFocused

    readonly property string uuid: CppUtils.uuid()


    modal: true
    dim: false
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

        // Workaround for this: when opening menu at mouse position,
        // cursor will be in menu's border which doesn't handle clicks
        TapHandler {
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: eventPoint => {
                const pos    = eventPoint.position
                const border = parent.border.width

                if (pos.x <= border || pos.x >= parent.width - border)
                    menu.close()

                if (pos.y <= border || pos.y >= parent.height - border)
                    menu.close()
            }
        }
    }

    onAboutToShow: {
        previouslyFocused = window.activeFocusItem
        focusOnClosed     = Qt.binding(() => previouslyFocused)
    }

    onOpened: {
        window.visibleMenus[uuid] = this
        window.visibleMenusChanged()
    }

    onClosed: {
        if (focusOnClosed) focusOnClosed.forceActiveFocus()
        delete window.visibleMenus[uuid]
        window.visibleMenusChanged()
    }

    Component.onDestruction: closed()
}
