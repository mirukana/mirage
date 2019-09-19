import QtQuick 2.12
import "Base"
import "utils.js" as Utils

HShortcutHandler {
    property Item flickTarget
    property DebugConsole debugConsole

    // App

    HShortcut {
        enabled: debugMode
        sequences: settings.keys.startPythonDebugger
        onPressed: py.call("APP.pdb")
    }

    HShortcut {
        enabled: debugMode && debugConsole
        sequences: settings.keys.toggleDebugConsole
        onPressed: debugConsole.visible = ! debugConsole.visible
    }

    HShortcut {
        sequences: settings.keys.reloadConfig
        onPressed: py.loadSettings(() => { mainUI.pressAnimation.start() })
    }

    // Page scrolling

    HShortcut {
        enabled: flickTarget
        sequences: settings.keys.scrollUp
        onPressed: Utils.smartVerticalFlick(flickTarget, -335)
        onHeld: pressed(event)
    }

    HShortcut {
        enabled: flickTarget
        sequences: settings.keys.scrollDown
        onPressed: Utils.smartVerticalFlick(flickTarget, 335)
        onHeld: pressed(event)
    }

    HShortcut {
        enabled: flickTarget
        sequences: settings.keys.scrollPageUp
        onPressed: Utils.smartVerticalFlick(
            flickTarget, -2.3 * flickTarget.height, 8,
        )
        onHeld: pressed(event)
        // Ensure only a slight slip after releasing the key
        onReleased: Utils.smartVerticalFlick(flickTarget, -335)
    }

    HShortcut {
        enabled: flickTarget
        sequences: settings.keys.scrollPageDown
        onPressed: Utils.smartVerticalFlick(
            flickTarget, 2.3 * flickTarget.height, 8,
        )
        onHeld: pressed(event)
        onReleased: Utils.smartVerticalFlick(flickTarget, 335)
    }

    HShortcut {
        enabled: flickTarget
        sequences: settings.keys.scrollToTop
        onPressed: Utils.flickToTop(flickTarget)
        onHeld: pressed(event)
    }

    HShortcut {
        enabled: flickTarget
        sequences: settings.keys.scrollToBottom
        onPressed: Utils.flickToBottom(flickTarget)
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
        onPressed: mainUI.sidePane.toolBar.roomFilter = ""
    }

    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.addNewAccount
        onPressed: mainUI.sidePane.toolBar.addAccountButton.clicked()
    }

    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.goToPreviousRoom
        onPressed: mainUI.sidePane.sidePaneList.previous()
        onHeld: pressed(event)
    }

    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.goToNextRoom
        onPressed: mainUI.sidePane.sidePaneList.next()
        onHeld: pressed(event)
    }

    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.toggleCollapseAccount
        onPressed: mainUI.sidePane.sidePaneList.toggleCollapseAccount()
    }


    // Chat

    HShortcut {
        enabled: window.uiState.page == "Chat/Chat.qml"
        sequences: settings.keys.clearRoomMessages
        onPressed: Utils.makePopup(
            "Popups/ClearMessagesPopup.qml",
            mainUI,
            {
                userId: window.uiState.pageProperties.userId,
                roomId: window.uiState.pageProperties.roomId,
            }
        )
    }
}
