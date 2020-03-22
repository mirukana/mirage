// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import Clipboard 0.1
import "Base"

Item {
    visible: false

    // Flickable or ListView that should be affected by scroll shortcuts
    property Item flickTarget

    // A QQC Container that should be affected by tab navigation shortcuts
    property Container tabsTarget

    // DebugConsoleLoader that should be affected by console shortcuts
    property DebugConsoleLoader debugConsoleLoader

    // DebugConsoleLoader to activate if no other loader is active and the
    // shortcut to bring up a console is pressed
    property DebugConsoleLoader defaultDebugConsoleLoader

    readonly property DebugConsole debugConsole:
        debugConsoleLoader ? debugConsoleLoader.item : null

    readonly property DebugConsole defaultDebugConsole:
        defaultDebugConsoleLoader ? defaultDebugConsoleLoader.item : null

    readonly property Item toFlick:
        debugConsole && debugConsole.activeFocus ?
        debugConsole.commandsView :
        flickTarget


    function toggleConsole() {
        if (debugConsole) {
            debugConsole.visible = ! debugConsole.visible

        } else if (! defaultDebugConsoleLoader.active) {
            defaultDebugConsoleLoader.active = true

        } else {
            defaultDebugConsole.visible = ! defaultDebugConsole.visible
        }
    }


    // App

    HShortcut {
        sequences: settings.keys.startPythonDebugger
        onActivated: py.call("BRIDGE.pdb")
    }

    HShortcut {
        sequences: settings.keys.toggleDebugConsole
        onActivated: toggleConsole()
    }

    HShortcut {
        sequences: settings.keys.reloadConfig
        onActivated: mainUI.reloadSettings()
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

    HShortcut {
        sequences: settings.keys.toggleCompactMode
        onActivated: {
            settings.compactMode = ! settings.compactMode
            settingsChanged()
        }
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
        onActivated: utils.flickPages(toFlick, -1 / 10)
    }

    HShortcut {
        enabled: toFlick
        sequences: settings.keys.scrollDown
        onActivated: utils.flickPages(toFlick, 1 / 10)
    }

    HShortcut {
        enabled: toFlick
        sequences: settings.keys.scrollPageUp
        onActivated: utils.flickPages(toFlick, -1)
    }

    HShortcut {
        enabled: toFlick
        sequences: settings.keys.scrollPageDown
        onActivated: utils.flickPages(toFlick, 1)
    }

    HShortcut {
        enabled: toFlick
        sequences: settings.keys.scrollToTop
        onActivated: utils.flickToTop(toFlick)
    }

    HShortcut {
        enabled: toFlick
        sequences: settings.keys.scrollToBottom
        onActivated: utils.flickToBottom(toFlick)
    }


    // Tab navigation

    HShortcut {
        enabled: tabsTarget
        sequences: settings.keys.previousTab
        onActivated: tabsTarget.setCurrentIndex(
            utils.numberWrapAt(tabsTarget.currentIndex - 1, tabsTarget.count),
        )
    }

    HShortcut {
        enabled: tabsTarget
        sequences: settings.keys.nextTab
        onActivated: tabsTarget.setCurrentIndex(
            utils.numberWrapAt(tabsTarget.currentIndex + 1, tabsTarget.count),
        )
    }


    // MainPane

    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.toggleFocusMainPane
        onActivated: mainUI.mainPane.toggleFocus()
        context: Qt.ApplicationShortcut
    }

    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.clearRoomFilter
        onActivated: mainUI.mainPane.bottomBar.roomFilter = ""
    }

    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.addNewAccount
        onActivated: mainUI.mainPane.bottomBar.addAccountButton.clicked()
    }

    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.addNewChat
        onActivated: mainUI.mainPane.mainPaneList.addNewChat()
    }


    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.accountSettings
        onActivated: mainUI.mainPane.mainPaneList.accountSettings()
    }


    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.toggleCollapseAccount
        onActivated: mainUI.mainPane.mainPaneList.toggleCollapseAccount()
    }


    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.goToPreviousRoom
        onActivated: {
            mainUI.mainPane.mainPaneList.previous()
            mainUI.mainPane.mainPaneList.requestActivate()
        }
    }

    HShortcut {
        enabled: mainUI.accountsPresent
        sequences: settings.keys.goToNextRoom
        onActivated: {
            mainUI.mainPane.mainPaneList.next()
            mainUI.mainPane.mainPaneList.requestActivate()
        }
    }

    Repeater {
        model: Object.keys(settings.keys.focusRoomAtIndex)

        Item {
            HShortcut {
                enabled: mainUI.accountsPresent
                sequence: settings.keys.focusRoomAtIndex[modelData]
                onActivated: mainUI.mainPane.mainPaneList.goToRoom(
                    parseInt(modelData - 1, 10),
                )
            }
        }
    }


    // Chat

    HShortcut {
        enabled: window.uiState.page === "Pages/Chat/Chat.qml"
        sequences: settings.keys.clearRoomMessages
        onActivated: utils.makePopup(
            "Popups/ClearMessagesPopup.qml",
            mainUI,
            {
                userId: window.uiState.pageProperties.userId,
                roomId: window.uiState.pageProperties.roomId,
            }
        )
    }

    HShortcut {
        enabled: window.uiState.page === "Pages/Chat/Chat.qml"
        sequences: settings.keys.sendFile
        onActivated: utils.makeObject(
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
        enabled: window.uiState.page === "Pages/Chat/Chat.qml"
        sequences: settings.keys.sendFileFromPathInClipboard
        onActivated: utils.sendFile(
            window.uiState.pageProperties.userId,
            window.uiState.pageProperties.roomId,
            Clipboard.text.trim(),
        )
    }


    // RoomPane

    HShortcut {
        enabled: window.uiState.page === "Pages/Chat/Chat.qml"
        sequences: settings.keys.toggleFocusRoomPane
        onActivated: mainUI.pageLoader.item.roomPane.toggleFocus()
        context: Qt.ApplicationShortcut
    }
}
