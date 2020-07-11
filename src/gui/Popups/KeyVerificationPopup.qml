// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"
import "../Base/ButtonLayout"

HFlickableColumnPopup {
    id: popup


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

                py.callCoro(
                    "verify_device",
                    [deviceOwner, deviceId, ed25519Key.replace(/ /g, "")],
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

                py.callCoro(
                    "blacklist_device",
                    [deviceOwner, deviceId, ed25519Key.replace(/ /g, "")],
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

    HTextArea {
        function formatInfo(info, value) {
            return (
                `<p style="line-height: 115%">` +
                info +
                `<span style="font-family: ${theme.fontFamily.mono}">` +
                "&nbsp;" + value +
                `</span></p>`
            )
        }

        readOnly: true
        wrapMode: HSelectableLabel.Wrap
        textFormat: Qt.RichText
        text: (
            formatInfo(qsTr("Session name:"), popup.deviceName) +
            formatInfo(qsTr("Session ID:"), popup.deviceId) +
            formatInfo(qsTr("Session key:"), "<b>"+ popup.ed25519Key+"</b>")
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
