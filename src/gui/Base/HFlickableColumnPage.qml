// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../ShortcutBundles"

HPage {
    property alias flickable: flickable
    default property alias columnData: column.data


    HFlickable {
        id: flickable
        anchors.fill: parent
        clip: true
        contentWidth: parent.width
        contentHeight: column.childrenRect.height

        FlickShortcuts {
            active: ! mainUI.debugConsole.visible
            flickable: flickable
        }

        HColumnLayout {
            id: column
            width: flickable.width
            height: flickable.height
        }
    }

    HKineticScrollingDisabler {
        flickable: flickable
        width: enabled ? flickable.width : 0
        height: enabled ? flickable.height : 0
    }
}
