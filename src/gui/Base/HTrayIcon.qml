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
                window.drawAttention()
                py.importModule("os", () => {
                    py.call("os.remove", [get(0, "filePath")])
                })
            }
        }
    }


    visible: true
    tooltip: qsTr("Mirage")
    icon.source: `../../icons/${iconPack}/tray-icon.png`

    onActivated:
        if (reason !== SystemTrayIcon.Context)
            window.drawAttention()


    menu: Menu {
        MenuItem {
            text: window.visible ? "Hide Mirage" : "Show Mirage"
            onTriggered:
                window.visible ?
                window.hide() :
                window.drawAttention()
        }

        MenuItem {
            text: qsTr("Quit Mirage")
            onTriggered: Qt.quit()
        }
    }
}
