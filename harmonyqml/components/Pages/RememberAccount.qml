import QtQuick 2.7
import QtQuick.Layouts 1.3
import "../Base"

Item {
    property string loginWith: "username"
    property var client: null

    HInterfaceBox {
        id: rememberBox
        title: "Sign in"
        anchors.centerIn: parent

        enterButtonTarget: "yes"

        buttonModel: [
            { name: "yes", text: qsTr("Yes") },
            { name: "no", text: qsTr("No") },
        ]

        buttonCallbacks: {
            "yes": function(button) {
                Backend.clients.remember(client)
                pageStack.showPage("Default")
            },
            "no": function(button) { pageStack.showPage("Default") },
        }

        HLabel {
            text: qsTr(
                "Do you want to remember this account?\n\n" +
                "If yes, the " + loginWith + " and an access token will be " +
                "stored to automatically sign in on this device."
            )
            wrapMode: Text.Wrap

            Layout.margins: rememberBox.margins
            Layout.maximumWidth: rememberBox.width - Layout.margins * 2
        }

        HSpacer {}
    }
}
