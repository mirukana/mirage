// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import ".."
import "../Base"

HSwipeView {
    id: swipeView
    orientation: Qt.Vertical

    Repeater {
        model: ModelStore.get("accounts")

        AccountView {}
    }
}
