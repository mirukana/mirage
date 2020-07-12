// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import "../../.."
import "../../../Base"

Rectangle {
    property int delegateHeight: 0

    readonly property var firstDelegate:
        transferList.contentItem.visibleChildren[0]

    readonly property alias transferCount: transferList.count


    implicitWidth: 800
    implicitHeight: firstDelegate ? firstDelegate.height : 0
    color: theme.chat.fileTransfer.background
    opacity: implicitHeight ? 1 : 0
    clip: true

    Behavior on implicitHeight { HNumberAnimation {} }

    HListView {
        id: transferList
        anchors.fill: parent

        model: ModelStore.get(chat.roomId, "uploads")
        delegate: Transfer { width: transferList.width }
    }
}
