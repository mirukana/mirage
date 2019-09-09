import QtQuick 2.12

BoxPopup {
    summary.text: qsTr("Clear this room's messages?")
    details.text: qsTr(
        "The messages will only be removed on your side. " +
        "They will be available again after you restart the application."
    )
    okText: qsTr("Clear")
    box.focusButton: "ok"

    onOk: py.callClientCoro(userId, "clear_events", [roomId])


    property string userId: ""
    property string roomId: ""
}
