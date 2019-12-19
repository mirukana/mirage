// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12

Column {
    spacing: theme.spacing / 2

    property alias label: fieldLabel
    property alias field: textField

    HLabel {
        id: fieldLabel
    }

    HTextField {
        id: textField
        radius: 2
        width: parent.width
    }
}
