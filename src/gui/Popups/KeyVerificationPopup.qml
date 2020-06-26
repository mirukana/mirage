// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../Base/ButtonLayout"

HFlickableColumnPopup {
    id: popup


    property string userId
    property string deviceOwner
    property string deviceId
    property string deviceName
    property string ed25519Key
    property bool deviceIsCurrent: false
    property var verifiedCallback: null
    property var blacklistedCallback: null


    page.footer: ButtonLayout {
        ApplyButton {
            visible: ! deviceIsCurrent
            text: qsTr("They match")
            icon.name: "device-verified"
            onClicked: {
                loading = true

                py.callClientCoro(
                    userId,
                    "verify_device_id",
                    [deviceOwner, deviceId],
                    () => {
                        if (verifiedCallback) verifiedCallback()
                        popup.close()
                    }
                )
            }
        }

        CancelButton {
            visible: ! popup.deviceIsCurrent
            text: qsTr("They differ")
            icon.name: "device-blacklisted"
            onClicked: {
                loading = true

                py.callClientCoro(
                    userId,
                    "blacklist_device_id",
                    [deviceOwner, deviceId],
                    () => {
                        if (blacklistedCallback) blacklistedCallback()
                        popup.close()
                    }
                )
            }
        }

        CancelButton {
            id: cancelButton
            onClicked: popup.close()

            Binding on text {
                value: qsTr("Exit")
                when: popup.deviceIsCurrent
            }
        }
    }

    SummaryLabel {
        text: qsTr("Do these info match on your other session?")
    }

    HSelectableLabel {
        function formatInfo(info, value) {
            return (
                `<li style="line-height: 110%">` +
                info +
                `<span style="font-family: ${theme.fontFamily.mono}">` +
                value +
                `</span></li><br style="line-height: 25%">`
            )
        }

        wrapMode: Text.Wrap
        textFormat: Qt.RichText
        text: (
            "<ul>" +
            formatInfo(qsTr("Session name: "), popup.deviceName) +
            formatInfo(qsTr("Session ID: "), popup.deviceId) +
            formatInfo(qsTr("Session key: "), "<b>"+popup.ed25519Key+"</b>") +
            "</ul>"
        )

        Layout.fillWidth: true
    }

    DetailsLabel {
        text:
            deviceIsCurrent ?
            qsTr(
                "Compare with the info in the account settings of the " +
                "session that wants to verify this one, and " +
                "indicate to that other session whether they match. " +
                "If they differ, your account's security may be compromised."
            ) :
            qsTr(
                "Compare with the info in your other session's account " +
                "settings. " +
                "If they differ, your account's security may be compromised."
            )
    }

    onOpened: cancelButton.forceActiveFocus()
}
