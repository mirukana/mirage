// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

HMenuItem {
    onTriggered: {
        menu.focusOnClosed = null

        utils.makePopup(
            popup,
            popupParent,
            utils.objectUpdate(
                { focusOnClosed: menu.previouslyFocused }, properties,
            ),
            null,
            autoDestruct,
        )
    }


    property var popup  // url or HPopup Component
    property QtObject popupParent: window
    property bool autoDestruct: true
    property var properties: ({})
}
