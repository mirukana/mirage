// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

Page {
    leftPadding: currentSpacing < theme.spacing ? 0 : currentSpacing
    rightPadding: leftPadding
    background: null


    property int currentSpacing:
        Math.min(theme.spacing * width / 400, theme.spacing)


    Behavior on leftPadding { HNumberAnimation {} }
}
