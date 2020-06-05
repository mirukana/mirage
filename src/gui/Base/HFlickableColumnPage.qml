// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../ShortcutBundles"

HPage {
    id: page


    default property alias columnData: column.data
    property alias column: column
    property alias flickable: flickable
    property alias flickShortcuts: flickShortcuts


    padding: 0


    HFlickable {
        id: flickable
        anchors.fill: parent
        clip: true
        contentWidth: parent.width
        contentHeight: column.childrenRect.height + column.padding * 2

        FlickShortcuts {
            id: flickShortcuts
            active: ! mainUI.debugConsole.visible
            flickable: flickable
        }

        HColumnLayout {
            id: column
            x: padding
            y: padding
            width: flickable.width - padding * 2
            height: flickable.height - padding * 2

            property int padding:
                page.currentSpacing < theme.spacing ? 0 : page.currentSpacing
        }
    }

    HKineticScrollingDisabler {
        flickable: flickable
        width: enabled ? flickable.width : 0
        height: enabled ? flickable.height : 0
    }
}
