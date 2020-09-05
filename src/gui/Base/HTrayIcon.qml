// SPDX-License-Identifier: LGPL-3.0-or-later

import Qt.labs.platform 1.1
import Qt.labs.folderlistmodel 2.12

SystemTrayIcon {
    property string iconPack: theme ? theme.icons.preferredPack : "thin"
    property alias settingsFolder: showUpWatcher.folder

    property var window

    property FolderListModel showUpWatcher: FolderListModel {
        id: showUpWatcher
        showDirs: false
        showHidden: true
        nameFilters: [".show"]

        onCountChanged: {
            if (count) {
                window.restoreFromTray()
                py.importModule("os", () => {
                    py.call("os.remove", [get(0, "filePath")])
                })
            }
        }
    }


    visible: true
    tooltip: Qt.application.displayName
    icon.source: `../../icons/${iconPack}/tray-icon.png`

    onActivated: {
        if (reason === SystemTrayIcon.MiddleClick)
            Qt.quit()
        else if (reason !== SystemTrayIcon.Context)
            window.visible ? window.hide() : window.restoreFromTray()
    }

    menu: Menu {
        MenuItem {
            text:
                window.visible ?
                "Minimize to tray" :
                qsTr("Open ") + Qt.application.displayName
            onTriggered:
                window.visible ?
                window.hide() :
                window.restoreFromTray()
        }

        MenuItem {
            text: qsTr("Quit ") + Qt.application.displayName
            onTriggered: Qt.quit()
        }
    }
}
