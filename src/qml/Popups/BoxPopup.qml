import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../Base"

HPopup {
    id: popup
    onAboutToShow: okClicked = false


    signal ok()
    signal cancel()


    property alias summary: summary
    property alias details: details
    property bool okClicked: false

    property string okText: qsTr("OK")
    property bool okEnabled: true


    box.clickButtonOnEnter: "ok"
    box.buttonModel: [
        { name: "ok", text: okText, iconName: "ok", enabled: okEnabled},
        { name: "cancel", text: qsTr("Cancel"), iconName: "cancel" },
    ]
    box.buttonCallbacks: ({
        ok:     button => { okClicked = true; popup.ok(); popup.close() },
        cancel: button => { okClicked = false; popup.cancel(); popup.close() },
    })


    HLabel {
        id: summary
        wrapMode: Text.Wrap
        font.bold: true
        visible: Boolean(text)

        Layout.fillWidth: true
    }

    HLabel {
        id: details
        wrapMode: Text.Wrap
        visible: Boolean(text)

        Layout.fillWidth: true
    }
}
