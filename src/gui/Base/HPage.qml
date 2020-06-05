// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

Page {
    padding: currentSpacing < theme.spacing ? 0 : currentSpacing
    background: null


    property bool useVariableSpacing: true

    property int currentSpacing:
        useVariableSpacing ?
        Math.min(theme.spacing * width / 400, theme.spacing) :
        theme.spacing


    Behavior on padding { HNumberAnimation {} }
}
