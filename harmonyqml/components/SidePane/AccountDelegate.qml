import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.4
import "../base" as Base

Base.HColumnLayout {
    id: accountDelegate
    width: parent.width

    property string roomListUserId: userId

    Base.HRowLayout {
        id: row

        Base.HAvatar { id: avatar; name: displayName; dimension: 36 }

        Base.HColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Base.HLabel {
                id: accountLabel
                text: displayName.value || userId
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.fillWidth: true
                leftPadding: 6
                rightPadding: leftPadding
            }

            Base.HTextField {
                id: statusEdit
                text: statusMessage || ""
                placeholderText: qsTr("Set status message")
                font.pixelSize: Base.HStyle.fontSize.small
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

        Base.HButton {
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
        Layout.leftMargin:
            sidePane.width < 36 + Layout.margins ? 0 : Layout.margins
        Layout.rightMargin: 0
    }
}
