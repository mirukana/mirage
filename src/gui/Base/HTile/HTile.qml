// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import ".."

HButton {
    id: tile

    property bool compact: window.settings.General.compact
    property real contentOpacity: 1
    property Component contextMenu: null
    property HMenu openedMenu: null

    signal leftClicked()
    signal middleClicked()
    signal rightClicked()
    signal longPressed()

    function openMenu(atCursor=true) {
        if (! contextMenu) return

        if (openedMenu) {
            openedMenu.close()
            return
        }

        openedMenu = contextMenu.createObject(tile)
        openedMenu.closed.connect(() => openedMenu.destroy())

        atCursor ?
        openedMenu.popup() :
        openedMenu.popup(tile.width / 2, tile.height / 2)
    }

    function doRightClick(menuAtCursor=true) {
        rightClicked()
        openMenu(menuAtCursor)
    }


    topPadding: padded ? spacing / (compact ? 4 : 2) : 0
    bottomPadding: topPadding

    Keys.onEnterPressed: leftClicked()
    Keys.onReturnPressed: leftClicked()
    Keys.onSpacePressed: leftClicked()
    Keys.onMenuPressed: doRightClick(false)


    Behavior on topPadding { HNumberAnimation {} }
    Behavior on bottomPadding { HNumberAnimation {} }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: leftClicked()
        onLongPressed: tile.longPressed()
    }

    TapHandler {
        acceptedButtons: Qt.MiddleButton
        onTapped: middleClicked()
        onLongPressed: tile.middleClicked()
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
