import QtQuick.Layouts 1.3
import "../Base"

HColumnLayout {
    id: accountDelegate
    width: parent.width

    property string roomListUserId: userId

    HRowLayout {
        id: row

        HAvatar { id: avatar; name: displayName; dimension: 36 }

        HColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            HLabel {
                id: accountLabel
                text: displayName.value || userId
                elide: HLabel.ElideRight
                maximumLineCount: 1
                Layout.fillWidth: true
                leftPadding: 6
                rightPadding: leftPadding
            }

            HTextField {
                id: statusEdit
                text: statusMessage || ""
                placeholderText: qsTr("Set status message")
                font.pixelSize: HStyle.fontSize.small
                background: null

                padding: 0
                leftPadding: accountLabel.leftPadding
                rightPadding: leftPadding
                Layout.fillWidth: true

                onEditingFinished: {
                    //Backend.setStatusMessage(userId, text)
                    pageStack.forceActiveFocus()
                }
            }
        }

        HButton {
            id: toggleExpand
            iconName: roomList.visible ? "up" : "down"
            iconDimension: 16
            backgroundColor: "transparent"
            onClicked: roomList.visible = ! roomList.visible

            Layout.preferredHeight: row.height
        }
    }

    RoomList {
        id: roomList
        visible: true
        interactive: false  // no scrolling
        userId: roomListUserId

        Layout.preferredHeight: roomList.visible ? roomList.contentHeight : 0

        Layout.preferredWidth:
            parent.width - Layout.leftMargin - Layout.rightMargin

        Layout.margins: accountList.spacing
        Layout.rightMargin: 0
        Layout.leftMargin:
            sidePane.width <= (sidePane.Layout.minimumWidth + Layout.margins) ?
            0 : Layout.margins
    }
}
