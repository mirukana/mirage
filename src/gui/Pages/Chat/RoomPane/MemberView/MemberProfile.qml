// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../../.."
import "../../../../Base"

HListView {
    id: profile


    property string userId
    property string roomId
    property QtObject member  // RoomMember model item
    property HStackView stackView


    function loadDevices() {
         py.callClientCoro(userId, "member_devices", [member.id], devices => {
            profile.model.clear()

            for (const device of devices)
                profile.model.append(device)
        })
    }


    clip: true
    bottomMargin: theme.spacing
    model: ListModel {}
    delegate: MemberDeviceDelegate {
        width: profile.width
        userId: profile.userId
        deviceOwner: member.id
        deviceOwnerDisplayName: member.display_name
        stackView: profile.stackView
    }

    section.property: "type"
    section.delegate: MemberDeviceSection {
        width: profile.width
    }

    header: HColumnLayout {
        x: theme.spacing
        width: profile.width - x * 2
        spacing: theme.spacing * 1.5

        HUserAvatar {
            userId: member.id
            displayName: member.display_name
            mxc: member.avatar_url

            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.preferredHeight: width
            Layout.topMargin: theme.spacing

            HButton {
                x: -theme.spacing * 0.75
                y: x
                z: 999
                circle: true
                icon.name: "close-view"
                iconItem.small: true
                onClicked: profile.stackView.pop()
            }

        }

        HLabel {
            textFormat: HLabel.StyledText
            wrapMode: HLabel.Wrap
            horizontalAlignment: Qt.AlignHCenter
            text:
                utils.coloredNameHtml(member.display_name, member.user_id) +
                (member.display_name.trim() ?
                 `<br><font color="${theme.colors.dimText}">${member.id}</font>` :
                 "")

            Layout.fillWidth: true
            Layout.bottomMargin: theme.spacing
        }

        // TODO
        // HColumnLayout {
        //     spacing: theme.spacing / 2

        //     HLabel {
        //         text: qsTr("Power level:")
        //         wrapMode: HLabel.Wrap
        //         horizontalAlignment: Qt.AlignHCenter

        //         Layout.fillWidth: true
        //     }

        //     HRowLayout {
        //         spacing: theme.spacing

        //         HSpacer {}

        //         Row {
        //             HButton {
        //                 text: qsTr("Default")
        //                 checked: levelBox.value >= 0 && levelBox.value < 50
        //                 onClicked: levelBox.value = 0
        //             }
        //             HButton {
        //                 text: qsTr("Moderator")
        //                 checked: levelBox.value >= 50 && levelBox.value < 100
        //                 onClicked: levelBox.value = 50
        //             }
        //             HButton {
        //                 text: qsTr("Admin")
        //                 checked: levelBox.value === 100
        //                 onClicked: levelBox.value = 100
        //             }
        //         }

        //         HSpinBox {
        //             id: levelBox
        //             from: -999
        //             to: 100
        //             defaultValue: member.power_level
        //         }

        //         HSpacer {}
        //     }
        // }
    }

    Component.onCompleted: loadDevices()

    Keys.onEscapePressed: stackView.pop()
}
