import QtQuick 2.12

BoxPopup {
    summary.text: qsTr(
        "Leave %1 and discard the history?"
    ).arg(roomName)

    details.text: qsTr(
        "You will not be able to see the messages you received in " +
        "this room anymore.\n\n" +

        "If all members forget the room, it will be removed from the servers."
    )

    okText: qsTr("Forget")
    box.focusButton: "ok"

    onOk: py.callClientCoro(userId, "room_forget", [roomId])


    property string userId: ""
    property string roomId: ""
    property string roomName: ""
}
