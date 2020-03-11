// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

Page {
    leftPadding: currentSpacing < theme.spacing ? 0 : currentSpacing
    rightPadding: leftPadding
    background: null

    Component.onCompleted:
        if (becomeKeyboardFlickableTarget) shortcuts.flickTarget = focusTarget


    property int currentSpacing:
        Math.min(theme.spacing * width / 400, theme.spacing)

    property Item focusTarget: this
    property bool becomeKeyboardFlickableTarget: true


    Behavior on leftPadding { HNumberAnimation {} }
}
