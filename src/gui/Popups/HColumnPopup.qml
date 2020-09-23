// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../Base"

HPopup {
    id: popup

    default property alias pageData: page.columnData

    property int contentWidthLimit: theme.controls.popup.defaultWidth

    readonly property alias page: page

    signal keyboardAccept()


    HColumnPage {
        id: page
        implicitWidth: Math.min(
            popup.maximumPreferredWidth, popup.contentWidthLimit,
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
