import QtQuick 2.12
import QtQuick.Layouts 1.12

HPopup {
    onAboutToShow: okClicked = false


    property alias label: label
    property bool okClicked: false


    box.enterButtonTarget: "ok"
    box.buttonModel: [
        { name: "ok", text: qsTr("OK"), iconName: "ok" },
        { name: "cancel", text: qsTr("Cancel"), iconName: "cancel" },
    ]
    box.buttonCallbacks: ({
        ok:     button => { okClicked = true; popup.close() },
        cancel: button => { okClicked = false; popup.close() },
    })


    HLabel {
        id: label
        wrapMode: Text.Wrap

        Layout.fillWidth: true
    }
}
