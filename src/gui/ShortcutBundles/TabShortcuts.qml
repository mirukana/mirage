// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../Base"

HQtObject {
    id: root


    property Item container: parent
    property bool enabled: true


    HShortcut {
        enabled: root.enabled
        sequences: window.settings.keys.previousTab
        onActivated: container.setCurrentIndex(
            utils.numberWrapAt(container.currentIndex - 1, container.count),
        )
    }

    HShortcut {
        enabled: root.enabled
        sequences: window.settings.keys.nextTab
        onActivated: container.setCurrentIndex(
            utils.numberWrapAt(container.currentIndex + 1, container.count),
        )
    }
}
