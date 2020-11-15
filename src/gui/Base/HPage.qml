// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

Page {
    property bool useVariableSpacing: true

    property int currentSpacing:
        useVariableSpacing ?
        Math.min(
            theme.spacing * width / 400,
            theme.spacing * height / 400,
            theme.spacing,
        ) :
        theme.spacing

    signal keyboardAccept()
    signal keyboardCancel()

    padding: currentSpacing < theme.spacing ? 0 : currentSpacing
    background: null

    Keys.onReturnPressed: keyboardAccept()
    Keys.onEnterPressed: keyboardAccept()
    Keys.onEscapePressed: keyboardCancel()

    Behavior on padding { HNumberAnimation {} }
}
