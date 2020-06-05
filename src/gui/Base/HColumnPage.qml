// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12

HPage {
    id: page


    default property alias columnData: column.data


    HColumnLayout {
        id: column
        anchors.fill: parent
    }
}
