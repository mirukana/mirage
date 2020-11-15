// Copyright Mirage authors & contributors <https://github.com/mirukana/mirage>
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../../../Base"
import "../../../../Base/Buttons"

HFlickableColumnPage {
    id: page

    property string deviceOwner
    property string deviceOwnerDisplayName
    property string deviceId
    property string deviceName
    property string ed25519Key
    property HStackView stackView

    property Item previouslyFocused: null

    signal trustSet(bool trust)

    function close() {
        if (previouslyFocused) previouslyFocused.forceActiveFocus()
        stackView.pop()
    }

    footer: AutoDirectionLayout {
        PositiveButton {
            text: qsTr("They're the same")
            icon.name: "device-verified"
            onClicked: {
                loading = true

                py.callCoro(
                    "verify_device",
                    [deviceOwner, deviceId, ed25519Key.replace(/ /g, "")],
                    () => {
                        loading = false
                        page.trustSet(true)
                        page.close()
                    }
                )
            }
        }

        NegativeButton {
            text: qsTr("They differ")
            icon.name: "device-blacklisted"
            onClicked: {
                loading = true

                py.callCoro(
                    "blacklist_device",
                    [deviceOwner, deviceId, ed25519Key.replace(/ /g, "")],
                    () => {
                        loading = false
                        page.trustSet(false)
                        page.close()
                    }
                )
            }
        }

        CancelButton {
            id: cancelButton
            onClicked: page.close()
        }
    }

    onKeyboardCancel: page.close()

    HRowLayout {
        HButton {
            id: closeButton
            circle: true
            icon.name: "close-view"
            iconItem.small: true
            onClicked: page.close()

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
        textFormat: HTextArea.RichText
        text: (
            formatInfo(qsTr("Session name: "), page.deviceName) +
            formatInfo(qsTr("Session ID: "), page.deviceId) +
            formatInfo(qsTr("Session key: "), "<b>"+page.ed25519Key+"</b>")
        )

        Component.onCompleted: {
            page.previouslyFocused = window.activeFocusItem
            forceActiveFocus()
        }

        Layout.fillWidth: true
    }

    HLabel {
        wrapMode: HLabel.Wrap
        text:
            qsTr(
                "If you already know this user, compare the info you see us" +
                "ing a trusted contact method, such as email or a phone call."
            )

        Layout.fillWidth: true
    }
}
