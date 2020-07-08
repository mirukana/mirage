// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../../../Base"
import "../../../../Base/ButtonLayout"

HFlickableColumnPage {
    id: page


    property string userId
    property string deviceOwner
    property string deviceOwnerDisplayName
    property string deviceId
    property string deviceName
    property string ed25519Key
    property HStackView stackView

    signal trustSet(bool trust)


    footer: ButtonLayout {
        ApplyButton {
            text: qsTr("They're the same")
            icon.name: "device-verified"
            onClicked: {
                loading = true

                py.callClientCoro(
                    userId,
                    "verify_device_id",
                    [deviceOwner, deviceId],
                    () => {
                        loading = false
                        page.trustSet(true)
                        stackView.pop()
                    }
                )
            }
        }

        CancelButton {
            text: qsTr("They differ")
            icon.name: "device-blacklisted"
            onClicked: {
                loading = true

                py.callClientCoro(
                    userId,
                    "blacklist_device_id",
                    [deviceOwner, deviceId],
                    () => {
                        loading = false
                        page.trustSet(false)
                        stackView.pop()
                    }
                )
            }
        }

        CancelButton {
            id: cancelButton
            onClicked: stackView.pop()
            Component.onCompleted: forceActiveFocus()
        }
    }

    onKeyboardCancel: stackView.pop()


    HRowLayout {
        HButton {
            id: closeButton
            circle: true
            icon.name: "close-view"
            iconItem.small: true
            onClicked: page.stackView.pop()

            Layout.rightMargin: theme.spacing
        }

        HLabel {
            text: qsTr("Verification")
            font.bold: true
            elide: HLabel.ElideRight
            horizontalAlignment: Qt.AlignHCenter

            Layout.fillWidth: true
        }

        Item {
            Layout.preferredWidth: closeButton.width
        }
    }

    HLabel {
        wrapMode: HLabel.Wrap
        textFormat: HLabel.StyledText
        text: qsTr(
            "Does %1 sees the same info in their session's account settings?"
        ).arg(utils.coloredNameHtml(deviceOwnerDisplayName, deviceOwner))

        Layout.fillWidth: true
    }

    HTextArea {
        function formatInfo(info, value) {
            return (
                `<p style="line-height: 115%">` +
                info +
                `<br><span style="font-family: ${theme.fontFamily.mono}">` +
                value +
                `</span></p>`
            )
        }

        readOnly: true
        wrapMode: HSelectableLabel.Wrap
        textFormat: Qt.RichText
        text: (
            formatInfo(qsTr("Session name: "), page.deviceName) +
            formatInfo(qsTr("Session ID: "), page.deviceId) +
            formatInfo(qsTr("Session key: "), "<b>"+page.ed25519Key+"</b>")
        )

        Layout.fillWidth: true
    }

    HLabel {
        wrapMode: HLabel.Wrap
        text:
            qsTr(
                "If you already know this user, exchange these info by using" +
                " a trusted contact method, such as email or a phone call."
            )

        Layout.fillWidth: true
    }
}
