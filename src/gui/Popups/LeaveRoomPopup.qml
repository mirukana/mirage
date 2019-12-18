import QtQuick 2.12

BoxPopup {
    summary.text: qsTr("Leave <i>%1</i>?").arg(roomName)
    summary.textFormat: Text.StyledText
    details.text: qsTr(
        "If this room is private, you will not be able to rejoin it."
    )
    okText: qsTr("Leave")
    box.focusButton: "ok"

    onOk: py.callClientCoro(userId, "room_leave", [roomId], leftCallback)


    property string userId: ""
    property string roomId: ""
    property string roomName: ""
    property var leftCallback: null
}
