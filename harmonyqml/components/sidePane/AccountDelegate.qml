import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.4
import "../base" as Base

ColumnLayout {
    id: accountDelegate
    spacing: 0
    width: parent.width

    RowLayout {
        id: row
        spacing: 0

        Base.HAvatar { id: avatar; name: displayName; dimension: 36 }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Base.HLabel {
                id: accountLabel
                text: displayName.value || userId
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.fillWidth: true
                leftPadding: 6
                rightPadding: leftPadding
            }

            TextField {
                id: statusEdit
                text: statusMessage || ""
                placeholderText: qsTr("Set status message")
                background: null
                color: "black"
                selectByMouse: true
                font.family: "Roboto"
                font.pixelSize: 12
                Layout.fillWidth: true
                padding: 0
                leftPadding: accountLabel.leftPadding
                rightPadding: leftPadding

                onEditingFinished: {
                    Backend.setStatusMessage(userId, text)
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
        forUserId: userId

        Layout.minimumHeight:
            roomList.visible ?
            roomList.contentHeight :
            0
        Layout.maximumHeight: Layout.minimumHeight

        Layout.minimumWidth:
            parent.width - Layout.leftMargin - Layout.rightMargin
        Layout.maximumWidth: Layout.minimumWidth

        Layout.margins: accountList.spacing
        Layout.leftMargin:
            sidePane.width < 36 + Layout.margins ? 0 : Layout.margins
        Layout.rightMargin: 0
    }
}
