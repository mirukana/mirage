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

        onTrustSet: trust => profile.loadDevices()
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

        HColumnLayout {  // no spacing between these children
            HLabel {
                wrapMode: HLabel.Wrap
                horizontalAlignment: Qt.AlignHCenter
                color: utils.nameColor(member.display_name || member.id)
                text: member.display_name.trim() || member.id

                Layout.fillWidth: true
            }

            HLabel {
                wrapMode: HLabel.Wrap
                horizontalAlignment: Qt.AlignHCenter
                color: theme.colors.dimText
                text: member.id
                visible: member.display_name.trim() !== ""

                Layout.fillWidth: true
            }
        }

        HColumnLayout {
            HLabel {
                wrapMode: HLabel.Wrap
                horizontalAlignment: Qt.AlignHCenter

                text:
                    member.presence === "online" ? qsTr("Online") :
                    member.presence === "unavailable" ? qsTr("Unavailable") :
                    member.presence === "invisible" ? qsTr("Invisible") :
                    qsTr("Offline / Unknown")

                color:
                    member.presence === "online" ?
                    theme.colors.positiveText :

                    member.presence === "unavailable" ?
                    theme.colors.warningText :

                    theme.colors.halfDimText

                Layout.fillWidth: true
            }

            HLabel {
                wrapMode: HLabel.Wrap
                horizontalAlignment: Qt.AlignHCenter
                visible: ! member.currently_active && text !== ""
                color: theme.colors.dimText

                Timer {
                    repeat: true
                    triggeredOnStart: true

                    running:
                        ! member.currently_active &&
                        member.last_active_at > new Date(1)

                    interval:
                        new Date() - member.last_active_at < 60000 ?
                        1000 :
                        60000

                    onTriggered: parent.text = Qt.binding(() =>
                        qsTr("Last seen %1 ago").arg(utils.formatRelativeTime(
                            new Date() - member.last_active_at, false,
                        ))
                    )
                }

                Layout.fillWidth: true
            }
        }

        HLabel {
            wrapMode: HLabel.Wrap
            text: member.status_msg.trim()
            visible: text !== ""

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

    Keys.onEnterPressed: Keys.onReturnPressed(event)
    Keys.onReturnPressed: {
        currentItem.leftClicked()
        currentItem.clicked()
    }
    Keys.onEscapePressed: stackView.pop()


    Connections {
        target: py.eventHandlers

        function onDeviceUpdateSignal(forAccount) {
            if (forAccount === profile.userId) profile.loadDevices()
        }
    }
}
