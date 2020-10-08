// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../.."
import "../../Base"
import "../../Base/Buttons"
import "../../ShortcutBundles"

HColumnPage {
    id: page

    property string userId

    property bool enableFlickShortcuts:
        SwipeView ? SwipeView.isCurrentItem : true

    property string loadFutureId: ""

    function takeFocus() {} // TODO

    function loadDevices() {
        loadFutureId = py.callClientCoro(userId, "devices_info",[],devices => {
            deviceList.uncheckAll()
            deviceList.model.clear()

            for (const device of devices)
                deviceList.model.append(device)

            loadFutureId                 = ""
            deviceList.sectionItemCounts = getSectionItemCounts()

            if (page.enabled && ! deviceList.currentItem)
                deviceList.currentIndex = 0
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


    enabled: ModelStore.get("accounts").find(userId).presence !== "offline"
    contentHeight: Math.min(
        window.height,
        Math.max(
            deviceList.contentHeight + deviceList.bottomMargin,
            busyIndicatorLoader.height + theme.spacing * 2,
        )
    )

    footer: AutoDirectionLayout {
        GroupButton {
            id: refreshButton
            text: qsTr("Refresh")
            icon.name: "device-refresh-list"
            onClicked: page.loadDevices()
        }

        NegativeButton {
            id: signOutCheckedButton
            enabled: deviceList.model.count > 0
            text:
                deviceList.selectedCount === 0 ?
                qsTr("Sign out all") :
                qsTr("Sign out checked")

            icon.name: "device-delete-checked"
            onClicked:
                deviceList.selectedCount ?
                page.deleteDevices(...deviceList.checkedIndice) :
                page.deleteDevices(...utils.range(1, deviceList.count - 1))
        }
    }

    Keys.forwardTo: [deviceList]

    HListView {
        id: deviceList

        // Don't bind directly to getSectionItemCounts(), laggy with big list
        property var sectionItemCounts: ({})

        bottomMargin: theme.spacing
        clip: true
        model: ListModel {}
        delegate: DeviceDelegate {
            width: deviceList.width
            view: deviceList
            userId: page.userId
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
        Keys.onTabPressed: incrementCurrentIndex()
        Keys.onBacktabPressed: decrementCurrentIndex()
        Keys.onSpacePressed: if (currentItem) toggleCheck(currentIndex)
        Keys.onEnterPressed: if (currentItem) currentItem.openMenu(false)
        Keys.onReturnPressed: Keys.onEnterPressed(event)
        Keys.onMenuPressed: Keys.onEnterPressed(event)

        HShortcut {
            sequences: window.settings.Keys.Sessions.refresh
            onActivated: refreshButton.clicked()
        }

        HShortcut {
            sequences: window.settings.Keys.Sessions.sign_out_checked_or_all
            onActivated: signOutCheckedButton.clicked()
        }

        FlickShortcuts {
            flickable: deviceList
            active:
                ! mainUI.debugConsole.visible && page.enableFlickShortcuts
        }

        HLoader {
            id: busyIndicatorLoader
            anchors.centerIn: parent
            width: 96 * theme.uiScale
            height: width

            source: "../../Base/HBusyIndicator.qml"
            active: page.loadFutureId
            opacity: active ? 1 : 0

            Behavior on opacity { HNumberAnimation { factor: 2 } }
        }
    }
}
