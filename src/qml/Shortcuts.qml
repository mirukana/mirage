import QtQuick 2.12
import "Base"
import "utils.js" as Utils

HShortcutHandler {
    property Item flickTarget: Item {}


    HShortcut {
        enabled: debugMode
        sequences: settings.keys.startDebugger
        onPressed: py.call("APP.pdb")
    }

    HShortcut {
        sequences: settings.keys.reloadConfig
        onPressed: py.loadSettings(() => { mainUI.pressAnimation.start() })
    }

    HShortcut {
        sequences: settings.keys.scrollUp
        onPressed: Utils.smartVerticalFlick(flickTarget, -335)
    }

    HShortcut {
        sequences: settings.keys.scrollDown
        onPressed: Utils.smartVerticalFlick(flickTarget, 335)
    }

    HShortcut {
        sequences: settings.keys.focusSidePane
        onPressed: mainUI.sidePane.setFocus()
    }

    HShortcut {
        sequences: settings.keys.clearRoomFilter
        onPressed: mainUI.sidePane.paneToolBar.roomFilter = ""
    }

    HShortcut {
        sequences: settings.keys.goToPreviousRoom
        onPressed: mainUI.sidePane.accountRoomList.previous()
    }

    HShortcut {
        sequences: settings.keys.goToNextRoom
        onPressed: mainUI.sidePane.accountRoomList.next()
    }

    HShortcut {
        sequences: settings.keys.toggleCollapseAccount
        onPressed: mainUI.sidePane.accountRoomList.toggleCollapseAccount()
    }
}
