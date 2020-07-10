// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import ".."

HButton {
    id: tile
    topPadding: padded ? spacing / (compact ? 4 : 2) : 0
    bottomPadding: topPadding

    Keys.onEnterPressed: leftClicked()
    Keys.onReturnPressed: leftClicked()
    Keys.onSpacePressed: leftClicked()
    Keys.onMenuPressed: doRightClick(false)


    signal leftClicked()
    signal rightClicked()
    signal longPressed()


    property bool compact: window.settings.compactMode
    property real contentOpacity: 1

    property Component contextMenu: null


    function openMenu(atCursor=true) {
        if (! contextMenu) return
        const menu = contextMenu.createObject(tile)
        menu.closed.connect(() => menu.destroy())
        atCursor ? menu.popup() : menu.popup(tile.width / 2, tile.height / 2)
    }

    function doRightClick(menuAtCursor=true) {
        rightClicked()
        openMenu(menuAtCursor)
    }


    Behavior on topPadding { HNumberAnimation {} }
    Behavior on bottomPadding { HNumberAnimation {} }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: leftClicked()
        onLongPressed: tile.longPressed()
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        acceptedPointerTypes: PointerDevice.GenericPointer | PointerDevice.Pen
        onTapped: doRightClick()
    }

    TapHandler {
        acceptedPointerTypes: PointerDevice.Finger | PointerDevice.Pen
        onLongPressed: doRightClick()
    }
}
