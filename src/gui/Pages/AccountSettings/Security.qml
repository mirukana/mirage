// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../.."
import "../../Base"
import "../../Base/Buttons"
import "../../PythonBridge"
import "../../ShortcutBundles"

HColumnPage {
    id: page

    property string userId

    property bool enableFlickShortcuts:
        SwipeView ? SwipeView.isCurrentItem : true

    property Future loadFuture: null

    readonly property QtObject account: ModelStore.get("accounts").find(userId)
    readonly property bool offline: ! account || account.presence === "offline"

    function takeFocus() {
        deviceList.headerItem.exportButton.forceActiveFocus()
    }

    function loadDevices() {
        loadFuture = py.callClientCoro(userId, "devices_info", [], devices => {
            deviceList.uncheckAll()
            deviceList.model.clear()

            for (const device of devices)
                deviceList.model.append(device)

            loadFuture                   = null
            deviceList.sectionItemCounts = getSectionItemCounts()
        })
    }

    function renameDevice(index, name) {
        const device = deviceList.model.get(index)

        device.display_name = name

        py.callClientCoro(userId, "rename_device", [device.id, name], ok => {
            if (! ok) deviceList.model.remove(index)  // 404 happened
        })
    }

    function deleteDevices(...indice) {
        if (indice.length === 1 && indice[0] === 0) {
            window.makePopup("Popups/SignOutPopup.qml", {userId: page.userId})
            return
        }

        const deviceIds     = []
        let deleteOwnDevice = false

        for (const i of indice.sort()) {
            i === 0 ?
            deleteOwnDevice = true :
            deviceIds.push(deviceList.model.get(i).id)
        }

        window.makePopup(
            "Popups/DeleteDevicesPopup.qml",
            {
                userId: page.userId,
                deviceIds,
                deletedCallback: () => {
                    deleteOwnDevice ?
                    window.makePopup(
                        "Popups/SignOutPopup.qml", { userId: page.userId },
                    ) :
                    page.loadDevices()
                },
            },
        )
    }

    function getSectionItemCounts() {
        const counts = {}

        for (let i = 0; i < deviceList.model.count; i++) {
            const section = deviceList.model.get(i).type
            section in counts ? counts[section] += 1 : counts[section] = 1
        }

        return counts
    }

    function focusListController(top=true) {
        deviceList.currentIndex = top ? 0 : deviceList.count - 1
        listController.forceActiveFocus()
    }


    contentHeight: Math.min(
        window.height,
        deviceList.contentHeight + deviceList.bottomMargin,
    )

    Keys.forwardTo: [deviceList]

    HListView {
        id: deviceList

        // Don't bind directly to getSectionItemCounts(), laggy with big list
        property var sectionItemCounts: ({})

        bottomMargin: theme.spacing
        clip: true
        keyNavigationEnabled: false

        model: ListModel {}

        header: HColumnLayout {
            readonly property alias exportButton: exportButton
            readonly property alias importButton: importButton
            readonly property alias signOutCheckedButton: signOutCheckedButton

            spacing: theme.spacing
            x: spacing
            width: deviceList.width - x * 2

            HLabel {
                text: qsTr("Decryption keys")
                font.pixelSize: theme.fontSize.big
                wrapMode: HLabel.Wrap
                topPadding: parent.spacing

                Layout.fillWidth: true
            }

            HLabel {
                text: qsTr(
                    "The decryption keys for messages received in encrypted " +
                    "rooms <b>until present time</b> can be exported " +
                    "to a passphrase-protected file.<br><br>" +

                    "You can then import this file on any Matrix account or " +
                    "application, in order to decrypt these messages again."
                )
                textFormat: Text.StyledText
                wrapMode: HLabel.Wrap

                Layout.fillWidth: true
            }

            AutoDirectionLayout {
                GroupButton {
                    id: exportButton
                    text: qsTr("Export")
                    icon.name: "export-keys"

                    onClicked: utils.makeObject(
                        "Dialogs/ExportKeys.qml",
                        page,
                        { userId: page.userId },
                        obj => {
                            loading = Qt.binding(() => obj.exporting)
                            obj.dialog.open()
                        }
                    )

                    Keys.onBacktabPressed: page.focusListController(false)
                }

                GroupButton {
                    id: importButton
                    text: qsTr("Import")
                    icon.name: "import-keys"

                    onClicked: utils.makeObject(
                        "Dialogs/ImportKeys.qml",
                        page,
                        { userId: page.userId },
                        obj => { obj.dialog.open() }
                    )

                    Keys.onTabPressed:
                        signOutCheckedButton.enabled ?
                        refreshButton.forceActiveFocus() :
                        page.focusListController()
                }
            }

            HLabel {
                text: qsTr("Sessions")
                font.pixelSize: theme.fontSize.big
                wrapMode: HLabel.Wrap
                topPadding: parent.spacing / 2

                Layout.fillWidth: true
            }

            HLabel {
                text: qsTr(
                    "New sessions are created the first time you sign in " +
                    "from a different device or application."
                )
                wrapMode: HLabel.Wrap

                Layout.fillWidth: true
            }

            AutoDirectionLayout {
                enabled: ! page.offline

                GroupButton {
                    id: refreshButton
                    text: qsTr("Refresh")
                    loading: page.loadFuture !== null
                    icon.name: "device-refresh-list"
                    onClicked: page.loadDevices()
                }

                NegativeButton {
                    id: signOutCheckedButton
                    enabled: deviceList.model.count > 0
                    text:
                        deviceList.selectedCount === 0 ?
                        qsTr("Sign out others") :
                        qsTr("Sign out checked")

                    icon.name: "device-delete-checked"
                    onClicked:
                        deviceList.selectedCount ?
                        page.deleteDevices(...deviceList.checkedIndice) :
                        page.deleteDevices(
                            ...utils.range(1, deviceList.count - 1),
                        )

                    Keys.onTabPressed: page.focusListController()
                }
            }
        }

        delegate: DeviceDelegate {
            width: deviceList.width
            view: deviceList
            userId: page.userId
            offline: page.offline
            onVerified: page.loadDevices()
            onBlacklisted: page.loadDevices()
            onRenameRequest: name => page.renameDevice(model.index, name)
            onDeleteRequest: page.deleteDevices(model.index)
        }

        section.property: "type"
        section.delegate: DeviceSection {
            width: deviceList.width
            view: deviceList
        }

        Component.onCompleted: page.loadDevices()

        Layout.fillWidth: true
        Layout.fillHeight: true

        Keys.onEscapePressed: uncheckAll()
        Keys.onSpacePressed: if (currentItem) toggleCheck(currentIndex)
        Keys.onEnterPressed: if (currentItem) currentItem.openMenu(false)
        Keys.onReturnPressed: Keys.onEnterPressed(event)
        Keys.onMenuPressed: Keys.onEnterPressed(event)

        Keys.onUpPressed: page.focusListController(false)
        Keys.onDownPressed: page.focusListController()

        Item {
            id: listController

            Keys.onBacktabPressed: {
                if (parent.currentIndex === 0) {
                    parent.currentIndex = -1

                    parent.headerItem.signOutCheckedButton.enabled ?
                    parent.headerItem.signOutCheckedButton.forceActiveFocus() :
                    parent.headerItem.importButton.forceActiveFocus()

                    return
                }
                parent.decrementCurrentIndex()
                forceActiveFocus()
            }

            Keys.onTabPressed: {
                if (parent.currentIndex === parent.count - 1) {
                    utils.flickToTop(deviceList)
                    parent.currentIndex = -1
                    parent.headerItem.exportButton.forceActiveFocus()
                    return
                }
                parent.incrementCurrentIndex()
                forceActiveFocus()
            }

            Keys.onUpPressed: ev => Keys.onBacktabPressed(ev)
            Keys.onDownPressed: ev => Keys.onTabPressed(ev)
        }

        HShortcut {
            sequences: window.settings.keys.refreshDevices
            onActivated: refreshButton.clicked()
        }

        HShortcut {
            sequences: window.settings.keys.signOutCheckedOrAllDevices
            onActivated: signOutCheckedButton.clicked()
        }

        FlickShortcuts {
            flickable: deviceList
            active:
                ! mainUI.debugConsole.visible && page.enableFlickShortcuts
        }
    }
}
