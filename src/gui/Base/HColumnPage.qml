// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12

HPage {
    id: page

    default property alias columnData: column.data

    property alias column: column

    implicitWidth: theme.controls.box.defaultWidth
    contentHeight: column.childrenRect.height

    HColumnLayout {
        id: column
        anchors.fill: parent
        spacing: theme.spacing * 1.5
    }
}
