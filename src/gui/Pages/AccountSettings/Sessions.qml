// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../Base/ButtonLayout"
import "../../PythonBridge"
import "../../ShortcutBundles"

HColumnPage {
    id: page
    contentHeight: Math.min(
        window.height,
        Math.max(
            deviceList.contentHeight + deviceList.bottomMargin,
            busyIndicatorLoader.height + theme.spacing * 2,
        )
    )


    property string userId

    property bool enableFlickShortcuts:
        SwipeView ? SwipeView.isCurrentItem : true

    property Future loadFuture: null


    function takeFocus() {} // TODO

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
        const deviceIds = []

        for (const i of indice.sort())
            deviceIds.push(deviceList.model.get(i).id)

        utils.makePopup(
            "Popups/AuthentificationPopup.qml",
            {
                userId: page.userId,
                deviceIds,
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


    footer: ButtonLayout {
        OtherButton {
            text: qsTr("Refresh")
            icon.name: "device-refresh-list"
            onClicked: page.loadDevices()
        }

        OtherButton {
            enabled: deviceList.model.count > 0
            text:
                deviceList.selectedCount === 0 ?
                qsTr("Sign out all") :
                deviceList.selectedCount === 1 ?
                qsTr("Sign out checked") :
                qsTr("Sign out checked (%1)").arg(deviceList.selectedCount)

            icon.name: "device-delete-checked"
            icon.color: theme.colors.negativeBackground
            onClicked:
                deviceList.selectedCount ?
                page.deleteDevices(...deviceList.checkedIndice) :
                page.deleteDevices(...utils.range(1, deviceList.count - 1))
        }
    }


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
            active: page.loadFuture
            opacity: active ? 1 : 0

            Behavior on opacity { HNumberAnimation { factor: 2 } }
        }
    }
}
