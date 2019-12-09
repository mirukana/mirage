import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../Base"

HPage {
    HTabContainer {
        tabModel: [
            qsTr("Sign in"), qsTr("Register"), qsTr("Reset"),
        ]

        SignIn { Component.onCompleted: forceActiveFocus() }
        Register {}
        Reset {}
    }
}
