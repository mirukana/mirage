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
                    icon.name: "reload-config-files"
                    text: qsTr("Reload config & theme")
                    onTriggered: mainUI.reloadSettings()
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
            toolTip.text: qsTr("Open project repository")

            onClicked:
                Qt.openUrlExternally("https://github.com/mirukana/mirage")

            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        HButton {
            backgroundColor: "transparent"

            icon.name:
                window.notificationLevel === Window.NotificationLevel.All ?
                "notifications-all" :

                window.notificationLevel === Window.NotificationLevel.None ?
                "notifications-none" :

                "notifications-mentions-keywords"

            icon.color:
                window.notificationLevel === Window.NotificationLevel.All ?
                theme.icons.colorize :

                window.notificationLevel === Window.NotificationLevel.None ?
                theme.colors.negativeBackground :

                theme.colors.middleBackground

            toolTip.text: qsTr("Control global notifications")
            onClicked: notificationsMenu.open()

            Layout.fillHeight: true

            HMenu {
                id: notificationsMenu
                y: parent.height

                HMenuItem {
                    icon.name: "notifications-all"
                    text: qsTr("Normal notifications")
                    onTriggered:
                        window.notificationLevel =
                            Window.NotificationLevel.All
                }

                HMenuItem {
                    icon.name: "notifications-mentions-keywords"
                    icon.color: theme.colors.middleBackground
                    text: qsTr("Mentions & keywords")
                    onTriggered:
                        window.notificationLevel =
                            Window.NotificationLevel.MentionsKeywords
                }

                HMenuItem {
                    icon.name: "notifications-none"
                    icon.color: theme.colors.negativeBackground
                    text: qsTr("Nothing")
                    onTriggered:
                        window.notificationLevel =
                            Window.NotificationLevel.None
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
