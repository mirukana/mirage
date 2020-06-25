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
        padding: theme.spacing
        topPadding: padding * (section === "current" ? 1 : 2)

        text:
            section === "current" ? qsTr("Current session") :
            section === "verified" ? qsTr("Verified") :
            section === "ignored" ? qsTr("Ignored") :
            section === "blacklisted" ? qsTr("Blacklisted") :
            qsTr("Unverified")

        tristate: true

        checkState:
            sectionTotalCount === sectionCheckedCount ? Qt.Checked :
            ! sectionCheckedCount                     ? Qt.Unchecked :
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

        rightPadding: theme.spacing * 1.5
        color:
            section === "current" || section === "verified" ?
            theme.colors.positiveText :

            section === "unset" || section === "ignored" ?
            theme.colors.warningText :

            theme.colors.errorText
    }
}
