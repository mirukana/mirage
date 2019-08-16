import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

Item {
    property string loginWith: "username"
    property string userId: ""

    HInterfaceBox {
        id: rememberBox
        title: "Sign in"
        anchors.centerIn: parent

        enterButtonTarget: "yes"

        buttonModel: [
            { name: "yes", text: qsTr("Yes") },
            { name: "no", text: qsTr("No") },
        ]

        buttonCallbacks: ({
            yes: button => {
                py.callCoro("saved_accounts.add", [userId])
                pageStack.showPage("EditAccount/EditAccount", {userId})
            },
            no: button => {
                py.callCoro("saved_accounts.delete", [userId])
                pageStack.showPage("EditAccount/EditAccount", {userId})
            },
        })

        HLabel {
            text: qsTr(
                "Do you want to remember this account?\n\n" +
                "If yes, the " + loginWith + " and an access token will be " +
                "stored to automatically sign in on this device."
            )
            wrapMode: Text.Wrap

            Layout.margins: rememberBox.margins
            Layout.fillWidth: true
        }

        HSpacer {}
    }
}
