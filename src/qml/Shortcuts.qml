import QtQuick 2.12
import QtQuick.Controls 2.12
import "Base"
import "utils.js" as Utils

Item {
    visible: false

    // Flickable or ListView that should be affected by scroll shortcuts
    property Item flickTarget

    // TabBar that should be affected by tab navigation shortcuts
    property TabBar tabsTarget

    // DebugConsole that should be affected by console shortcuts
    property DebugConsole debugConsole

    readonly property Item toFlick:
        debugConsole && debugConsole.activeFocus ?
        debugConsole.commandsView : flickTarget


    // App

    HShortcut {
        enabled: debugMode
        sequences: settings.keys.startPythonDebugger
        onActivated: py.call("APP.pdb")
    }

    HShortcut {
        enabled: debugMode
        sequences: settings.keys.toggleDebugConsole
        onActivated:  {
            if (debugConsole) {
                debugConsole.visible = ! debugConsole.visible
            } else {
                Utils.debug(mainUI || window)
            }
        }
    }

    HShortcut {
        sequences: settings.keys.reloadConfig
        onActivated: py.loadSettings(() => { mainUI.pressAnimation.start() })
    }

    HShortcut {
        sequences: settings.keys.zoomIn
        onActivated: theme.uiScale += 0.1
    }

    HShortcut {
        sequences: settings.keys.zoomOut
        onActivated: theme.uiScale = Math.max(0.1, theme.uiScale - 0.1)
    }

    HShortcut {
        sequences: settings.keys.zoomReset
        onActivated: theme.uiScale = 1
    }

    // Pages

    HShortcut {
        sequences: settings.keys.goToLastPage
        onActivated: mainUI.pageLoader.showPrevious()
    }

    // Page scrolling

    HShortcut {
        enabled: toFlick
        sequences: settings.keys.scrollUp
        onActivated: Utils.flickPages(toFlick, -1 / 10)
    }

    HShortcut {
        enabled: toFlick
        sequences: settings.keys.scrollDown
        onActivated: Utils.flickPages(toFlick, 1 / 10)
    }

    HShortcut {
        enabled: toFlick
        sequences: settings.keys.scrollPageUp
        onActivated: Utils.flickPages(toFlick, -1)
    }

    HShortcut {
        enabled: toFlick
        sequences: settings.keys.scrollPageDown
        onActivated: Utils.flickPages(toFlick, 1)
    }

    HShortcut {
        enabled: toFlick
        sequences: settings.keys.scrollToTop
        onActivated: Utils.flickToTop(toFlick)
    }

    HShortcut {
        enabled: toFlick
        sequences: settings.keys.scrollToBottom
        onActivated: Utils.flickToBottom(toFlick)
    }


    // Tab navigation

    HShortcut {
        enabled: tabsTarget
        sequences: settings.keys.previousTab
        onActivated: tabsTarget.setCurrentIndex(
            Utils.numberWrapAt(tabsTarget.currentIndex - 1, tabsTarget.count),
        )
    }

    HShortcut {
        enabled: tabsTarget
        sequences: settings.keys.nextTab
        onActivated: tabsTarget.setCurrentIndex(
            Utils.numberWrapAt(tabsTarget.currentIndex + 1, tabsTarget.count),
        )
    }


    // SidePane

    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.focusSidePane
        onActivated: mainUI.sidePane.toggleFocus()
        context: Qt.ApplicationShortcut
    }

    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.clearRoomFilter
        onActivated: mainUI.sidePane.toolBar.roomFilter = ""
    }

    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.addNewAccount
        onActivated: mainUI.sidePane.toolBar.addAccountButton.clicked()
    }

    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.addNewChat
        onActivated: mainUI.sidePane.sidePaneList.addNewChat()
    }


    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.accountSettings
        onActivated: mainUI.sidePane.sidePaneList.accountSettings()
    }


    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.toggleCollapseAccount
        onActivated: mainUI.sidePane.sidePaneList.toggleCollapseAccount()
    }


    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.goToPreviousRoom
        onActivated: mainUI.sidePane.sidePaneList.previous()
    }

    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.goToNextRoom
        onActivated: mainUI.sidePane.sidePaneList.next()
    }


    // Chat

    HShortcut {
        enabled: window.uiState.page === "Chat/Chat.qml"
        sequences: settings.keys.clearRoomMessages
        onActivated: Utils.makePopup(
            "Popups/ClearMessagesPopup.qml",
            mainUI,
            {
                userId: window.uiState.pageProperties.userId,
                roomId: window.uiState.pageProperties.roomId,
            }
        )
    }

    HShortcut {
        enabled: window.uiState.page === "Chat/Chat.qml"
        sequences: settings.keys.sendFile
        onActivated: Utils.makeObject(
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
        enabled: window.uiState.page === "Chat/Chat.qml"
        sequences: settings.keys.sendFileFromPathInClipboard
        onActivated: Utils.sendFile(
            window.uiState.pageProperties.userId,
            window.uiState.pageProperties.roomId,
            Clipboard.text.trim(),
        )
    }
}
