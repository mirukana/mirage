// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../Base"

HQtObject {
    id: root

    property Item container: parent
    property bool active: container.count > 1

    HShortcut {
        active: root.active
        sequences: window.settings.Keys.previous_tab
        onActivated: container.setCurrentIndex(
            utils.numberWrapAt(container.currentIndex - 1, container.count),
        )
    }

    HShortcut {
        active: root.active
        sequences: window.settings.Keys.next_tab
        onActivated: container.setCurrentIndex(
            utils.numberWrapAt(container.currentIndex + 1, container.count),
        )
    }
}
