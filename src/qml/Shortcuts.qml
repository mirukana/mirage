import QtQuick 2.12
import "Base"
import "utils.js" as Utils

HShortcutHandler {
    property Item flickTarget: Item {}

    // App

    HShortcut {
        enabled: debugMode
        sequences: settings.keys.startDebugger
        onPressed: py.call("APP.pdb")
    }

    HShortcut {
        sequences: settings.keys.reloadConfig
        onPressed: py.loadSettings(() => { mainUI.pressAnimation.start() })
    }

    // Page scrolling

    HShortcut {
        sequences: settings.keys.scrollUp
        onPressed: Utils.smartVerticalFlick(flickTarget, -335)
        onHeld: pressed(event)
    }

    HShortcut {
        sequences: settings.keys.scrollDown
        onPressed: Utils.smartVerticalFlick(flickTarget, 335)
        onHeld: pressed(event)
    }

    // SidePane

    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.focusSidePane
        onPressed: mainUI.sidePane.setFocus()
    }

    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.clearRoomFilter
        onPressed: mainUI.sidePane.paneToolBar.roomFilter = ""
    }

    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.addNewAccount
        onPressed: mainUI.sidePane.paneToolBar.addAccountButton.clicked()
    }

    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.goToPreviousRoom
        onPressed: mainUI.sidePane.accountRoomList.previous()
        onHeld: pressed(event)
    }

    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.goToNextRoom
        onPressed: mainUI.sidePane.accountRoomList.next()
        onHeld: pressed(event)
    }

    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.toggleCollapseAccount
        onPressed: mainUI.sidePane.accountRoomList.toggleCollapseAccount()
    }
}
