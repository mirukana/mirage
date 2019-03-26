import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.4

ColumnLayout {
    id: "accountDelegate"
    spacing: 0
    width: parent.width

    RowLayout {
        id: "row"
        spacing: 0

        Avatar { id: "avatar"; username: display_name; dimmension: 36 }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            PlainLabel {
                id: "accountLabel"
                text: display_name
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.fillWidth: true
                leftPadding: 6
                rightPadding: leftPadding
            }

            TextField {
                id: "statusEdit"
                text: status_message || ""
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
                    Backend.setStatusMessage(user_id, text)
                    pageStack.forceActiveFocus()
                }
            }
        }

        HButton {
            id: "toggleExpand"
            iconName: roomList.visible ? "up" : "down"
            Layout.maximumWidth: 28
            Layout.maximumHeight: Layout.maximumWidth

            onClicked: {
                toggleExpand.ToolTip.hide()
                roomList.visible = ! roomList.visible
            }
        }
    }

    RoomList {
        id: "roomList"
        visible: true
        user: Backend.getUser(user_id)

        Layout.minimumHeight:
            roomList.visible ?
            roomList.contentHeight + roomList.anchors.margins * 2 :
            0
        Layout.maximumHeight: Layout.minimumHeight

        Layout.minimumWidth: parent.width - Layout.leftMargin * 2
        Layout.maximumWidth: Layout.minimumWidth

        Layout.margins: accountList.spacing
        Layout.leftMargin:
            sidePane.width < 36 + Layout.margins ? 0 : Layout.margins
        Layout.rightMargin: Layout.leftMargin
    }
}
