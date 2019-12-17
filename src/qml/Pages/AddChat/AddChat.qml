import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HPage {
    id: addChatPage


    property string userId

    readonly property var account:
        utils.getItem(modelSources["Account"] || [], "user_id", userId)


    HTabContainer {
        tabModel: [
            qsTr("Direct chat"), qsTr("Join room"), qsTr("Create room"),
        ]

        DirectChat { Component.onCompleted: forceActiveFocus() }
        JoinRoom {}
        CreateRoom {}
    }
}
