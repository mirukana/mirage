// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../../../Base"

HRowLayout {
    spacing: theme.spacing / 2

    HIcon {
        svgName: "device-" + section
        colorize:
            section === "verified" ? theme.colors.positiveText :
            section === "blacklisted" ? theme.colors.errorText :
            theme.colors.warningText

        Layout.preferredHeight: dimension
        Layout.leftMargin: theme.spacing / 2
    }

    HLabel {
        elide: HLabel.ElideRight
        verticalAlignment: Qt.AlignVCenter

        text:
            section === "unset" ? qsTr("Unverified sessions") :
            section === "verified" ? qsTr("Verified sessions") :
            section === "ignored" ? qsTr("Ignored sessions") :
            qsTr("Blacklisted sessions")

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.topMargin: theme.spacing
        Layout.bottomMargin: theme.spacing
        Layout.rightMargin: theme.spacing / 2
    }
}
