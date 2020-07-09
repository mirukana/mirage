// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../../../Base"
import "../../../../Base/ButtonLayout"
import "../../../../Base/HTile"

HTile {
    id: deviceTile


    property string userId
    property string deviceOwner
    property string deviceOwnerDisplayName
    property HStackView stackView

    signal trustSet(bool trust)


    backgroundColor: "transparent"
    rightPadding: theme.spacing / 2
    compact: false

    contentItem: ContentRow {
        tile: deviceTile
        spacing: 0

        HColumnLayout {
            HRowLayout {
                spacing: theme.spacing

                TitleLabel {
                    text: model.display_name || qsTr("Unnamed")
                }
            }

            SubtitleLabel {
                tile: deviceTile
                font.family: theme.fontFamily.mono
                text: model.id
            }
        }

        HIcon {
            svgName: "device-action-menu"

            Layout.fillHeight: true
        }
    }

    onClicked: {
        const item = stackView.push(
            "DeviceVerification.qml",
            {
                deviceOwner: deviceTile.deviceOwner,
                deviceOwnerDisplayName: deviceTile.deviceOwnerDisplayName,
                deviceId: model.id,
                deviceName: model.display_name,
                ed25519Key: model.ed25519_key,
                stackView: deviceTile.stackView
            },
        )
        item.trustSet.connect(deviceTile.trustSet)
    }
}
