// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import ".."

HButton {
    id: tile


    signal leftClicked()
    signal rightClicked()
    signal longPressed()


    property bool compact: window.settings.compactMode
    property real contentOpacity: 1

    property alias contextMenu: contextMenuLoader.sourceComponent


    Behavior on topPadding { HNumberAnimation {} }
    Behavior on bottomPadding { HNumberAnimation {} }

    Binding on topPadding {
        value: spacing / 4
        when: compact
    }

    Binding on bottomPadding {
        value: spacing / 4
        when: compact
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: leftClicked()
        onLongPressed: tile.longPressed()
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        acceptedPointerTypes: PointerDevice.GenericPointer | PointerDevice.Pen
        onTapped: {
            rightClicked()
            if (contextMenu) contextMenuLoader.active = true
        }
    }

    TapHandler {
        acceptedPointerTypes: PointerDevice.Finger | PointerDevice.Pen
        onLongPressed: {
            rightClicked()
            if (contextMenu) contextMenuLoader.active = true
        }
    }

    Connections {
        enabled: contextMenuLoader.status === Loader.Ready
        target: contextMenuLoader.item
        onClosed: contextMenuLoader.active = false
    }

    HLoader {
        id: contextMenuLoader
        active: false
        onLoaded: item.popup()
    }
}
