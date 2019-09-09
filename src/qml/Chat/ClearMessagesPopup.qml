import QtQuick 2.12
import "../Base"

HOkCancelPopup {
    text: qsTr(
        "Clear this room's messages?\n" +
        "The messages will only be removed on your side. " +
        "They will be available again after you restart the application."
    )

    onOk: py.callClientCoro(userId, "clear_events", [roomId])


    property string userId: ""
    property string roomId: ""
}
