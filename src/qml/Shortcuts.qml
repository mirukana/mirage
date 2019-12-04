import QtQuick 2.12
import QtQuick.Controls 2.12
import "Base"
import "utils.js" as Utils

HShortcutHandler {
    // Flickable or ListView that should be affected by scroll shortcuts
    property Item flickTarget

    // TabBar that should be affected by tab navigation shortcuts
    property TabBar tabsTarget

    // DebugConsole that should be affected by console shortcuts
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

    HShortcut {
        sequences: settings.keys.zoomIn
        onPressed: theme.uiScale += 0.1
    }

    HShortcut {
        sequences: settings.keys.zoomOut
        onPressed: theme.uiScale = Math.max(0.1, theme.uiScale - 0.1)
    }

    HShortcut {
        sequences: settings.keys.zoomReset
        onPressed: theme.uiScale = 1
    }

    // Pages

    HShortcut {
        sequences: settings.keys.goToLastPage
        onPressed: mainUI.pageLoader.showPrevious()
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


    // Tab navigation

    HShortcut {
        enabled: tabsTarget
        sequences: settings.keys.previousTab
        onPressed: tabsTarget.setCurrentIndex(
            Utils.numberWrapAt(tabsTarget.currentIndex - 1, tabsTarget.count),
        )
    }

    HShortcut {
        enabled: tabsTarget
        sequences: settings.keys.nextTab
        onPressed: tabsTarget.setCurrentIndex(
            Utils.numberWrapAt(tabsTarget.currentIndex + 1, tabsTarget.count),
        )
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
        sequences: settings.keys.addNewChat
        onPressed: mainUI.sidePane.sidePaneList.addNewChat()
    }


    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.accountSettings
        onPressed: mainUI.sidePane.sidePaneList.accountSettings()
    }


    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.toggleCollapseAccount
        onPressed: mainUI.sidePane.sidePaneList.toggleCollapseAccount()
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

    HShortcut {
        enabled: window.uiState.page == "Chat/Chat.qml"
        sequences: settings.keys.sendFile
        onPressed: Utils.makeObject(
            "Dialogs/SendFilePicker.qml",
            mainUI,
            {
                userId:          window.uiState.pageProperties.userId,
                roomId:          window.uiState.pageProperties.roomId,
                destroyWhenDone: true,
            },
            picker => { picker.dialog.open() }
        )
    }

    HShortcut {
        enabled: window.uiState.page == "Chat/Chat.qml"
        sequences: settings.keys.sendFileFromPathInClipboard
        onPressed: Utils.sendFile(
            window.uiState.pageProperties.userId,
            window.uiState.pageProperties.roomId,
            Clipboard.text.trim(),
        )
    }
}
