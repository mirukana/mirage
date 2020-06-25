// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../Base/ButtonLayout"
import "../../PythonBridge"

HColumnPage {
    id: page


    property string userId

    property Future loadFuture: null


    function takeFocus() {} // XXX

    function loadDevices() {
        loadFuture = py.callClientCoro(userId, "devices_info", [], devices => {
            deviceList.checked = {}
            deviceList.model.clear()

            for (const device of devices)
                deviceList.model.append(device)

            loadFuture = null
        })
    }

    function renameDevice(index, name) {
        const device = deviceList.model.get(index)

        device.display_name = name

        py.callClientCoro(userId, "rename_device", [device.id, name], ok => {
            if (! ok) deviceList.model.remove(index)  // 404 happened
        })
    }


    footer: ButtonLayout {
        visible: height >= 0
        height: deviceList.selectedCount ? implicitHeight : 0

        Behavior on height { HNumberAnimation {} }

        OtherButton {
            text:
                deviceList.selectedCount === 1 ?
                qsTr("Sign out checked session") :
                qsTr("Sign out %1 sessions").arg(deviceList.selectedCount)

            icon.name: "device-delete-checked"
            icon.color: theme.colors.negativeBackground
        }
    }


    HListView {
        id: deviceList

        readonly property var sectionItemCounts: {
            const counts = {}

            for (let i = 0; i < count; i++) {
                const section = model.get(i).type
                section in counts ? counts[section] += 1 : counts[section] = 1
            }

            return counts
        }

        clip: true
        model: ListModel {}
        delegate: DeviceDelegate {
            width: deviceList.width
            view: deviceList
            onRenameDeviceRequest: name => renameDevice(model.index, name)
        }

        section.property: "type"
        section.delegate: DeviceSection {
            width: deviceList.width
            view: deviceList
        }

        Component.onCompleted: page.loadDevices()

        Layout.fillWidth: true
        Layout.fillHeight: true

        HLoader {
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
