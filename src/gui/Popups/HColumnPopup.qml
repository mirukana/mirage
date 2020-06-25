// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../Base"

HPopup {
    id: popup


    default property alias pageData: page.columnData
    readonly property alias page: page

    signal keyboardAccept()


    HColumnPage {
        id: page
        implicitWidth: Math.min(
            popup.maximumPreferredWidth,
            theme.controls.popup.defaultWidth,
        )
        implicitHeight: Math.min(
            popup.maximumPreferredHeight,
            implicitHeaderHeight + implicitFooterHeight +
            topPadding + bottomPadding + implicitContentHeight,
        )
        useVariableSpacing: false

        Keys.onReturnPressed: popup.keyboardAccept()
        Keys.onEnterPressed: popup.keyboardAccept()
    }
}
