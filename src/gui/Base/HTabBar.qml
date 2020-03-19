// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

TabBar {
    spacing: 0
    position: TabBar.Header

    background: Item {
        Rectangle {
            width: parent.width
            anchors.bottom: parent.bottom
            height: 2
            color: theme.controls.tab.bottomLine
        }
    }
}
