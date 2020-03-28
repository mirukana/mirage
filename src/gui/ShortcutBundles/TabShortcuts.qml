// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../Base"

HQtObject {
    property Item container: parent


    HShortcut {
        sequences: window.settings.keys.previousTab
        onActivated: container.setCurrentIndex(
            utils.numberWrapAt(container.currentIndex - 1, container.count),
        )
    }

    HShortcut {
        sequences: window.settings.keys.nextTab
        onActivated: container.setCurrentIndex(
            utils.numberWrapAt(container.currentIndex + 1, container.count),
        )
    }
}
