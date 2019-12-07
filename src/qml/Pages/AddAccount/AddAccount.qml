import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HPage {
    HTabbedBoxes {
        tabModel: [
            qsTr("Sign in"), qsTr("Register"), qsTr("Recovery"),
        ]

        SignIn { Component.onCompleted: forceActiveFocus() }
        Item {}  // TODO
        Item {}  // TODO
    }
}
