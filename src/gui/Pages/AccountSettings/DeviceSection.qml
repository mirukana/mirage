// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HRowLayout {
    property HListView view

    readonly property int sectionCheckedCount:
        Object.values(deviceList.checked).filter(
            item => item.type === section
        ).length

    readonly property int sectionTotalCount:
        deviceList.sectionItemCounts[section] || 0


    HCheckBox {
        id: checkBox
        padding: theme.spacing
        topPadding: padding * (section === "current" ? 1 : 2)

        text:
            section === "current" ? qsTr("Current session") :
            section === "unset" ? qsTr("Unverified") :
            section === "no_keys" ? qsTr("Unverifiable") :
            section === "verified" ? qsTr("Verified") :
            section === "ignored" ? qsTr("Ignored") :
            qsTr("Blacklisted")

        tristate: true

        checkState:
            ! sectionCheckedCount                     ? Qt.Unchecked :
            sectionTotalCount === sectionCheckedCount ? Qt.Checked :
            Qt.PartiallyChecked

        nextCheckState:
            checkState === Qt.Checked ? Qt.Unchecked : Qt.Checked

        onClicked: {
            const indice = []

            for (let i = 0; i < deviceList.count; i++) {
                if (deviceList.model.get(i).type === section)
                    indice.push(i)
            }

            const checkedItems = Object.values(deviceList.checked)

            checkedItems.some(item => item.type === section) ?
            deviceList.uncheck(...indice) :
            deviceList.check(...indice)
        }

        Layout.fillWidth: true
    }

    HLabel {
        text:
            sectionCheckedCount ?
            qsTr("%1 / %2")
            .arg(sectionCheckedCount).arg(sectionTotalCount) :
            sectionTotalCount

        topPadding: checkBox.topPadding - theme.spacing * 0.75
        rightPadding: theme.spacing * 1.5
        verticalAlignment: Qt.AlignVCenter

        color:
            ["current", "verified"].includes(section) ?
            theme.colors.positiveText :

            ["unset", "ignored", "no_keys"].includes(section) ?
            theme.colors.warningText :

            theme.colors.errorText

        Layout.fillHeight: true
    }
}
