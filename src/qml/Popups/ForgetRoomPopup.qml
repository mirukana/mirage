import QtQuick 2.12

BoxPopup {
    summary.text: qsTr(
        "You will leave the room and lose its messages. Forget %1?"
    ).arg(roomName)

    details.text: qsTr(
        "If all members forget the room, it will be removed from the servers."
    )

    okText: qsTr("Forget")
    box.focusButton: "ok"

    onOk: py.callClientCoro(userId, "room_forget", [roomId])


    property string userId: ""
    property string roomId: ""
    property string roomName: ""
}
