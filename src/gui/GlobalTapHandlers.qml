// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12

Item {
    id: root

    property PageLoader pageLoader

    // Raise our z-index as much as possible, so that mouse events go before
    // anything else through this item which the TapHandlers are watching
    z: 99999

    implicitWidth: parent ? parent.width : 0
    implicitHeight: parent ? parent.height : 0

    TapHandler {
        acceptedPointerTypes: PointerDevice.GenericPointer
        acceptedButtons: Qt.BackButton
        onTapped: root.pageLoader.moveThroughHistory(1)
    }

    TapHandler {
        acceptedPointerTypes: PointerDevice.GenericPointer
        acceptedButtons: Qt.ForwardButton
        onTapped: root.pageLoader.moveThroughHistory(-1)
    }
}
