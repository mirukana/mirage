// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import ".."
import "../Base"

HSwipeView {
    id: swipeView
    orientation: Qt.Vertical

    Repeater {
        model: ModelStore.get("accounts")

        HLoader {
            id: loader
            active:
                HSwipeView.isCurrentItem ||
                HSwipeView.isNextItem ||
                HSwipeView.isPreviousItem

            readonly property bool isCurrent: HSwipeView.isCurrentItem

            sourceComponent: HColumnLayout {
                id: column

                readonly property QtObject accountModel: model
                readonly property alias roomList: roomList

                Account {
                    id: account
                    isCurrent: loader.isCurrent

                    Layout.fillWidth: true
                }

                RoomList {
                    id: roomList
                    clip: true
                    accountModel: column.accountModel
                    roomPane: swipeView
                    isCurrent: loader.isCurrent

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                HTextField {
                    id: filterField
                    saveName: "roomFilterField"

                    placeholderText: qsTr("Filter rooms")
                    backgroundColor:
                        theme.mainPane.bottomBar.filterFieldBackground
                    bordered: false
                    opacity: width >= 16 * theme.uiScale ? 1 : 0

                    Layout.fillWidth: true
                    Layout.preferredHeight: theme.baseElementsHeight

                    Keys.onUpPressed: roomList.decrementCurrentIndex()
                    Keys.onDownPressed: roomList.incrementCurrentIndex()

                    Keys.onEnterPressed: Keys.onReturnPressed(event)
                    Keys.onReturnPressed: {
                        if (window.settings.clearRoomFilterOnEnter) text = ""
                        roomList.showRoom()
                    }

                    Keys.onEscapePressed: {
                        if (window.settings.clearRoomFilterOnEscape) text = ""
                        mainUI.pageLoader.forceActiveFocus()
                    }

                    Behavior on opacity { HNumberAnimation {} }

                    HShortcut {
                        enabled: loader.isCurrent
                        sequences: window.settings.keys.clearRoomFilter
                        onActivated: filterField.text = ""
                    }

                    HShortcut {
                        enabled: loader.isCurrent
                        sequences: window.settings.keys.toggleFocusMainPane
                        onActivated: {
                            if (filterField.activeFocus) {
                                pageLoader.takeFocus()
                                return
                            }

                            mainPane.open()
                            filterField.forceActiveFocus()
                        }
                    }
                }
            }
        }
    }
}
