import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"
import "../../utils.js" as Utils

HPage {
    id: addChatPage


    property string userId

    readonly property var account:
        Utils.getItem(modelSources["Account"] || [], "user_id", userId)


    HTabbedBoxes {
        tabModel: [
            qsTr("Find someone"), qsTr("Join room"), qsTr("Create room"),
        ]

        FindSomeone { Component.onCompleted: forceActiveFocus() }
        JoinRoom {}
        CreateRoom {}
    }
}
