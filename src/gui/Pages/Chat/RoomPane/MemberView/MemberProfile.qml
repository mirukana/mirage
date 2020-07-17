// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../../.."
import "../../../../Base"
import "../../../../Base/Buttons"
import "../../../../PythonBridge"

HListView {
    id: root

    property string userId
    property string roomId
    property int ownPowerLevel
    property int canSetPowerLevels
    property QtObject member  // RoomMember model item
    property HStackView stackView

    property bool powerLevelFieldFocused: false

    property Future setPowerFuture: null
    property Future getPresenceFuture: null

    function loadDevices() {
         py.callClientCoro(userId, "member_devices", [member.id], devices => {
            root.model.clear()

            for (const device of devices)
                root.model.append(device)
        })
    }


    clip: true
    bottomMargin: theme.spacing
    model: ListModel {}
    delegate: MemberDeviceDelegate {
        width: root.width
        userId: root.userId
        deviceOwner: member.id
        deviceOwnerDisplayName: member.display_name
        stackView: root.stackView

        onTrustSet: trust => root.loadDevices()
    }

    section.property: "type"
    section.delegate: MemberDeviceSection {
        width: root.width
    }

    header: HColumnLayout {
        x: theme.spacing
        width: root.width - x * 2
        spacing: theme.spacing * 1.5

        HUserAvatar {
            userId: member.id
            displayName: member.display_name
            mxc: member.avatar_url

            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.maximumWidth: 256 * theme.uiScale
            Layout.preferredHeight: width
            Layout.topMargin: theme.spacing

            HButton {
                x: -theme.spacing * 0.75
                y: x
                z: 999
                circle: true
                icon.name: "close-view"
                iconItem.small: true
                onClicked: root.stackView.pop()
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
            horizontalAlignment: lineCount > 1 ? Qt.AlignLeft : Qt.AlignHCenter
            color: theme.colors.halfDimText

            Layout.fillWidth: true
        }

        HLabeledItem {
            id: powerLevel
            elementsOpacity: item.field.opacity
            enabled:
                root.canSetPowerLevels &&
                (
                    root.ownPowerLevel > member.power_level ||
                    (root.ownPowerLevel === 100 && member.id === userId)
                )

            label.text: qsTr("Power level:")
            label.horizontalAlignment: Qt.AlignHCenter

            errorLabel.horizontalAlignment: Qt.AlignHCenter
            errorLabel.text:
                ! item.changed ?
                "" :

                item.fieldOverMaximum && root.userId === member.id ?
                qsTr("Can't set your own level higher") :

                item.fieldOverMaximum ?
                qsTr("Can't set level higher than your own") :

                item.uncappedLevel === root.ownPowerLevel ?
                qsTr("You won't be able to demote this user") :

                item.uncappedLevel <
                root.ownPowerLevel && root.userId === member.id ?
                qsTr("You won't be able to regain power") :

                ""

            errorLabel.color:
                item.uncappedLevel === root.ownPowerLevel ||
                (
                    item.uncappedLevel <
                    root.ownPowerLevel && root.userId === member.id
                ) ?
                theme.colors.warningText :
                theme.colors.errorText

            Layout.preferredWidth: parent.width

            PowerLevelControl {
                width: parent.width
                defaultLevel: member.power_level
                maximumLevel: root.ownPowerLevel
                rowSpacing: powerLevel.spacing

                onAccepted: applyButton.clicked()
                onFieldFocusedChanged:
                    root.powerLevelFieldFocused = fieldFocused
                Component.onCompleted: forceActiveFocus()

            }
        }

        AutoDirectionLayout {
            visible: scale > 0
            id: buttonsLayout
            scale: powerLevel.item.changed ? 1 : 0
            rowSpacing: powerLevel.spacing

            Layout.preferredWidth: parent.width
            Layout.preferredHeight: implicitHeight * scale
            Layout.topMargin: -theme.spacing

            Behavior on scale { HNumberAnimation {} }

            HSpacer {}

            ApplyButton {
                id: applyButton
                enabled: ! powerLevel.item.fieldOverMaximum
                loading: setPowerFuture !== null
                onClicked: {
                    setPowerFuture = py.callClientCoro(
                        userId,
                        "room_set_member_power",
                        [roomId, member.id, powerLevel.item.level],
                        () => { setPowerFuture = null }
                    )
                }

                Layout.fillWidth: false
                Layout.alignment: Qt.AlignCenter
            }

            CancelButton {
                onClicked: {
                    setPowerFuture.cancel()
                    setPowerFuture = null
                    powerLevel.item.reset()
                }

                Layout.fillWidth: false
                Layout.alignment: Qt.AlignCenter
            }

            HSpacer {}
        }

        Item {
            // This item is just to have some spacing at the bottom of header
            visible: root.count > 0
            Layout.fillWidth: true
        }
    }

    Component.onCompleted: {
        loadDevices()

        if (member.presence === "offline" &&
            member.last_active_at < new Date(1))
        {
            getPresenceFuture =
                py.callClientCoro(userId, "get_offline_presence", [member.id])
        }
    }

    Component.onDestruction: {
        if (setPowerFuture) setPowerFuture.cancel()
        if (getPresenceFuture) getPresenceFuture.cancel()
    }

    Keys.onEnterPressed: Keys.onReturnPressed(event)
    Keys.onReturnPressed: if (! root.powerLevelFieldFocused && currentItem) {
        currentItem.leftClicked()
        currentItem.clicked()
    }
    Keys.onEscapePressed: stackView.pop()

    Connections {
        target: py.eventHandlers

        function onDeviceUpdateSignal(forAccount) {
            if (forAccount === root.userId) root.loadDevices()
        }
    }
}
