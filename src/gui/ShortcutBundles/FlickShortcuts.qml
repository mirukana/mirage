// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../Base"

HQtObject {
    id: root

    property Item flickable: parent
    property bool active: true
    property bool disableIfAnyPopupOrMenu: true

    HShortcut {
        active: root.active
        disableIfAnyPopupOrMenu: root.disableIfAnyPopupOrMenu
        sequences: window.settings.Keys.Scrolling.up
        onActivated: utils.flickPages(flickable, -1 / 10)
    }

    HShortcut {
        active: root.active
        disableIfAnyPopupOrMenu: root.disableIfAnyPopupOrMenu
        sequences: window.settings.Keys.Scrolling.down
        onActivated: utils.flickPages(flickable, 1 / 10)
    }

    HShortcut {
        active: root.active
        disableIfAnyPopupOrMenu: root.disableIfAnyPopupOrMenu
        sequences: window.settings.Keys.Scrolling.page_up
        onActivated: utils.flickPages(flickable, -1)
    }

    HShortcut {
        active: root.active
        disableIfAnyPopupOrMenu: root.disableIfAnyPopupOrMenu
        sequences: window.settings.Keys.Scrolling.page_down
        onActivated: utils.flickPages(flickable, 1)
    }

    HShortcut {
        active: root.active
        disableIfAnyPopupOrMenu: root.disableIfAnyPopupOrMenu
        sequences: window.settings.Keys.Scrolling.top
        onActivated: utils.flickToTop(flickable)
    }

    HShortcut {
        active: root.active
        disableIfAnyPopupOrMenu: root.disableIfAnyPopupOrMenu
        sequences: window.settings.Keys.Scrolling.bottom
        onActivated: utils.flickToBottom(flickable)
    }
}
