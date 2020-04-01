// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../Base"

HQtObject {
    id: root


    property Item flickable: parent
    property bool active: true


    HShortcut {
        active: root.active
        sequences: window.settings.keys.scrollUp
        onActivated: utils.flickPages(flickable, -1 / 10)
    }

    HShortcut {
        active: root.active
        sequences: window.settings.keys.scrollDown
        onActivated: utils.flickPages(flickable, 1 / 10)
    }

    HShortcut {
        active: root.active
        sequences: window.settings.keys.scrollPageUp
        onActivated: utils.flickPages(flickable, -1)
    }

    HShortcut {
        active: root.active
        sequences: window.settings.keys.scrollPageDown
        onActivated: utils.flickPages(flickable, 1)
    }

    HShortcut {
        active: root.active
        sequences: window.settings.keys.scrollToTop
        onActivated: utils.flickToTop(flickable)
    }

    HShortcut {
        active: root.active
        sequences: window.settings.keys.scrollToBottom
        onActivated: utils.flickToBottom(flickable)
    }
}
