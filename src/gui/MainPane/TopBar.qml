// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import ".."
import "../Base"

Rectangle {
    clip: true
    implicitHeight: theme.baseElementsHeight
    color: theme.mainPane.topBar.background

    HRowLayout {
        anchors.fill: parent

        HButton {
            backgroundColor: "transparent"
            icon.name: "settings"
            toolTip.text: qsTr("Settings")
            onClicked: settingsMenu.open()

            Layout.fillHeight: true

            HMenu {
                id: settingsMenu
                y: parent.height

                HMenuItem {
                    icon.name: "more-settings"
                    text: qsTr("Open config folder")
                    onTriggered:
                        py.callCoro("get_config_dir", [], Qt.openUrlExternally)
                }

                HMenuItem {
                    icon.name: "theme"
                    text: qsTr("Open theme folder")
                    onTriggered:
                        py.callCoro("get_theme_dir", [], Qt.openUrlExternally)
                }

                HMenuItem {
                    icon.name: "debug"
                    text: qsTr("Developer console")
                    onTriggered: mainUI.debugConsole.toggle()
                }
            }
        }

        HButton {
            backgroundColor: "transparent"

            text: qsTr("%1 %2")
                  .arg(Qt.application.displayName).arg(Qt.application.version)
            label.color: theme.mainPane.topBar.nameVersionLabel
            toolTip.text: qsTr("Double click to open project repository")

            onDoubleClicked:
                Qt.openUrlExternally("https://github.com/mirukana/mirage")

            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        HButton {
            backgroundColor: "transparent"

            icon.name:
                window.notificationLevel === Window.NotificationLevel.Enable ?
                "notifications-all" :

                window.notificationLevel === Window.NotificationLevel.Mute ?
                "notifications-none" :

                "notifications-mentions-keywords"

            icon.color:
                window.notificationLevel === Window.NotificationLevel.Enable ?
                theme.icons.colorize :

                window.notificationLevel === Window.NotificationLevel.Mute ?
                theme.colors.negativeBackground :

                theme.colors.middleBackground

            onClicked: notificationsMenu.open()

            Layout.fillHeight: true

            HMenu {
                id: notificationsMenu
                y: parent.height

                HMenuItem {
                    text: qsTr("Enable notifications")
                    checked:
                        window.notificationLevel ===
                            Window.NotificationLevel.Enable
                    onTriggered:
                        window.notificationLevel =
                            Window.NotificationLevel.Enable
                }

                HMenuItem {
                    text: qsTr("Highlights only (replies, keywords...)")
                    checked:
                        window.notificationLevel ===
                            Window.NotificationLevel.HighlightsOnly
                    onTriggered:
                        window.notificationLevel =
                            Window.NotificationLevel.HighlightsOnly
                }

                HMenuItem {
                    text: qsTr("Mute all notifications")
                    checked:
                        window.notificationLevel ===
                            Window.NotificationLevel.Mute
                    onTriggered:
                        window.notificationLevel =
                            Window.NotificationLevel.Mute
                }
            }
        }

        HButton {
            visible: Layout.preferredWidth > 0
            backgroundColor: "transparent"
            icon.name: "go-back-to-chat-from-main-pane"
            toolTip.text: qsTr("Go back to room")

            onClicked: mainPane.toggleFocus()

            Layout.preferredWidth: mainPane.collapse ? implicitWidth : 0
            Layout.fillHeight: true

            Behavior on Layout.preferredWidth { HNumberAnimation {} }
        }
    }
}
