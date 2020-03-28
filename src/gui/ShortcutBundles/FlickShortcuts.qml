// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../Base"

HQtObject {
    property Item flickable: parent


    HShortcut {
        sequences: window.settings.keys.scrollUp
        onActivated: utils.flickPages(flickable, -1 / 10)
    }

    HShortcut {
        sequences: window.settings.keys.scrollDown
        onActivated: utils.flickPages(flickable, 1 / 10)
    }

    HShortcut {
        sequences: window.settings.keys.scrollPageUp
        onActivated: utils.flickPages(flickable, -1)
    }

    HShortcut {
        sequences: window.settings.keys.scrollPageDown
        onActivated: utils.flickPages(flickable, 1)
    }

    HShortcut {
        sequences: window.settings.keys.scrollToTop
        onActivated: utils.flickToTop(flickable)
    }

    HShortcut {
        sequences: window.settings.keys.scrollToBottom
        onActivated: utils.flickToBottom(flickable)
    }
}
